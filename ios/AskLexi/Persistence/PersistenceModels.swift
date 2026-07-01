import Foundation
import SwiftData

/// Local cache of a conversation so recent history renders instantly and
/// survives relaunch. The server remains the source of truth.
@Model
final class CachedConversation {
    @Attribute(.unique) var id: String
    var title: String
    var jurisdiction: String?
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \CachedMessage.conversation)
    var messages: [CachedMessage]

    init(id: String, title: String, jurisdiction: String?, updatedAt: Date = .now,
         messages: [CachedMessage] = []) {
        self.id = id
        self.title = title
        self.jurisdiction = jurisdiction
        self.updatedAt = updatedAt
        self.messages = messages
    }
}

@Model
final class CachedMessage {
    @Attribute(.unique) var id: String
    /// Stored as the raw value of `MessageRole`.
    var roleRaw: String
    var content: String
    var createdAt: Date
    var conversation: CachedConversation?

    init(id: String, roleRaw: String, content: String, createdAt: Date = .now) {
        self.id = id
        self.roleRaw = roleRaw
        self.content = content
        self.createdAt = createdAt
    }

    var role: MessageRole { MessageRole(rawValue: roleRaw) ?? .assistant }
}

/// A saved security-deposit intake draft so the user can resume the flow.
@Model
final class DepositDraft {
    @Attribute(.unique) var id: UUID
    var stateCode: String
    var moveOutDate: Date
    var depositAmountCents: Int
    var itemizationReceived: Bool
    var generatedLetter: String?
    var updatedAt: Date

    init(id: UUID = UUID(), stateCode: String, moveOutDate: Date,
         depositAmountCents: Int, itemizationReceived: Bool,
         generatedLetter: String? = nil, updatedAt: Date = .now) {
        self.id = id
        self.stateCode = stateCode
        self.moveOutDate = moveOutDate
        self.depositAmountCents = depositAmountCents
        self.itemizationReceived = itemizationReceived
        self.generatedLetter = generatedLetter
        self.updatedAt = updatedAt
    }
}

enum PersistenceSchema {
    /// The model types managed by SwiftData, in one place for the container.
    static let models: [any PersistentModel.Type] = [
        CachedConversation.self,
        CachedMessage.self,
        DepositDraft.self,
    ]
}
