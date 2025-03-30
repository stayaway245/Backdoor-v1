//
// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.
//

import Foundation
import CoreData

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

extension ChatMessage {
    @objc public var wrappedSender: String {
        sender ?? "Unknown Sender"
    }
    
    @objc public var wrappedContent: String {
        content ?? "No Content"
    }
    
    @objc public var wrappedTimestamp: Date {
        timestamp ?? Date()
    }
}