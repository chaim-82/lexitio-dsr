import SwiftUI

/// Semantic design tokens for "Lexi by Lexitio".
///
/// Colors resolve from the asset catalog (`Assets.xcassets`) so light/dark
/// variants and Increase-Contrast are handled by the system. Never hardcode a
/// hex value in a view — reach for one of these tokens.
///
/// The palette (pine green / warm gold / cream) mirrors asklexi.legal. The live
/// CSS was unreachable when this was authored (org egress policy blocked the
/// host), so the exact hex values live in `tools/gen_assets.py` and should be
/// reconciled against the site before launch — but the token names below are
/// the stable contract the UI depends on.
enum Theme {

    // MARK: Colors (semantic)

    /// Pine green. Primary brand color: key actions, headers, active states.
    static let brandPrimary = Color("BrandPrimary")
    /// Warm gold. Accent: highlights, badges, selected chips, the wordmark's "Lexi".
    static let brandAccent = Color("BrandAccent")
    /// Cream (warm dark in dark mode). App background.
    static let surface = Color("BrandSurface")
    /// Elevated card/sheet background.
    static let surfaceElevated = Color("BrandSurfaceElevated")
    /// Primary text.
    static let textPrimary = Color("BrandTextPrimary")
    /// Secondary / supporting text, including the UPL footer.
    static let textSecondary = Color("BrandTextSecondary")
    /// Hairline separators and card strokes.
    static let stroke = Color("BrandStroke")
    /// Destructive / error color (also used for account deletion).
    static let danger = Color("BrandDanger")

    // MARK: Spacing scale (8pt grid)

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: Corner radii

    enum Radius {
        static let card: CGFloat = 16
        static let control: CGFloat = 12
        static let chip: CGFloat = 20
    }
}
