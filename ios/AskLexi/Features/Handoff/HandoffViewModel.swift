import Foundation
import Observation

@MainActor
@Observable
final class HandoffViewModel {
    enum Phase: Equatable {
        case editing
        case submitting
        case submitted
        case failed(String)
    }

    var summary: String
    var budgetText: String = ""
    private(set) var phase: Phase = .editing

    private let category: String

    init(prefillSummary: String, category: String = "landlord_tenant") {
        self.summary = prefillSummary
        self.category = category
    }

    var canSubmit: Bool {
        summary.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 && phase != .submitting
    }

    private var budgetCents: Int? {
        let cleaned = budgetText.filter { $0.isNumber || $0 == "." }
        guard let dollars = Decimal(string: cleaned), dollars > 0 else { return nil }
        return (dollars * 100 as NSDecimalNumber).intValue
    }

    func submit(using marketplace: any MarketplaceServicing, jurisdiction: USState) async {
        guard canSubmit else { return }
        phase = .submitting
        let body = MarketplaceRequestBody(
            category: category,
            jurisdiction: jurisdiction.abbreviation,
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            budgetCents: budgetCents)
        do {
            _ = try await marketplace.submitRequest(body)
            phase = .submitted
        } catch let error as APIError {
            phase = .failed(error.userMessage)
        } catch {
            phase = .failed(Strings.genericErrorBody)
        }
    }
}
