import Foundation

/// Result of a successful sign-in.
struct AuthResult: Sendable {
    let tokens: TokenPair
    let user: UserDTO?
}

/// Combined auth response as (assumed) returned by the backend.
private struct AuthResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int?
    let user: UserDTO?

    var result: AuthResult {
        AuthResult(
            tokens: TokenPair(accessToken: accessToken,
                              refreshToken: refreshToken,
                              expiresIn: expiresIn),
            user: user
        )
    }
}

protocol AuthServicing: Sendable {
    /// Request a magic sign-in link be emailed to `email`.
    func requestMagicLink(email: String) async throws
    /// Exchange a magic-link token (from the deep link) for a session.
    func verifyMagicLink(token: String) async throws -> AuthResult
    /// Sign in with Apple, exchanging the identity token for a session.
    func signInWithApple(identityToken: String,
                         authorizationCode: String?,
                         fullName: String?,
                         email: String?) async throws -> AuthResult
    /// Fetch the current user profile.
    func fetchCurrentUser() async throws -> UserDTO
    /// Record the UPL disclaimer acknowledgment server-side.
    func acknowledgeDisclaimer(version: String) async throws
    /// Permanently delete the account (App Store guideline 5.1.1(v)).
    func deleteAccount() async throws
}

// MARK: - Live

struct LiveAuthService: AuthServicing {
    let api: APIClient
    let session: SessionStore

    func requestMagicLink(email: String) async throws {
        let body = Endpoint.json(MagicLinkRequest(email: email))
        try await api.send(Endpoint(.post, "auth/magic-link", body: body, requiresAuth: false))
    }

    func verifyMagicLink(token: String) async throws -> AuthResult {
        let body = Endpoint.json(MagicLinkVerifyRequest(token: token))
        let response: AuthResponseDTO = try await api.send(
            Endpoint(.post, "auth/magic-link/verify", body: body, requiresAuth: false))
        await persist(response.result)
        return response.result
    }

    func signInWithApple(identityToken: String,
                         authorizationCode: String?,
                         fullName: String?,
                         email: String?) async throws -> AuthResult {
        let body = Endpoint.json(AppleSignInRequest(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            fullName: fullName,
            email: email))
        let response: AuthResponseDTO = try await api.send(
            Endpoint(.post, "auth/apple", body: body, requiresAuth: false))
        await persist(response.result)
        return response.result
    }

    func fetchCurrentUser() async throws -> UserDTO {
        let user: UserDTO = try await api.send(Endpoint(.get, "me"))
        await session.update(user: user)
        return user
    }

    func acknowledgeDisclaimer(version: String) async throws {
        let body = Endpoint.json(DisclaimerAckRequest(acknowledgedAt: .now, version: version))
        try await api.send(Endpoint(.post, "me/disclaimer", body: body))
    }

    func deleteAccount() async throws {
        try await api.send(Endpoint(.delete, "me"))
        await session.clear()
    }

    private func persist(_ result: AuthResult) async {
        await session.update(tokens: result.tokens)
        if let user = result.user { await session.update(user: user) }
    }
}

// MARK: - Stub
//
// Default implementation while the backend is unreachable from CI / the wedge
// backend is being finalized. Every method here corresponds to an endpoint the
// backend must expose — see BACKEND_TODO.md. Flip `AppEnvironment.useStubServices`
// to false once the live endpoints are confirmed.

actor StubAuthService: AuthServicing {
    let session: SessionStore
    private var acknowledged = false

    init(session: SessionStore) { self.session = session }

    func requestMagicLink(email: String) async throws {
        // Pretend an email was sent.
    }

    func verifyMagicLink(token: String) async throws -> AuthResult {
        try await grantStubSession(email: "demo@asklexi.legal", name: "Demo")
    }

    func signInWithApple(identityToken: String,
                         authorizationCode: String?,
                         fullName: String?,
                         email: String?) async throws -> AuthResult {
        try await grantStubSession(email: email ?? "apple.demo@asklexi.legal",
                                   name: fullName ?? "Lexi User")
    }

    func fetchCurrentUser() async throws -> UserDTO {
        await session.user ?? UserDTO(id: "stub-user", email: "demo@asklexi.legal",
                                      name: "Demo", jurisdiction: "NY", tier: "free")
    }

    func acknowledgeDisclaimer(version: String) async throws { acknowledged = true }

    func deleteAccount() async throws { await session.clear() }

    private func grantStubSession(email: String, name: String) async throws -> AuthResult {
        let tokens = TokenPair(accessToken: "stub-access", refreshToken: "stub-refresh", expiresIn: 3600)
        let user = UserDTO(id: "stub-user", email: email, name: name, jurisdiction: "NY", tier: "free")
        await session.update(tokens: tokens)
        await session.update(user: user)
        return AuthResult(tokens: tokens, user: user)
    }
}
