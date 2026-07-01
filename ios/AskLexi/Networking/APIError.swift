import Foundation

/// Typed networking errors. Views should map these to friendly copy via
/// `userMessage`, never surface the raw value.
enum APIError: Error, Equatable {
    /// No network / transport failure.
    case offline
    /// Non-2xx status with an optional server-provided message.
    case http(status: Int, message: String?)
    /// 401 that could not be recovered via silent refresh; user must re-auth.
    case unauthorized
    /// Response body failed to decode into the expected model.
    case decoding(String)
    /// The requested capability isn't implemented by the backend yet.
    /// Used by the stub layer; see BACKEND_TODO.md.
    case notImplemented(String)
    /// Anything else.
    case unknown(String)

    /// Friendly, non-technical message safe to show a user.
    var userMessage: String {
        switch self {
        case .offline:
            return Strings.offlineBody
        case .unauthorized:
            return "Your session expired. Please sign in again."
        case .http(_, let message):
            return message ?? Strings.genericErrorBody
        case .decoding, .unknown, .notImplemented:
            return Strings.genericErrorBody
        }
    }
}
