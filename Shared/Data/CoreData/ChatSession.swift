import CoreData
import Foundation

@objc(ChatSession)
public class ChatSession: NSManagedObject {
    @NSManaged public var sessionID: String?
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

public extension ChatSession {
    @objc var wrappedMessages: [ChatMessage] {
        let set = messages as? Set<ChatMessage> ?? []
        return set.sorted {
            $0.timestamp ?? Date() < $1.timestamp ?? Date()
        }
    }

    @objc var wrappedTitle: String {
        title ?? "Untitled Chat"
    }
}
