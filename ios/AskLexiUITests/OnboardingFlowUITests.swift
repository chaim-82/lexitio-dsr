import XCTest

/// Smoke test: launch → walk the 3-screen onboarding → (stub auto-login) → Home.
///
/// Uses launch env flags honored by `AppState`:
///   UITEST_RESET=1     forces onboarding to show
///   UITEST_AUTOLOGIN=1 grants a stub session after onboarding so Home is reached
final class OnboardingFlowUITests: XCTestCase {

    func testLaunchThroughOnboardingReachesHome() {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_RESET"] = "1"
        app.launchEnvironment["UITEST_AUTOLOGIN"] = "1"
        app.launch()

        // Screen 1: intro → Continue
        let continueButton = app.buttons[Localized.continueTitle]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        // Screen 2: acknowledge the disclaimer, then Continue
        let acknowledge = app.switches.firstMatch
        XCTAssertTrue(acknowledge.waitForExistence(timeout: 5))
        acknowledge.tap()
        app.buttons[Localized.continueTitle].tap()

        // Screen 3: state selection → Get Started
        let getStarted = app.buttons[Localized.getStarted]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()

        // The main tab bar (Home) should appear once the stub session is granted.
        let homeTab = app.tabBars.buttons[Localized.homeTab]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 8))
    }
}

/// Mirrors the relevant `Strings` values (the UI test target can't import the app
/// target's internal symbols).
private enum Localized {
    static let continueTitle = "Continue"
    static let getStarted = "Get Started"
    static let homeTab = "Lexi"
}
