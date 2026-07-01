import Foundation

/// Single networking entry point. An `actor` so request/refresh state stays
/// race-free. Attaches bearer auth, decodes with the shared snake_case decoder,
/// and transparently retries once after a silent token refresh on 401.
actor APIClient {
    private let baseURL: URL
    private let session: SessionStore
    private let urlSession: URLSession

    /// Invoked when a 401 could not be recovered (refresh failed / absent). The
    /// app layer wires this to route the user back to sign-in.
    var onSessionExpired: (@Sendable () async -> Void)?

    /// Guards against concurrent refreshes stampeding the refresh endpoint.
    private var refreshTask: Task<Bool, Never>?

    init(
        baseURL: URL = Config.apiBaseURL,
        session: SessionStore,
        urlSession: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.urlSession = urlSession
    }

    func setSessionExpiredHandler(_ handler: @escaping @Sendable () async -> Void) {
        onSessionExpired = handler
    }

    // MARK: - JSON requests

    /// Send and decode a JSON response. `nonisolated` so the decoded model (which
    /// need not be `Sendable`) is produced in the caller's context, not returned
    /// across the actor boundary — `execute` only ever hands back `Data`.
    nonisolated func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type = T.self) async throws -> T {
        let (data, _) = try await execute(endpoint, allowRetry: true)
        do {
            return try JSONCoding.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    /// Send and ignore the response body (used for 204/empty responses).
    nonisolated func send(_ endpoint: Endpoint) async throws {
        _ = try await execute(endpoint, allowRetry: true)
    }

    // MARK: - Streaming (SSE)

    /// Returns a byte stream for an SSE endpoint plus the response, after
    /// applying the same auth + 401-refresh handling as `send`.
    ///
    /// `nonisolated` so the non-`Sendable` `AsyncBytes` isn't returned across an
    /// actor boundary; it only reads the actor's immutable `Sendable` `let`s
    /// synchronously and `await`s the isolated request/refresh helpers.
    nonisolated func bytes(for endpoint: Endpoint) async throws -> (URLSession.AsyncBytes, HTTPURLResponse) {
        var request = try await makeRequest(endpoint)
        do {
            var (stream, response) = try await urlSession.bytes(for: request)
            var http = try Self.httpResponse(response)
            if http.statusCode == 401, endpoint.requiresAuth {
                if await refreshIfNeeded() {
                    request = try await makeRequest(endpoint)
                    (stream, response) = try await urlSession.bytes(for: request)
                    http = try Self.httpResponse(response)
                } else {
                    await handleUnauthorized()
                    throw APIError.unauthorized
                }
            }
            guard (200..<300).contains(http.statusCode) else {
                throw APIError.http(status: http.statusCode, message: nil)
            }
            return (stream, http)
        } catch let error as APIError {
            throw error
        } catch {
            throw Self.mapTransportError(error)
        }
    }

    // MARK: - Core execution

    private func execute(
        _ endpoint: Endpoint,
        allowRetry: Bool
    ) async throws -> (Data, HTTPURLResponse) {
        let request = try await makeRequest(endpoint)
        do {
            let (data, response) = try await urlSession.data(for: request)
            let http = try Self.httpResponse(response)

            if http.statusCode == 401, endpoint.requiresAuth, allowRetry {
                if await refreshIfNeeded() {
                    return try await execute(endpoint, allowRetry: false)
                } else {
                    await handleUnauthorized()
                    throw APIError.unauthorized
                }
            }

            guard (200..<300).contains(http.statusCode) else {
                throw APIError.http(
                    status: http.statusCode,
                    message: Self.decodeServerMessage(data)
                )
            }
            return (data, http)
        } catch let error as APIError {
            throw error
        } catch {
            throw Self.mapTransportError(error)
        }
    }

    private func makeRequest(_ endpoint: Endpoint) async throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.unknown("Bad URL for path \(endpoint.path)")
        }
        if !endpoint.query.isEmpty { components.queryItems = endpoint.query }
        guard let url = components.url else {
            throw APIError.unknown("Bad URL components for \(endpoint.path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue(endpoint.accept, forHTTPHeaderField: "Accept")
        if let body = endpoint.body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if endpoint.requiresAuth, let token = await session.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    // MARK: - Token refresh

    /// Coalesced silent refresh. Returns whether a fresh access token is now set.
    private func refreshIfNeeded() async -> Bool {
        if let existing = refreshTask { return await existing.value }
        let task = Task<Bool, Never> { [self] in
            await performRefresh()
        }
        refreshTask = task
        let result = await task.value
        refreshTask = nil
        return result
    }

    private func performRefresh() async -> Bool {
        guard let refreshToken = await session.refreshToken else { return false }
        struct RefreshBody: Encodable { let refreshToken: String }
        guard let body = Endpoint.json(RefreshBody(refreshToken: refreshToken)) else {
            return false
        }
        // Deliberately does NOT flow through `execute` (no auth header, no retry).
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("auth/refresh"),
            resolvingAgainstBaseURL: false
        ) else { return false }
        components.queryItems = nil
        guard let url = components.url else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let pair = try? JSONCoding.decoder.decode(TokenPair.self, from: data)
            else { return false }
            await session.update(tokens: pair)
            return true
        } catch {
            return false
        }
    }

    private func handleUnauthorized() async {
        await session.clear()
        await onSessionExpired?()
    }

    // MARK: - Helpers

    private static func httpResponse(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown("Non-HTTP response")
        }
        return http
    }

    private static func decodeServerMessage(_ data: Data) -> String? {
        guard let body = try? JSONCoding.decoder.decode(APIErrorBody.self, from: data),
              let detail = body.detail, !detail.isEmpty else { return nil }
        return detail
    }

    private static func mapTransportError(_ error: Error) -> APIError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut,
                 .cannotConnectToHost, .cannotFindHost, .dataNotAllowed:
                return .offline
            default:
                return .unknown(urlError.localizedDescription)
            }
        }
        return .unknown(String(describing: error))
    }
}
