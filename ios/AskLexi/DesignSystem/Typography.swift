import SwiftUI

/// Type ramp for the app. System SF for body/UI, New York (serif) for display
/// headlines to echo the "legal but warm" brand. All sizes are relative to
/// Dynamic Type via `.custom(_:size:relativeTo:)` / text styles so accessibility
/// text sizing keeps working.
enum Typography {

    /// Large serif display, e.g. onboarding titles and the Home greeting.
    static func display(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
            .leading(.tight)
    }

    /// Serif section/screen titles.
    static func title(_ size: CGFloat = 26) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    /// Card and row headers (sans).
    static let headline = Font.headline
    /// Standard body copy.
    static let body = Font.body
    /// Emphasized body.
    static let bodyEmphasized = Font.body.weight(.semibold)
    /// Supporting/caption text (UPL footer, timestamps).
    static let caption = Font.caption
    /// Small all-caps labels (badges).
    static let overline = Font.caption2.weight(.semibold)
}

extension View {
    /// Applies a serif display font that still scales with Dynamic Type.
    func displayStyle(_ size: CGFloat = 34) -> some View {
        font(Typography.display(size))
    }
}
