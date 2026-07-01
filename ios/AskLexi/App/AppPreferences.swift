import Foundation

/// Lightweight, non-secret app state backed by `UserDefaults`. Secrets live in
/// the Keychain (`SessionStore`); this is for onboarding/jurisdiction flags.
struct AppPreferences {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private enum Key {
        static let onboardingCompleted = "onboarding.completed"
        static let disclaimerAckVersion = "disclaimer.ackVersion"
        static let disclaimerAckDate = "disclaimer.ackDate"
        static let jurisdiction = "jurisdiction.code"
    }

    /// The current UPL disclaimer version. Bump to force re-acknowledgment.
    static let currentDisclaimerVersion = "2026-07-01"

    var onboardingCompleted: Bool {
        get { defaults.bool(forKey: Key.onboardingCompleted) }
        nonmutating set { defaults.set(newValue, forKey: Key.onboardingCompleted) }
    }

    /// Records that the user acknowledged the current disclaimer version, now.
    func recordDisclaimerAcknowledgment() {
        defaults.set(Self.currentDisclaimerVersion, forKey: Key.disclaimerAckVersion)
        defaults.set(Date.now, forKey: Key.disclaimerAckDate)
    }

    var hasAcknowledgedCurrentDisclaimer: Bool {
        defaults.string(forKey: Key.disclaimerAckVersion) == Self.currentDisclaimerVersion
    }

    /// The user's selected jurisdiction, defaulting to NY (the v1 wedge).
    var jurisdiction: USState {
        get {
            guard let code = defaults.string(forKey: Key.jurisdiction),
                  let state = USState.named(code) else { return .newYork }
            return state
        }
        nonmutating set { defaults.set(newValue.abbreviation, forKey: Key.jurisdiction) }
    }
}
