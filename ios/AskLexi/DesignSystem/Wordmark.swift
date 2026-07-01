import SwiftUI

/// The "Lexi by Lexitio" wordmark. "Lexi" is prominent (serif, gold-on-pine
/// friendly); "by Lexitio" is small and secondary.
struct Wordmark: View {
    enum Size { case small, large }
    var size: Size = .large

    private var lexiSize: CGFloat { size == .large ? 40 : 24 }
    private var bySize: CGFloat { size == .large ? 15 : 11 }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text("Lexi")
                .font(.system(size: lexiSize, weight: .bold, design: .serif))
                .foregroundStyle(Theme.brandPrimary)
            Text("by Lexitio")
                .font(.system(size: bySize, weight: .regular, design: .serif))
                .foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lexi by Lexitio")
    }
}

/// The persistent, subtle UPL framing used across the app.
/// "Lexi provides legal information, not legal advice."
struct DisclaimerFooter: View {
    var body: some View {
        Text(Strings.uplFooter)
            .font(Typography.caption)
            .foregroundStyle(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(Strings.uplFooter)
    }
}
