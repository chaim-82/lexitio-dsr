import Foundation

/// Compile-time / launch-time configuration, sourced from the active
/// `.xcconfig` via `Info.plist` so `dev` and `prod` differ without code changes.
///
/// Read `API_BASE_URL` and feature flags here rather than scattering
/// `Bundle.main` lookups through the app.
enum Config {

    /// Base URL for the AskLexi FastAPI backend, e.g. `https://asklexi.legal`.
    ///
    /// Falls back to the production host if the Info.plist value is missing or
    /// malformed so the app never crashes on a misconfigured build. All
    /// networking goes through `APIClient`, which resolves paths against this.
    static let apiBaseURL: URL = {
        let fallback = URL(string: "https://asklexi.legal") ?? URL(fileURLWithPath: "/")
        guard let raw = infoString("API_BASE_URL"),
              !raw.isEmpty,
              let url = URL(string: raw),
              url.scheme != nil
        else { return fallback }
        return url
    }()

    /// In-app purchases. Ship v1 with this OFF (paywall UI visible, purchases
    /// stubbed) per the monetization decision. Flip via the `IAP_ENABLED`
    /// xcconfig flag once StoreKit products are live and reviewed.
    static let iapEnabled: Bool = boolFlag("IAP_ENABLED", default: false)

    /// When true, the app runs entirely against in-memory stub services instead
    /// of the network. Defaults to true because the AskLexi backend endpoints
    /// were unverified at scaffold time (see BACKEND_TODO.md). Flip the
    /// `USE_STUB_SERVICES` xcconfig flag to NO once the live API is confirmed.
    static let useStubServices: Bool = boolFlag("USE_STUB_SERVICES", default: true)

    /// StoreKit 2 product identifiers. Kept here so flipping `iapEnabled` is
    /// the only change needed to go live.
    enum Products {
        static let plusMonthly = "legal.asklexi.plus.monthly"
        static let proMonthly = "legal.asklexi.pro.monthly"
        static let all: [String] = [plusMonthly, proMonthly]
    }

    /// Remote legal pages rendered in-app via `SFSafariViewController`.
    enum LegalURLs {
        static let terms = URL(string: "https://asklexi.legal/terms") ?? apiBaseURL
        static let privacy = URL(string: "https://asklexi.legal/privacy") ?? apiBaseURL
        static let disclaimer = URL(string: "https://asklexi.legal/disclaimer") ?? apiBaseURL
    }

    /// Custom URL scheme used as the magic-link fallback: `asklexi://auth?token=…`.
    static let urlScheme = "asklexi"

    // MARK: - Info.plist helpers

    private static func infoString(_ key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }

    private static func boolFlag(_ key: String, default fallback: Bool) -> Bool {
        guard let raw = infoString(key)?.uppercased() else { return fallback }
        return raw == "YES" || raw == "TRUE" || raw == "1"
    }
}
