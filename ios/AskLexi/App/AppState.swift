import Foundation
import Observation

/// Top-level app coordinator: owns the navigation phase (onboarding / signed-out
/// / signed-in), the current user, and the selected jurisdiction. Injected into
/// the environment so any screen can react to auth changes.
@MainActor
@Observable
final class AppState {
    enum Phase: Equatable {
        case launching
        case onboarding
        case signedOut
        case signedIn
    }

    let environment: AppEnvironment
    private(set) var phase: Phase = .launching
    private(set) var currentUser: UserDTO?
    private(set) var jurisdiction: USState

    private var preferences: AppPreferences { environment.preferences }

    init(environment: AppEnvironment) {
        self.environment = environment
        self.jurisdiction = environment.preferences.jurisdiction
    }

    /// Resolve the initial phase and wire session-expiry handling.
    /// UI-test hooks (no effect in normal runs). `UITEST_RESET` forces a fresh
    /// onboarding; `UITEST_AUTOLOGIN` grants a stub session after onboarding so a
    /// UI test can deterministically reach Home without real credentials.
    private let uiTestReset = ProcessInfo.processInfo.environment["UITEST_RESET"] == "1"
    private var uiTestAutologin: Bool { ProcessInfo.processInfo.environment["UITEST_AUTOLOGIN"] == "1" }

    func bootstrap() async {
        await environment.api.setSessionExpiredHandler { [weak self] in
            await self?.handleSessionExpired()
        }
        await environment.subscriptionManager.start()

        if uiTestReset {
            preferences.onboardingCompleted = false
            await environment.session.clear()
        }

        guard preferences.onboardingCompleted else {
            phase = .onboarding
            return
        }

        if await environment.session.isAuthenticated {
            currentUser = await environment.session.user
            phase = .signedIn
            Task { await self.refreshUserSilently() }
        } else {
            phase = .signedOut
        }
    }

    // MARK: Onboarding

    func completeOnboarding(state: USState) {
        preferences.onboardingCompleted = true
        preferences.recordDisclaimerAcknowledgment()
        setJurisdiction(state)
        // Best-effort server-side acknowledgment.
        Task { try? await environment.auth.acknowledgeDisclaimer(
            version: AppPreferences.currentDisclaimerVersion) }
        phase = .signedOut

        if uiTestAutologin {
            Task {
                if let result = try? await environment.auth.verifyMagicLink(token: "uitest") {
                    didAuthenticate(result)
                }
            }
        }
    }

    // MARK: Auth transitions

    func didAuthenticate(_ result: AuthResult) {
        currentUser = result.user
        phase = .signedIn
        Task { await self.refreshUserSilently() }
    }

    func signOut() async {
        await environment.session.clear()
        wipeLocalData()
        currentUser = nil
        phase = .signedOut
    }

    func deleteAccount() async throws {
        try await environment.auth.deleteAccount()
        wipeLocalData()
        currentUser = nil
        phase = .signedOut
    }

    // MARK: Jurisdiction

    func setJurisdiction(_ state: USState) {
        jurisdiction = state
        preferences.jurisdiction = state
    }

    // MARK: Deep links (magic-link auth)

    /// Handle `asklexi://auth?token=…` and `https://asklexi.legal/auth?token=…`.
    /// Returns true if the URL was an auth link we consumed.
    @discardableResult
    func handleDeepLink(_ url: URL) async -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }
        let isAuthPath = url.host == "auth"                       // custom scheme
            || components.path.hasSuffix("/auth")                 // universal link
            || components.path == "/auth"
        guard isAuthPath,
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value,
              !token.isEmpty
        else { return false }

        if let result = try? await environment.auth.verifyMagicLink(token: token) {
            didAuthenticate(result)
            return true
        }
        return false
    }

    // MARK: Internals

    private func refreshUserSilently() async {
        guard let user = try? await environment.auth.fetchCurrentUser() else { return }
        currentUser = user
        if let code = user.jurisdiction, let state = USState.named(code) {
            setJurisdiction(state)
        }
    }

    private func handleSessionExpired() {
        currentUser = nil
        phase = .signedOut
    }

    private func wipeLocalData() {
        let context = environment.modelContainer.mainContext
        try? context.delete(model: CachedConversation.self)
        try? context.delete(model: CachedMessage.self)
        try? context.delete(model: DepositDraft.self)
        try? context.save()
    }
}
