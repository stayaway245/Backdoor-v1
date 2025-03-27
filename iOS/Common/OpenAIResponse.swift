import Foundation

/// Model for AI API responses (compatible with both OpenAI and OpenRouter)
struct OpenAIResponse: Codable {
    let choices: [Choice]
    let id: String?
    let model: String?
    
    struct Choice: Codable {
        let message: Message
        let index: Int?
        let finish_reason: String?
    }
    
    struct Message: Codable {
        let content: String
        let role: String?
    }
}
