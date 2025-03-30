import CoreData
import Foundation

@objc(ChatMessage)
public class ChatMessage: NSManagedObject {
    @NSManaged public var messageID: String?
    @NSManaged public var sender: String?
    @NSManaged public var content: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var session: ChatSession?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatMessage> {
        return NSFetchRequest<ChatMessage>(entityName: "ChatMessage")
    }
}

public extension ChatMessage {
    @objc var wrappedSender: String {
        sender ?? "Unknown Sender"
    }

    @objc var wrappedContent: String {
        content ?? "No Content"
    }

    @objc var wrappedTimestamp: Date {
        timestamp ?? Date()
    }
}
