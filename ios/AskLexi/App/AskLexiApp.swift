import SwiftUI

@main
struct AskLexiApp: App {
    @State private var appState: AppState
    private let environment: AppEnvironment

    init() {
        let env = AppEnvironment()
        self.environment = env
        _appState = State(initialValue: AppState(environment: env))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(environment)
                .modelContainer(environment.modelContainer)
                .tint(Theme.brandPrimary)
                .task { await appState.bootstrap() }
                .onOpenURL { url in
                    Task { await appState.handleDeepLink(url) }
                }
        }
    }
}

/// Shared, lazily-created environment used by `#Preview`s. Never used in the real
/// app run (the App injects its own).
@MainActor
enum PreviewSupport {
    static let environment = AppEnvironment()
    static var appState: AppState { AppState(environment: environment) }
}
