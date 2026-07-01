import Foundation

// MARK: - Auth

/// Tokens returned by the backend after magic-link verification or Apple sign-in.
struct TokenPair: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    /// Seconds until the access token expires, if the backend reports it.
    let expiresIn: Int?
}

/// The signed-in user. Fields beyond `id`/`email` are optional so the app
/// degrades gracefully if the backend omits them.
struct UserDTO: Codable, Equatable, Sendable {
    let id: String
    let email: String?
    let name: String?
    /// Two-letter state code, if the backend stores the user's jurisdiction.
    let jurisdiction: String?
    /// "free" | "plus" | "pro", if present.
    let tier: String?
}

struct MagicLinkRequest: Encodable { let email: String }
struct MagicLinkVerifyRequest: Encodable { let token: String }

struct AppleSignInRequest: Encodable {
    let identityToken: String
    let authorizationCode: String?
    let fullName: String?
    let email: String?
}

/// Records the UPL disclaimer acknowledgment (onboarding).
struct DisclaimerAckRequest: Encodable {
    let acknowledgedAt: Date
    let version: String
}

// MARK: - Chat

enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
    case system
}

struct ConversationDTO: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let title: String?
    let jurisdiction: String?
    let updatedAt: Date?
    let messages: [MessageDTO]?
}

struct MessageDTO: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    let createdAt: Date?
}

/// Body for sending a chat message. When `conversationId` is nil the backend is
/// expected to create a new conversation and return its id in the stream.
struct SendMessageRequest: Encodable {
    let conversationId: String?
    let content: String
    let jurisdiction: String?
}

/// A single decoded SSE chunk from the chat stream. The backend's exact shape is
/// unconfirmed (see BACKEND_TODO); this matches the common
/// `{"delta": "…", "conversation_id": "…", "done": false}` pattern and the
/// parser also tolerates a bare `[DONE]` sentinel.
struct ChatStreamChunk: Decodable, Sendable {
    let delta: String?
    let conversationId: String?
    let done: Bool?
    /// Optional suggested follow-ups delivered on the terminal chunk.
    let suggestions: [String]?
}

// MARK: - Marketplace (attorney handoff)

struct MarketplaceRequestBody: Encodable {
    let category: String
    let jurisdiction: String
    let summary: String
    let budgetCents: Int?
}

struct MarketplaceRequestResponse: Codable, Equatable, Sendable {
    let id: String
    let status: String?
}

// MARK: - Subscription

struct EntitlementSyncRequest: Encodable {
    let transactionId: String
    let productId: String
}

struct EntitlementDTO: Codable, Equatable, Sendable {
    /// "free" | "plus" | "pro"
    let tier: String
    let active: Bool
    let expiresAt: Date?
}

// MARK: - Generic

/// Common FastAPI error envelope: `{ "detail": "..." }` (string or objects).
struct APIErrorBody: Decodable {
    let detail: String?
}
