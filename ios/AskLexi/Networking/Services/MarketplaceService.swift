import Foundation

protocol MarketplaceServicing: Sendable {
    /// Post a reverse-auction request for flat-fee attorney quotes.
    func submitRequest(_ body: MarketplaceRequestBody) async throws -> MarketplaceRequestResponse
}

struct LiveMarketplaceService: MarketplaceServicing {
    let api: APIClient
    func submitRequest(_ body: MarketplaceRequestBody) async throws -> MarketplaceRequestResponse {
        try await api.send(Endpoint(.post, "marketplace/requests", body: Endpoint.json(body)))
    }
}

struct StubMarketplaceService: MarketplaceServicing {
    func submitRequest(_ body: MarketplaceRequestBody) async throws -> MarketplaceRequestResponse {
        try? await Task.sleep(for: .milliseconds(400))
        return MarketplaceRequestResponse(id: "req-stub-1", status: "open")
    }
}
