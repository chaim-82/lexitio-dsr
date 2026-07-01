import SwiftUI

/// Switches the whole app between launch, onboarding, sign-in, and the main tabs
/// based on `AppState.phase`.
struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            BrandBackground()
            switch appState.phase {
            case .launching:
                LaunchView()
            case .onboarding:
                OnboardingView()
            case .signedOut:
                SignInView()
            case .signedIn:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.phase)
    }
}

/// Brief branded splash shown while `bootstrap()` resolves the initial phase.
struct LaunchView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Wordmark(size: .large)
            ProgressView().tint(Theme.brandPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.appName)
    }
}

/// The signed-in tab bar: Home, Ask Lexi (chat), Settings.
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label(Strings.appName, systemImage: "house.fill") }
            NavigationStack {
                ChatView(conversationID: nil, seedPrompt: nil)
            }
            .tabItem { Label(Strings.askLexi, systemImage: "bubble.left.and.text.bubble.right.fill") }
            SettingsView()
                .tabItem { Label(Strings.settingsTitle, systemImage: "gearshape.fill") }
        }
    }
}
