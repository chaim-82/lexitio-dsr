import Foundation

/// A simplified statutory rule for how long a landlord has to return a security
/// deposit (or provide an itemized statement) after a tenant moves out.
///
/// IMPORTANT: These day counts are a curated, simplified reference for the v1
/// wedge (NY-first) and are *legal information, not legal advice*. Nuances
/// (certified mail, forwarding-address requirements, itemization vs. return)
/// vary. The backend should own the authoritative rules over time
/// (see BACKEND_TODO.md); until then this table drives the deadline math.
struct DepositRule: Equatable, Sendable {
    let stateCode: String
    /// Days after move-out by which the landlord must act.
    let returnDays: Int
    /// Short, human-readable statutory reference shown to the user.
    let citation: String
}

enum DepositRules {
    /// Default when a state isn't in the table.
    static let fallback = DepositRule(stateCode: "US", returnDays: 30,
                                      citation: "your state's security deposit statute")

    static let table: [String: DepositRule] = [
        "NY": .init(stateCode: "NY", returnDays: 14, citation: "NY Gen. Oblig. Law § 7-108"),
        "NJ": .init(stateCode: "NJ", returnDays: 30, citation: "N.J.S.A. 46:8-21.1"),
        "CT": .init(stateCode: "CT", returnDays: 30, citation: "Conn. Gen. Stat. § 47a-21"),
        "MA": .init(stateCode: "MA", returnDays: 30, citation: "Mass. Gen. Laws ch. 186 § 15B"),
        "CA": .init(stateCode: "CA", returnDays: 21, citation: "Cal. Civ. Code § 1950.5"),
        "TX": .init(stateCode: "TX", returnDays: 30, citation: "Tex. Prop. Code § 92.103"),
        "FL": .init(stateCode: "FL", returnDays: 15, citation: "Fla. Stat. § 83.49"),
        "IL": .init(stateCode: "IL", returnDays: 30, citation: "765 ILCS 710"),
        "WA": .init(stateCode: "WA", returnDays: 30, citation: "RCW 59.18.280"),
        "CO": .init(stateCode: "CO", returnDays: 30, citation: "Colo. Rev. Stat. § 38-12-103"),
        "PA": .init(stateCode: "PA", returnDays: 30, citation: "68 P.S. § 250.512"),
        "OH": .init(stateCode: "OH", returnDays: 30, citation: "Ohio Rev. Code § 5321.16"),
        "GA": .init(stateCode: "GA", returnDays: 30, citation: "O.C.G.A. § 44-7-34"),
        "MI": .init(stateCode: "MI", returnDays: 30, citation: "MCL § 554.609"),
        "AZ": .init(stateCode: "AZ", returnDays: 14, citation: "A.R.S. § 33-1321"),
    ]

    static func rule(for code: String) -> DepositRule {
        table[code.uppercased()] ?? DepositRule(
            stateCode: code.uppercased(), returnDays: fallback.returnDays, citation: fallback.citation)
    }
}

/// The computed deadline picture for a given move-out date.
struct DepositDeadline: Equatable, Sendable {
    let returnDays: Int
    let deadlineDate: Date
    let daysElapsed: Int
    let daysRemaining: Int
    let citation: String

    var isOverdue: Bool { daysRemaining < 0 }
}

/// Pure, deterministic deadline math. `asOf` and `calendar` are injectable so
/// this is fully unit-testable without depending on the current date.
enum DepositDeadlineCalculator {
    static func compute(
        stateCode: String,
        moveOutDate: Date,
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> DepositDeadline {
        let rule = DepositRules.rule(for: stateCode)
        let moveOutDay = calendar.startOfDay(for: moveOutDate)
        let today = calendar.startOfDay(for: now)

        let deadline = calendar.date(byAdding: .day, value: rule.returnDays, to: moveOutDay) ?? moveOutDay
        let elapsed = calendar.dateComponents([.day], from: moveOutDay, to: today).day ?? 0
        let remaining = rule.returnDays - elapsed

        return DepositDeadline(
            returnDays: rule.returnDays,
            deadlineDate: deadline,
            daysElapsed: max(0, elapsed),
            daysRemaining: remaining,
            citation: rule.citation)
    }
}
