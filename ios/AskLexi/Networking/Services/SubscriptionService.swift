import Foundation

protocol SubscriptionServicing: Sendable {
    /// Push a verified StoreKit transaction to the backend to sync entitlement.
    func syncEntitlement(transactionID: String, productID: String) async throws -> EntitlementDTO
    /// Fetch the server's view of the user's current entitlement.
    func fetchEntitlement() async throws -> EntitlementDTO
}

struct LiveSubscriptionService: SubscriptionServicing {
    let api: APIClient

    func syncEntitlement(transactionID: String, productID: String) async throws -> EntitlementDTO {
        let body = Endpoint.json(EntitlementSyncRequest(transactionId: transactionID, productId: productID))
        return try await api.send(Endpoint(.post, "billing/entitlement", body: body))
    }

    func fetchEntitlement() async throws -> EntitlementDTO {
        try await api.send(Endpoint(.get, "billing/entitlement"))
    }
}

struct StubSubscriptionService: SubscriptionServicing {
    func syncEntitlement(transactionID: String, productID: String) async throws -> EntitlementDTO {
        EntitlementDTO(tier: "free", active: false, expiresAt: nil)
    }
    func fetchEntitlement() async throws -> EntitlementDTO {
        EntitlementDTO(tier: "free", active: false, expiresAt: nil)
    }
}
