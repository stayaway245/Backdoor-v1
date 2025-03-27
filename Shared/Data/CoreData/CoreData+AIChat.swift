// CoreData+AIChat.swift
import Foundation
import CoreData

// MARK: - Core Data Stack
class AIChatCoreDataManager {
    static let shared = AIChatCoreDataManager()
    
    private init() {}
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AIChatModel")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Save Context
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

// MARK: - Chat Session Management
extension AIChatCoreDataManager {
    // Create new chat session
    func createChatSession(title: String? = nil) -> ChatSession {
        let context = persistentContainer.viewContext
        let chatSession = ChatSession(context: context)
        
        chatSession.sessionID = UUID().uuidString
        chatSession.title = title
        chatSession.creationDate = Date()
        
        saveContext()
        return chatSession
    }
    
    // Fetch all chat sessions
    func fetchChatSessions() -> [ChatSession] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<ChatSession> = ChatSession.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch chat sessions: \(error)")
            return []
        }
    }
    
    // Fetch specific chat session by ID
    func fetchChatSession(sessionID: String) -> ChatSession? {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<ChatSession> = ChatSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "sessionID == %@", sessionID)
        fetchRequest.fetchLimit = 1
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("Failed to fetch chat session: \(error)")
            return nil
        }
    }
    
    // Delete chat session
    func deleteChatSession(_ session: ChatSession) {
        let context = persistentContainer.viewContext
        context.delete(session)
        saveContext()
    }
}

// MARK: - Chat Message Management
extension AIChatCoreDataManager {
    func addMessage(to session: ChatSession, content: String, isUser: Bool) -> ChatMessage {
        let context = persistentContainer.viewContext
        let message = ChatMessage(context: context)
        
        message.messageID = UUID().uuidString
        message.content = content
        message.timestamp = Date()
        message.isUserMessage = isUser
        session.addToMessages(message)
        
        saveContext()
        return message
    }
}

// MARK: - ChatMessage Entity
@objc(ChatMessage)
public class ChatMessage: NSManagedObject {
    @NSManaged public var messageID: String?
    @NSManaged public var content: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var isUserMessage: Bool
    @NSManaged public var session: ChatSession?
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatMessage> {
        return NSFetchRequest<ChatMessage>(entityName: "ChatMessage")
    }
}

// Regarding your existing ChatSession class:
// Your original code is mostly fine, but we should make some small adjustments
// Here's the corrected version:

@objc(ChatSession)
public class ChatSession: NSManagedObject {
    @NSManaged public var sessionID: String?  // Changed from id to sessionID to match Core Data conventions
    @NSManaged public var title: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var messages: NSSet?
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatSession> {
        return NSFetchRequest<ChatSession>(entityName: "ChatSession")
    }
    
    // Relationship management methods
    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: ChatMessage)
    
    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: ChatMessage)
    
    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)
    
    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)
}

extension ChatSession {
    @objc public var wrappedMessages: [ChatMessage] {
        let set = messages as? Set<ChatMessage> ?? []
        return set.sorted {
            $0.timestamp ?? Date() < $1.timestamp ?? Date()
        }
    }
    
    @objc public var wrappedTitle: String {
        title ?? "Untitled Chat"
    }
}