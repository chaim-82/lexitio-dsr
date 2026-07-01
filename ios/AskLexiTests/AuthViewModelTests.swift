import XCTest
@testable import AskLexi

final class AuthViewModelTests: XCTestCase {
    func testValidEmails() {
        XCTAssertTrue(AuthViewModel.isValidEmail("a@b.com"))
        XCTAssertTrue(AuthViewModel.isValidEmail("first.last@sub.domain.io"))
        XCTAssertTrue(AuthViewModel.isValidEmail("  spaced@trimmed.com  "))
    }

    func testInvalidEmails() {
        XCTAssertFalse(AuthViewModel.isValidEmail(""))
        XCTAssertFalse(AuthViewModel.isValidEmail("nope"))
        XCTAssertFalse(AuthViewModel.isValidEmail("@nolocal.com"))
        XCTAssertFalse(AuthViewModel.isValidEmail("no@domain"))
        XCTAssertFalse(AuthViewModel.isValidEmail("trailing@dot."))
    }
}
