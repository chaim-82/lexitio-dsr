import Foundation
import AuthenticationServices
import Observation

/// Drives the sign-in screen: magic-link email entry and Sign in with Apple.
/// Dependency-light — services are passed into the async methods so the view
/// model has no retained references to the DI container.
@MainActor
@Observable
final class AuthViewModel {
    enum Phase: Equatable {
        case idle
        case sending
        case linkSent
        case failed(String)
    }

    var email: String = ""
    private(set) var phase: Phase = .idle

    var isEmailValid: Bool { Self.isValidEmail(email) }

    // MARK: Magic link

    func sendMagicLink(using auth: any AuthServicing) async {
        guard isEmailValid else {
            phase = .failed(Strings.invalidEmail)
            return
        }
        phase = .sending
        do {
            try await auth.requestMagicLink(email: email.trimmingCharacters(in: .whitespaces))
            phase = .linkSent
        } catch let error as APIError {
            phase = .failed(error.userMessage)
        } catch {
            phase = .failed(Strings.genericErrorBody)
        }
    }

    func resetToEntry() { phase = .idle }

    // MARK: Sign in with Apple

    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handleAppleCompletion(
        _ result: Result<ASAuthorization, Error>,
        using auth: any AuthServicing,
        appState: AppState
    ) async {
        switch result {
        case .failure(let error):
            // User-cancelled is not an error worth surfacing.
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            phase = .failed(Strings.genericErrorBody)
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                phase = .failed(Strings.genericErrorBody)
                return
            }
            let code = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
            let name = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }.joined(separator: " ")
            phase = .sending
            do {
                let session = try await auth.signInWithApple(
                    identityToken: identityToken,
                    authorizationCode: code,
                    fullName: name.isEmpty ? nil : name,
                    email: credential.email)
                appState.didAuthenticate(session)
            } catch let error as APIError {
                phase = .failed(error.userMessage)
            } catch {
                phase = .failed(Strings.genericErrorBody)
            }
        }
    }

    // MARK: Validation

    static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        // Pragmatic check: non-empty local part, "@", a dot in the domain.
        guard let at = trimmed.firstIndex(of: "@"), at != trimmed.startIndex else { return false }
        let domain = trimmed[trimmed.index(after: at)...]
        return domain.contains(".") && !domain.hasSuffix(".") && !domain.hasPrefix(".")
    }
}
