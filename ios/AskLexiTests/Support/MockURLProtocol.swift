import Foundation

/// A `URLProtocol` that serves responses from a test-provided handler, so
/// `APIClient` can be exercised without hitting the network.
final class MockURLProtocol: URLProtocol {
    /// (request) -> (status, headers, body) or throws to simulate transport errors.
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> (Int, [String: String], Data))?
    /// Requests seen, in order — useful for asserting headers/paths.
    nonisolated(unsafe) static var requests: [URLRequest] = []

    static func reset() {
        handler = nil
        requests = []
    }

    /// Build a `URLSession` wired to this protocol.
    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        MockURLProtocol.requests.append(request)
        guard let handler = MockURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (status, headers, body) = try handler(request)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
