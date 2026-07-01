import XCTest
@testable import AskLexi

final class APIClientDecodingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    private func makeClient(session: SessionStore = SessionStore()) -> APIClient {
        APIClient(baseURL: URL(string: "https://example.test")!,
                  session: session,
                  urlSession: MockURLProtocol.makeSession())
    }

    func testDecodesSnakeCaseUser() async throws {
        let json = """
        { "id": "u1", "email": "a@b.com", "name": "Ada", "jurisdiction": "NY", "tier": "free" }
        """
        MockURLProtocol.handler = { _ in (200, ["Content-Type": "application/json"], Data(json.utf8)) }

        let client = makeClient()
        let user: UserDTO = try await client.send(Endpoint(.get, "me", requiresAuth: false))
        XCTAssertEqual(user.id, "u1")
        XCTAssertEqual(user.jurisdiction, "NY")
        XCTAssertEqual(user.tier, "free")
    }

    func testDecodesISO8601DatesWithFractionalSeconds() async throws {
        let json = """
        { "id": "m1", "role": "assistant", "content": "hi", "created_at": "2026-07-01T12:30:00.500Z" }
        """
        MockURLProtocol.handler = { _ in (200, [:], Data(json.utf8)) }

        let client = makeClient()
        let message: MessageDTO = try await client.send(Endpoint(.get, "m", requiresAuth: false))
        XCTAssertEqual(message.role, .assistant)
        XCTAssertNotNil(message.createdAt)
    }

    func testHTTPErrorSurfacesServerDetail() async {
        let json = #"{ "detail": "Not allowed" }"#
        MockURLProtocol.handler = { _ in (403, [:], Data(json.utf8)) }

        let client = makeClient()
        do {
            let _: UserDTO = try await client.send(Endpoint(.get, "me", requiresAuth: false))
            XCTFail("Expected error")
        } catch let error as APIError {
            XCTAssertEqual(error, .http(status: 403, message: "Not allowed"))
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testTransportErrorMapsToOffline() async {
        MockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }

        let client = makeClient()
        do {
            let _: UserDTO = try await client.send(Endpoint(.get, "me", requiresAuth: false))
            XCTFail("Expected error")
        } catch let error as APIError {
            XCTAssertEqual(error, .offline)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testAttachesBearerTokenWhenAuthenticated() async throws {
        let session = SessionStore()
        await session.update(tokens: TokenPair(accessToken: "tok-123", refreshToken: "r", expiresIn: nil))
        MockURLProtocol.handler = { _ in (200, [:], Data(#"{"id":"u1"}"#.utf8)) }

        let client = makeClient(session: session)
        let _: UserDTO = try await client.send(Endpoint(.get, "me"))

        let auth = MockURLProtocol.requests.first?.value(forHTTPHeaderField: "Authorization")
        XCTAssertEqual(auth, "Bearer tok-123")
    }

    func testUnauthorizedRefreshesThenRetries() async throws {
        let session = SessionStore()
        await session.update(tokens: TokenPair(accessToken: "old", refreshToken: "refresh", expiresIn: nil))

        // First protected call → 401; refresh → 200 with new tokens; retry → 200.
        // Count prior "/me" hits from the recorded requests rather than a captured
        // mutable local (which would violate strict concurrency in the handler).
        MockURLProtocol.handler = { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("/auth/refresh") {
                let body = #"{"access_token":"new","refresh_token":"refresh2"}"#
                return (200, [:], Data(body.utf8))
            }
            let meHits = MockURLProtocol.requests.filter { $0.url?.path.hasSuffix("/me") == true }.count
            if meHits <= 1 { return (401, [:], Data()) } // first /me (incl. current) → 401
            return (200, [:], Data(#"{"id":"u1"}"#.utf8))  // retry → 200
        }

        let client = makeClient(session: session)
        let user: UserDTO = try await client.send(Endpoint(.get, "me"))
        XCTAssertEqual(user.id, "u1")
        let newToken = await session.accessToken
        XCTAssertEqual(newToken, "new")
    }
}
