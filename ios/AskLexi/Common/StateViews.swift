import SwiftUI

/// Standard loading placeholder. Never leave a blank screen.
struct LoadingStateView: View {
    var message: String = Strings.loading
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView().tint(Theme.brandPrimary)
            Text(message)
                .font(Typography.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// Standard empty state with an icon, title, body, and optional CTA.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(Theme.brandAccent)
            Text(title)
                .font(Typography.headline)
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                SecondaryButton(title: actionTitle, action: action)
                    .frame(maxWidth: 240)
                    .padding(.top, Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// Standard error state. Shows friendly copy, not a raw error string.
struct ErrorStateView: View {
    var title: String = Strings.genericErrorTitle
    var message: String = Strings.genericErrorBody
    var retry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(Theme.danger)
            Text(title).font(Typography.headline).foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if let retry {
                SecondaryButton(title: Strings.retry, action: retry)
                    .frame(maxWidth: 200)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Loadable state wrapper used by view models for list/detail screens.
enum Loadable<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)
}
