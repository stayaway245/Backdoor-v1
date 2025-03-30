//
// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.
//

//
//

import Foundation

/// Custom AI service that replaces the OpenRouter API with a local AI implementation
final class CustomAIService {
    // Singleton instance for app-wide use
    static let shared = CustomAIService()
    
    private init() {
        Debug.shared.log(message: "Initializing custom AI service", type: .info)
    }
    
    enum ServiceError: Error, LocalizedError {
        case processingError(String)
        case contextMissing
        
        var errorDescription: String? {
            switch self {
            case .processingError(let reason): 
                return "Processing error: \(reason)"
            case .contextMissing:
                return "App context is missing or invalid"
            }
        }
    }
    
    // Maintained for compatibility with existing code
    struct AIMessagePayload {
        let role: String
        let content: String
    }
    
    /// Process user input and generate an AI response
    func getAIResponse(messages: [AIMessagePayload], context: AppContext, completion: @escaping (Result<String, ServiceError>) -> Void) {
        // Log the request
        Debug.shared.log(message: "Processing AI request with \(messages.count) messages", type: .info)
        
        // Get the user's last message
        guard let lastUserMessage = messages.last(where: { $0.role == "user" })?.content else {
            completion(.failure(.processingError("No user message found")))
            return
        }
        
        // Use a background thread for processing to keep UI responsive
        DispatchQueue.global(qos: .userInitiated).async {
            // Analyze the message to understand what the user wants
            let messageIntent = self.analyzeUserIntent(message: lastUserMessage)
            
            // Generate response based on intent and context
            let response = self.generateResponse(
                intent: messageIntent,
                userMessage: lastUserMessage,
                conversationHistory: messages,
                appContext: context
            )
            
            // Add a small delay to simulate processing time (prevents jarring instant responses)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                completion(.success(response))
            }
        }
    }
    
    // MARK: - Intent Analysis
    
    private enum MessageIntent {
        case question(topic: String)
        case appNavigation(destination: String)
        case appInstall(appName: String)
        case appSign(appName: String)
        case sourceAdd(url: String)
        case generalHelp
        case greeting
        case unknown
    }
    
    private func analyzeUserIntent(message: String) -> MessageIntent {
        let lowercasedMessage = message.lowercased()
        
        // Check for greetings
        if lowercasedMessage.contains("hello") || lowercasedMessage.contains("hi ") || lowercasedMessage == "hi" || lowercasedMessage.contains("hey") {
            return .greeting
        }
        
        // Check for help requests
        if lowercasedMessage.contains("help") || lowercasedMessage.contains("how do i") || lowercasedMessage.contains("how to") {
            return .generalHelp
        }
        
        // Use regex patterns to identify specific intents
        if let match = lowercasedMessage.range(of: "sign\\s+(the\\s+)?app\\s+(?:called\\s+|named\\s+)?([^?]+)", options: .regularExpression) {
            let appName = String(lowercasedMessage[match]).replacing(regularExpression: "sign\\s+(the\\s+)?app\\s+(?:called\\s+|named\\s+)?", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return .appSign(appName: appName)
        }
        
        if let match = lowercasedMessage.range(of: "(?:go\\s+to|navigate\\s+to|open|show)\\s+(?:the\\s+)?([^?]+?)\\s+(?:tab|screen|page|section)", options: .regularExpression) {
            let destination = String(lowercasedMessage[match]).replacing(regularExpression: "(?:go\\s+to|navigate\\s+to|open|show)\\s+(?:the\\s+)?|\\s+(?:tab|screen|page|section)", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return .appNavigation(destination: destination)
        }
        
        if let match = lowercasedMessage.range(of: "add\\s+(?:a\\s+)?(?:new\\s+)?source\\s+(?:with\\s+url\\s+|at\\s+|from\\s+)?([^?]+)", options: .regularExpression) {
            let url = String(lowercasedMessage[match]).replacing(regularExpression: "add\\s+(?:a\\s+)?(?:new\\s+)?source\\s+(?:with\\s+url\\s+|at\\s+|from\\s+)?", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return .sourceAdd(url: url)
        }
        
        if let match = lowercasedMessage.range(of: "install\\s+(?:the\\s+)?app\\s+(?:called\\s+|named\\s+)?([^?]+)", options: .regularExpression) {
            let appName = String(lowercasedMessage[match]).replacing(regularExpression: "install\\s+(?:the\\s+)?app\\s+(?:called\\s+|named\\s+)?", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return .appInstall(appName: appName)
        }
        
        // If it contains a question mark, assume it's a question
        if lowercasedMessage.contains("?") {
            // Extract topic from question
            let topic = lowercasedMessage.replacing(regularExpression: "\\?|what|how|when|where|why|who|is|are|can|could|would|will|should", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return .question(topic: topic)
        }
        
        // Default case
        return .unknown
    }
    
    // MARK: - Response Generation
    
    private func generateResponse(intent: MessageIntent, userMessage: String, conversationHistory: [AIMessagePayload], appContext: AppContext) -> String {
        // Get context information
        let contextInfo = appContext.currentScreen
        // Get available commands for use in help responses
        let commandsList = AppContextManager.shared.availableCommands()
        
        switch intent {
        case .greeting:
            return "Hello! I'm your Backdoor assistant. I can help you sign apps, manage sources, and navigate through the app. How can I assist you today?"
            
        case .generalHelp:
            let availableCommandsText = commandsList.isEmpty ? 
                "" : 
                "\n\nAvailable commands: " + commandsList.joined(separator: ", ")
            
            return """
            I'm here to help you with Backdoor! Here are some things I can do:

            • Sign apps with your certificates
            • Add new sources for app downloads
            • Help you navigate through different sections
            • Install apps from your sources
            • Provide information about Backdoor's features\(availableCommandsText)

            What would you like help with specifically?
            """
            
        case .question(let topic):
            // Handle different topics the user might ask about
            if topic.contains("certificate") || topic.contains("cert") {
                return "Certificates are used to sign apps so they can be installed on your device. You can manage your certificates in the Settings tab. If you need to add a new certificate, go to Settings > Certificates and tap the + button. Would you like me to help you navigate there? [navigate to:certificates]"
            } else if topic.contains("sign") {
                return "To sign an app, first navigate to the Library tab where your downloaded apps are listed. Select the app you want to sign, then tap the Sign button. Make sure you have a valid certificate set up first. Would you like me to help you navigate to the Library? [navigate to:library]"
            } else if topic.contains("source") || topic.contains("repo") {
                return "Sources are repositories where you can find apps to download. To add a new source, go to the Sources tab and tap the + button. Enter the URL of the source you want to add. Would you like me to help you navigate to the Sources tab? [navigate to:sources]"
            } else {
                // General response when we don't have specific information about the topic
                return "That's a good question about \(topic). Based on the current state of the app, I can see you're on the \(contextInfo) screen. Would you like me to help you navigate somewhere specific or perform an action related to your question?"
            }
            
        case .appNavigation(let destination):
            return "I'll help you navigate to the \(destination) section. [navigate to:\(destination)]"
            
        case .appSign(let appName):
            return "I'll help you sign the app \"\(appName)\". Let's get started with the signing process. [sign:\(appName)]"
            
        case .appInstall(let appName):
            return "I'll help you install \"\(appName)\". First, let me check if it's available in your sources. [install:\(appName)]"
            
        case .sourceAdd(let url):
            return "I'll add the source from \"\(url)\" to your repositories. [add source:\(url)]"
            
        case .unknown:
            // Extract any potential commands from the message using regex
            let commandPattern = "(sign|navigate to|install|add source)\\s+([\\w\\s.:/\\-]+)"
            if let match = userMessage.range(of: commandPattern, options: .regularExpression) {
                let commandText = String(userMessage[match])
                let components = commandText.split(separator: " ", maxSplits: 1).map(String.init)
                
                if components.count == 2 {
                    let command = components[0]
                    let parameter = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    return "I'll help you with that request. [\(command):\(parameter)]"
                }
            }
            
            // Default response for unknown intents
            return """
            I understand you need assistance with Backdoor. Based on your current context (\(contextInfo)), here are some actions I can help with:

            - Sign apps
            - Install apps
            - Add sources
            - Navigate to different sections

            Please let me know specifically what you'd like to do.
            """
        }
    }
}

// Helper extension for string regex replacement
extension String {
    func replacing(regularExpression pattern: String, with replacement: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(self.startIndex..., in: self)
            return regex.stringByReplacingMatches(in: self, range: range, withTemplate: replacement)
        } catch {
            return self
        }
    }
}
