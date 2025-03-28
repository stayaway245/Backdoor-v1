import Foundation

/// Model for AI responses - structure maintained for compatibility
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
    
    /// Creates a response with the given content
    static func createLocal(content: String) -> OpenAIResponse {
        return OpenAIResponse(
            choices: [
                Choice(
                    message: Message(content: content, role: "assistant"),
                    index: 0,
                    finish_reason: "stop"
                )
            ],
            id: UUID().uuidString,
            model: "backdoor-custom-ai"
        )
    }
}
