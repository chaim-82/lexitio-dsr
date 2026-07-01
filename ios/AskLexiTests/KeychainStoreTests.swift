import XCTest
@testable import AskLexi

/// Runs against the real Keychain in the simulator. Uses a unique service per
/// run so tests don't collide with app data or each other.
final class KeychainStoreTests: XCTestCase {
    private var store: KeychainStore!

    override func setUp() {
        super.setUp()
        store = KeychainStore(service: "legal.asklexi.tests.\(UUID().uuidString)")
    }

    override func tearDown() {
        try? store.remove("account")
        super.tearDown()
    }

    func testSetAndGetString() throws {
        try store.setString("secret-token", for: "account")
        XCTAssertEqual(try store.string(for: "account"), "secret-token")
    }

    func testOverwriteUpdatesValue() throws {
        try store.setString("first", for: "account")
        try store.setString("second", for: "account")
        XCTAssertEqual(try store.string(for: "account"), "second")
    }

    func testMissingKeyReturnsNil() throws {
        XCTAssertNil(try store.string(for: "does-not-exist"))
    }

    func testRemoveDeletesValue() throws {
        try store.setString("x", for: "account")
        XCTAssertTrue(try store.remove("account"))
        XCTAssertNil(try store.string(for: "account"))
    }

    func testCodableRoundTrip() throws {
        let tokens = TokenPair(accessToken: "a", refreshToken: "b", expiresIn: 60)
        try store.setCodable(tokens, for: "account")
        let loaded = try store.codable(TokenPair.self, for: "account")
        XCTAssertEqual(loaded, tokens)
    }
}
