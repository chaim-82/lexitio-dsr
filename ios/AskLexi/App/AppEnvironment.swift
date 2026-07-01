import Foundation
import SwiftData
import Observation

/// Dependency container wired once at launch. Chooses stub vs. live services
/// based on `Config.useStubServices`, so the whole app is exercisable offline
/// and flipping to the real backend is a one-line config change.
///
/// Injected into the SwiftUI environment as an observable object and read with
/// `@Environment(AppEnvironment.self)`.
@MainActor
@Observable
final class AppEnvironment {
    let session: SessionStore
    let api: APIClient
    let auth: any AuthServicing
    let chat: any ChatServicing
    let marketplace: any MarketplaceServicing
    let subscriptions: any SubscriptionServicing
    let subscriptionManager: SubscriptionManager
    let modelContainer: ModelContainer
    let preferences: AppPreferences

    init(preferences: AppPreferences = AppPreferences()) {
        let session = SessionStore()
        let api = APIClient(session: session)
        self.session = session
        self.api = api
        self.preferences = preferences

        if Config.useStubServices {
            self.auth = StubAuthService(session: session)
            self.chat = StubChatService()
            self.marketplace = StubMarketplaceService()
            self.subscriptions = StubSubscriptionService()
        } else {
            self.auth = LiveAuthService(api: api, session: session)
            self.chat = LiveChatService(api: api)
            self.marketplace = LiveMarketplaceService(api: api)
            self.subscriptions = LiveSubscriptionService(api: api)
        }

        self.subscriptionManager = SubscriptionManager(subscriptions: subscriptions)
        self.modelContainer = Self.makeContainer()
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema(PersistenceSchema.models)
        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: schema, configurations: [onDisk]) {
            return container
        }
        // Fall back to in-memory so a corrupt store never bricks the app.
        let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(for: schema, configurations: [inMemory]) {
            return container
        }
        fatalError("Unable to initialize SwiftData ModelContainer for AskLexi schema.")
    }
}
