import SwiftUI
import AuthenticationServices

/// Sign-in screen: magic-link email + Sign in with Apple. Apple's guidelines
/// require Sign in with Apple when other social logins exist; we include it
/// regardless for conversion.
struct SignInView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    @State private var vm = AuthViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer(minLength: Theme.Spacing.xxl)
                Wordmark(size: .large)

                if vm.phase == .linkSent {
                    linkSentState
                } else {
                    entryState
                }

                Spacer(minLength: 0)
                DisclaimerFooter()
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: 600)
        }
        .background(BrandBackground())
    }

    // MARK: Entry

    private var entryState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text(Strings.signInSubtitle)
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            TextField(Strings.emailPlaceholder, text: Binding(
                get: { vm.email },
                set: { vm.email = $0 }))
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(Theme.Spacing.md)
                .background(Theme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1))
                .accessibilityLabel(Strings.emailPlaceholder)

            if case .failed(let message) = vm.phase {
                Text(message)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(
                title: Strings.sendMagicLink,
                isLoading: vm.phase == .sending,
                isEnabled: vm.isEmailValid
            ) {
                Task { await vm.sendMagicLink(using: environment.auth) }
            }

            dividerRow

            SignInWithAppleButton(.signIn) { request in
                vm.configureAppleRequest(request)
            } onCompletion: { result in
                Task {
                    await vm.handleAppleCompletion(result, using: environment.auth, appState: appState)
                }
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .accessibilityLabel(Strings.signInWithApple)
        }
    }

    private var dividerRow: some View {
        HStack {
            line
            Text(Strings.orDivider)
                .font(Typography.caption)
                .foregroundStyle(Theme.textSecondary)
            line
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var line: some View {
        Rectangle().fill(Theme.stroke).frame(height: 1)
    }

    // MARK: Link sent

    private var linkSentState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 48))
                .foregroundStyle(Theme.brandAccent)
            Text(Strings.magicLinkSentTitle)
                .font(Typography.title())
                .foregroundStyle(Theme.textPrimary)
            Text(Strings.magicLinkSentBody(vm.email))
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            SecondaryButton(title: Strings.openMailApp, systemImage: "envelope") {
                if let url = URL(string: "message://") { openURL(url) }
            }
            Button(Strings.cancel) { vm.resetToEntry() }
                .font(Typography.caption)
                .foregroundStyle(Theme.brandPrimary)
        }
        .padding(.top, Theme.Spacing.lg)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    SignInView()
        .environment(PreviewSupport.appState)
        .environment(PreviewSupport.environment)
}
