import SwiftUI

// MARK: - Buttons

/// Primary filled action button (pine green). Full-width by default.
struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title).font(Typography.bodyEmphasized)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(Theme.brandPrimary.opacity(isEnabled ? 1 : 0.4))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

/// Secondary/tertiary bordered button.
struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).font(Typography.bodyEmphasized)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.brandPrimary)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                .strokeBorder(Theme.brandPrimary.opacity(0.5), lineWidth: 1.5)
        )
    }
}

// MARK: - Cards & surfaces

/// A rounded, subtly bordered surface. The default container for content.
struct Card<Content: View>: View {
    var padding: CGFloat = Theme.Spacing.md
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(Theme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
    }
}

/// The app's warm background. Apply at the screen root behind content.
struct BrandBackground: View {
    var body: some View {
        Theme.surface.ignoresSafeArea()
    }
}

// MARK: - Chips & badges

/// A tappable suggestion chip (quick topics, follow-up suggestions).
struct SuggestionChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.brandPrimary)
        .background(Theme.brandAccent.opacity(0.14))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Theme.brandAccent.opacity(0.35), lineWidth: 1))
        .accessibilityAddTraits(.isButton)
    }
}

/// Small jurisdiction badge, e.g. "NY" shown on conversations and drafts.
struct JurisdictionBadge: View {
    let jurisdiction: USState

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.and.ellipse").font(.caption2)
            Text(jurisdiction.abbreviation).font(Typography.overline)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 4)
        .foregroundStyle(Theme.brandPrimary)
        .background(Theme.brandPrimary.opacity(0.1))
        .clipShape(Capsule())
        .accessibilityLabel(Strings.a11yJurisdiction(jurisdiction.name))
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(Typography.headline)
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}
