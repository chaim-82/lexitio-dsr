import Foundation
import StoreKit
import Observation

/// StoreKit 2 entitlement manager. Built so flipping `Config.iapEnabled` to true
/// is the only change needed to go live: product IDs, purchase, restore,
/// transaction listening, and backend entitlement sync are all wired.
///
/// With IAP disabled (the v1 decision) `start()` no-ops into the free tier so
/// the paywall UI renders without touching StoreKit.
@MainActor
@Observable
final class SubscriptionManager {
    enum Tier: String, Sendable {
        case free, plus, pro

        var displayName: String {
            switch self {
            case .free: return Strings.subscriptionFreeTitle
            case .plus: return Strings.planPlus
            case .pro: return Strings.planPro
            }
        }
    }

    private(set) var products: [Product] = []
    private(set) var activeTier: Tier = .free
    private(set) var isLoadingProducts = false
    private(set) var purchaseInFlight: String?

    private let subscriptions: any SubscriptionServicing
    private var updatesTask: Task<Void, Never>?

    init(subscriptions: any SubscriptionServicing) {
        self.subscriptions = subscriptions
    }

    deinit { updatesTask?.cancel() }

    /// The paywall can show purchases only when IAP is enabled and products loaded.
    var canPurchase: Bool { Config.iapEnabled && !products.isEmpty }

    func start() async {
        guard Config.iapEnabled else {
            activeTier = .free
            return
        }
        updatesTask = listenForTransactions()
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        guard Config.iapEnabled else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        products = (try? await Product.products(for: Config.Products.all))?
            .sorted { $0.price < $1.price } ?? []
    }

    func purchase(_ product: Product) async throws {
        purchaseInFlight = product.id
        defer { purchaseInFlight = nil }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try Self.checkVerified(verification)
            await syncAndFinish(transaction)
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var resolved: Tier = .free
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.checkVerified(result) else { continue }
            if transaction.revocationDate == nil, let tier = Self.tier(for: transaction.productID) {
                // Prefer the higher tier if multiple are active.
                if tier == .pro || resolved == .free { resolved = tier }
            }
        }
        activeTier = resolved
    }

    // MARK: Private

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                guard let transaction = try? Self.checkVerified(update) else { continue }
                await self.syncAndFinish(transaction)
            }
        }
    }

    private func syncAndFinish(_ transaction: Transaction) async {
        _ = try? await subscriptions.syncEntitlement(
            transactionID: String(transaction.id), productID: transaction.productID)
        await transaction.finish()
        await refreshEntitlements()
    }

    nonisolated private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe): return safe
        case .unverified: throw APIError.unknown("Unverified StoreKit transaction")
        }
    }

    nonisolated private static func tier(for productID: String) -> Tier? {
        switch productID {
        case Config.Products.plusMonthly: return .plus
        case Config.Products.proMonthly: return .pro
        default: return nil
        }
    }
}
