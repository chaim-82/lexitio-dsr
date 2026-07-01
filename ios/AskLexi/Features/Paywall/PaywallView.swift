import SwiftUI
import StoreKit

/// Membership paywall. In v1, IAP is disabled (`Config.iapEnabled == false`), so
/// this shows the plans and a "coming soon" note with a Continue-with-Free path.
/// When IAP is enabled it renders live StoreKit products with working purchase
/// buttons — no other change required.
struct PaywallView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss

    private var manager: SubscriptionManager { environment.subscriptionManager }

    private let plusFeatures = [
        "Unlimited questions to Lexi",
        "Saved conversation history",
        "Priority responses",
    ]
    private let proFeatures = [
        "Everything in Lexi+",
        "Guided document drafting",
        "Attorney handoff perks",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    header
                    planCard(title: Strings.planPlus,
                             productID: Config.Products.plusMonthly,
                             features: plusFeatures)
                    planCard(title: Strings.planPro,
                             productID: Config.Products.proMonthly,
                             features: proFeatures)

                    if !Config.iapEnabled {
                        Text(Strings.paywallComingSoon)
                            .font(Typography.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    Button(Strings.paywallContinueFree) { dismiss() }
                        .font(Typography.bodyEmphasized)
                        .foregroundStyle(Theme.brandPrimary)

                    if Config.iapEnabled {
                        Button(Strings.paywallRestore) {
                            Task { await manager.restore() }
                        }
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .background(BrandBackground())
            .navigationTitle(Strings.paywallTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.close) { dismiss() }
                }
            }
            .task { await manager.loadProducts() }
        }
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Wordmark(size: .small)
            Text(Strings.paywallSubtitle)
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func planCard(title: String, productID: String, features: [String]) -> some View {
        let product = manager.products.first { $0.id == productID }
        return Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Text(title).font(Typography.headline).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text(product?.displayPrice ?? "—")
                        .font(Typography.bodyEmphasized)
                        .foregroundStyle(Theme.brandPrimary)
                }
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    ForEach(features, id: \.self) { feature in
                        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.brandAccent)
                            Text(feature).font(Typography.body).foregroundStyle(Theme.textPrimary)
                        }
                    }
                }
                PrimaryButton(
                    title: purchaseTitle(product),
                    isLoading: manager.purchaseInFlight == productID,
                    isEnabled: manager.canPurchase && product != nil
                ) {
                    guard let product else { return }
                    Task { try? await manager.purchase(product) }
                }
            }
        }
    }

    private func purchaseTitle(_ product: Product?) -> String {
        guard Config.iapEnabled, let product else { return Strings.paywallComingSoon }
        return "Subscribe · \(product.displayPrice)"
    }
}
