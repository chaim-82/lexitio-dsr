import Foundation

/// Owns the authenticated session (tokens + cached user) and persists it to the
/// Keychain. Actor-isolated so `APIClient` and the auth layer can share it
/// safely. Deliberately storage-only — the network refresh lives in `APIClient`.
actor SessionStore {
    private enum Account {
        static let tokens = "session.tokens"
        static let user = "session.user"
    }

    private let keychain: KeychainStore
    private(set) var tokens: TokenPair?
    private(set) var user: UserDTO?

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
        self.tokens = try? keychain.codable(TokenPair.self, for: Account.tokens)
        self.user = try? keychain.codable(UserDTO.self, for: Account.user)
    }

    var isAuthenticated: Bool { tokens != nil }
    var accessToken: String? { tokens?.accessToken }
    var refreshToken: String? { tokens?.refreshToken }

    func update(tokens: TokenPair) {
        self.tokens = tokens
        try? keychain.setCodable(tokens, for: Account.tokens)
    }

    func update(user: UserDTO) {
        self.user = user
        try? keychain.setCodable(user, for: Account.user)
    }

    /// Wipe everything — used by logout and by unrecoverable 401s.
    func clear() {
        tokens = nil
        user = nil
        try? keychain.remove(Account.tokens)
        try? keychain.remove(Account.user)
    }
}
