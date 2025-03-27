import Foundation

/// Service for interacting with OpenRouter API (using OpenAIService name for compatibility)
final class OpenAIService {
    // Hardcoded OpenRouter API key as requested
    private let hardcodedAPIKey = "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"
    
    // Singleton instance for app-wide use
    static let shared = OpenAIService()
    
    private var apiKey: String
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    private let session: URLSession
    
    private init() {
        self.apiKey = hardcodedAPIKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    /// This method is maintained for backward compatibility but uses the hardcoded key regardless
    func updateAPIKey(_ newKey: String) {
        // For backward compatibility, method exists but always uses hardcoded key
        self.apiKey = hardcodedAPIKey
        Debug.shared.log(message: "Using hardcoded OpenRouter API key", type: .debug)
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
                return "API key error. Please contact support."
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
    
    // Maintained for compatibility with existing code
    struct AIMessagePayload {
        let role: String
        let content: String
    }
    
    func getAIResponse(messages: [AIMessagePayload], context: AppContext, completion: @escaping (Result<String, ServiceError>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add HTTP-Referer for OpenRouter tracking
        request.addValue("https://github.com/BackdoorBDG/Feather", forHTTPHeaderField: "HTTP-Referer")
        
        // Enhanced system message with better context and capabilities
        let systemMessage: [String: String] = [
            "role": "system",
            "content": """
            You are an AI assistant fully integrated into the Backdoor app with complete access to all app functionality.
            
            Current app context: \(context.toString())
            
            Available commands: \(AppContextManager.shared.availableCommands().joined(separator: ", "))
            
            You have full awareness of the app's features, data, and capabilities. You can perform any action that a user could manually execute in the app based on their instructions, such as:
            - Signing apps ([sign:app_name])
            - Adding sources ([add source:url])
            - Opening apps ([open:app_name])
            - Navigating to app sections ([navigate to:screen_name])
            - And all other app functions
            
            When you need to perform an action, include commands in your response using the format [command:parameter].
            
            Be concise but friendly in your responses, focusing on helping the user accomplish their tasks within the app.
            """
        ]
        
        var apiMessages = [systemMessage]
        apiMessages.append(contentsOf: messages.map { ["role": $0.role, "content": $0.content] })
        
        // OpenRouter-specific parameters for Gemini
        let body: [String: Any] = [
            "model": "google/gemini-2.5-pro-exp-03-25:free", // Updated to use Gemini model
            "messages": apiMessages,
            "temperature": 0.7,
            "max_tokens": 1000, // Increased token limit for more comprehensive responses
            "route": "fallback" // Use fallback routing for reliability
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            Debug.shared.log(message: "Failed to serialize request body: \(error)", type: .error)
            completion(.failure(.decodingError(error)))
            return
        }
        
        Debug.shared.log(message: "Making API request to Gemini via OpenRouter", type: .info)
        
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
                    Debug.shared.log(message: "Unauthorized: Invalid OpenRouter API key", type: .error)
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
                    Debug.shared.log(message: "Gemini response received successfully", type: .success)
                    completion(.success(content))
                } else {
                    Debug.shared.log(message: "No content in Gemini response", type: .warning)
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