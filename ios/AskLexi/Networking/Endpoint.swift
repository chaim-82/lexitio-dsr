import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Describes a single backend call. Bodies are provided pre-encoded as `Data`
/// (see `Endpoint.json(_:)`) so `Endpoint` stays non-generic and easy to pass
/// around.
struct Endpoint {
    var method: HTTPMethod
    var path: String
    var query: [URLQueryItem]
    var body: Data?
    var requiresAuth: Bool
    /// Accept header; SSE endpoints use `text/event-stream`.
    var accept: String

    init(
        _ method: HTTPMethod,
        _ path: String,
        query: [URLQueryItem] = [],
        body: Data? = nil,
        requiresAuth: Bool = true,
        accept: String = "application/json"
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.body = body
        self.requiresAuth = requiresAuth
        self.accept = accept
    }

    /// JSON-encode an `Encodable` body using the shared snake_case encoder.
    static func json<T: Encodable>(_ value: T) -> Data? {
        try? JSONCoding.encoder.encode(value)
    }
}

/// Shared JSON coders configured for a FastAPI backend (snake_case on the wire,
/// ISO-8601 dates with or without fractional seconds).
enum JSONCoding {
    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = iso8601WithFractional.date(from: string)
                ?? iso8601Plain.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unrecognized date: \(string)")
        }
        return d
    }()

    private static let iso8601WithFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601Plain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
