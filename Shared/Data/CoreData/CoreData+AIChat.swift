// CoreData+AIChat.swift
// This file has been deprecated in favor of using the main CoreDataManager
// The entity declarations have been moved to their respective files
// (ChatMessage.swift and ChatSession.swift)
// Keeping this file for backward compatibility

import Foundation
import CoreData

// MARK: - Deprecated Core Data Stack
// Use CoreDataManager.shared instead
@available(*, deprecated, message: "Use CoreDataManager.shared instead")
class AIChatCoreDataManager {
    static let shared = CoreDataManager.shared
    
    private init() {}
    
    // MARK: - Save Context (Deprecated)
    @available(*, deprecated, message: "Use CoreDataManager.shared.saveContext() instead")
    func saveContext() {
        do {
            try CoreDataManager.shared.saveContext()
        } catch {
            Debug.shared.log(message: "AIChatCoreDataManager.saveContext: \(error)", type: .error)
        }
    }
}

// MARK: - Chat functionality moved to CoreDataManager
extension CoreDataManager {
    // Create new chat session
    func createAIChatSession(title: String? = nil) throws -> ChatSession {
        let chatSession = ChatSession(context: context)
        
        chatSession.sessionID = UUID().uuidString
        chatSession.title = title
        chatSession.creationDate = Date()
        
        try saveContext()
        return chatSession
    }
    
    // Fetch all chat sessions
    func fetchChatSessions() -> [ChatSession] {
        let fetchRequest: NSFetchRequest<ChatSession> = ChatSession.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            Debug.shared.log(message: "Failed to fetch chat sessions: \(error)", type: .error)
            return []
        }
    }
    
    // Fetch specific chat session by ID
    func fetchChatSession(sessionID: String) -> ChatSession? {
        let fetchRequest: NSFetchRequest<ChatSession> = ChatSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "sessionID == %@", sessionID)
        fetchRequest.fetchLimit = 1
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            Debug.shared.log(message: "Failed to fetch chat session: \(error)", type: .error)
            return nil
        }
    }
    
    // Delete chat session
    func deleteChatSession(_ session: ChatSession) throws {
        context.delete(session)
        try saveContext()
    }
    
    // Add AI message
    func addAIMessage(to session: ChatSession, content: String, isUser: Bool) throws -> ChatMessage {
        let message = ChatMessage(context: context)
        
        message.messageID = UUID().uuidString
        message.content = content
        message.timestamp = Date()
        message.sender = isUser ? "user" : "ai"
        session.addToMessages(message)
        
        try saveContext()
        return message
    }
}