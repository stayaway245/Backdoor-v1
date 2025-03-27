import Foundation

/// Service for interacting with OpenAI API
final class OpenAIService {
    // Use a property to access the API key from a secure location
    static let shared: OpenAIService = {
        // In production, this should be retrieved from a secure keychain or environment variable
        // For now, we'll initialize with a placeholder but expect it to be set externally
        let service = OpenAIService(apiKey: "")
        // Attempt to load API key from secure storage
        if let storedKey = UserDefaults.standard.string(forKey: "openai_api_key") {
            service.updateAPIKey(storedKey)
        }
        return service
    }()
    
    private var apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let session: URLSession
    private var isAPIKeyValid: Bool = false
    
    init(apiKey: String) {
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
        self.isAPIKeyValid = !apiKey.isEmpty && !apiKey.contains("[...]")
    }
    
    /// Updates the API key
    func updateAPIKey(_ newKey: String) {
        self.apiKey = newKey
        self.isAPIKeyValid = !newKey.isEmpty && !newKey.contains("[...]")
        // Save to UserDefaults (in a real app, use Keychain instead)
        UserDefaults.standard.set(newKey, forKey: "openai_api_key")
    }
    
    enum ServiceError: Error, LocalizedError {
        case invalidURL
        case invalidAPIKey
        case networkError(Error)
        case decodingError(Error)
        case noData
        case rateLimitExceeded
        case serverError(Int)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: 
                return "Invalid API URL"
            case .invalidAPIKey: 
                return "Invalid or missing API key. Please check your settings."
            case .networkError(let error): 
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error): 
                return "Failed to process AI response: \(error.localizedDescription)"
            case .noData: 
                return "No response received from AI service"
            case .rateLimitExceeded:
                return "AI service rate limit exceeded. Please try again later."
            case .serverError(let code):
                return "AI service error (code: \(code)). Please try again later."
            }
        }
    }
    
    // Renamed from ChatMessage to AIMessagePayload to avoid conflicts with CoreData ChatMessage entity
    struct AIMessagePayload {
        let role: String
        let content: String
    }
    
    func getAIResponse(messages: [AIMessagePayload], context: AppContext, completion: @escaping (Result<String, ServiceError>) -> Void) {
        // First, check if the API key is valid
        if !isAPIKeyValid {
            Debug.shared.log(message: "Invalid API key detected for OpenAI", type: .error)
            completion(.failure(.invalidAPIKey))
            return
        }
        
        guard let url = URL(string: baseURL) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Enhanced system message with better context and capabilities
        let systemMessage: [String: String] = [
            "role": "system",
            "content": """
            You are a helpful AI assistant integrated into the Backdoor app that helps users with signing and managing their applications. 
            
            Current app context: \(context.toString())
            
            Available commands: \(AppContextManager.shared.availableCommands().joined(separator: ", "))
            
            When you need to perform an action, include commands in your response using the format [command:parameter].
            
            Be concise but friendly in your responses, focusing on helping the user accomplish their tasks.
            """
        ]
        
        var apiMessages = [systemMessage]
        apiMessages.append(contentsOf: messages.map { ["role": $0.role, "content": $0.content] })
        
        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": apiMessages,
            "temperature": 0.7,
            "max_tokens": 800  // Increased token limit for more comprehensive responses
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            Debug.shared.log(message: "Failed to serialize request body: \(error)", type: .error)
            completion(.failure(.decodingError(error)))
            return
        }
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard self != nil else { return }  // Prevent execution if service has been deallocated
            
            if let error = error {
                Debug.shared.log(message: "Network error: \(error.localizedDescription)", type: .error)
                completion(.failure(.networkError(error)))
                return
            }
            
            // Check HTTP response status
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                
                switch statusCode {
                case 401:
                    Debug.shared.log(message: "Unauthorized: Invalid API key", type: .error)
                    completion(.failure(.invalidAPIKey))
                    return
                case 429:
                    Debug.shared.log(message: "Rate limit exceeded", type: .warning)
                    completion(.failure(.rateLimitExceeded))
                    return
                case 400..<500 where statusCode != 429:
                    Debug.shared.log(message: "Client error: \(statusCode)", type: .error)
                    completion(.failure(.serverError(statusCode)))
                    return
                case 500..<600:
                    Debug.shared.log(message: "Server error: \(statusCode)", type: .error)
                    completion(.failure(.serverError(statusCode)))
                    return
                default:
                    break
                }
            }
            
            guard let data = data else {
                Debug.shared.log(message: "No data received", type: .error)
                completion(.failure(.noData))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let content = result.choices.first?.message.content {
                    Debug.shared.log(message: "AI response received successfully", type: .success)
                    completion(.success(content))
                } else {
                    Debug.shared.log(message: "No content in AI response", type: .warning)
                    completion(.failure(.noData))
                }
            } catch {
                Debug.shared.log(message: "Failed to decode response: \(error)", type: .error)
                
                // Log the raw response for debugging
                if let rawResponse = String(data: data, encoding: .utf8) {
                    Debug.shared.log(message: "Raw response: \(rawResponse)", type: .debug)
                }
                
                completion(.failure(.decodingError(error)))
            }
        }
        task.resume()
    }
}