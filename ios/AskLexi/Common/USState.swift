import Foundation

/// A US jurisdiction the user can select. Drives which rules Lexi applies.
///
/// Modeled as a value type with the full 50 states + DC. NY is the v1 wedge
/// (security deposit flow), so `.newYork` is called out for convenience.
struct USState: Identifiable, Hashable, Codable, Sendable {
    let abbreviation: String
    let name: String

    var id: String { abbreviation }

    static let newYork = USState(abbreviation: "NY", name: "New York")

    /// Look up by two-letter code (case-insensitive).
    static func named(_ abbreviation: String) -> USState? {
        all.first { $0.abbreviation.caseInsensitiveCompare(abbreviation) == .orderedSame }
    }

    static let all: [USState] = [
        .init(abbreviation: "AL", name: "Alabama"),
        .init(abbreviation: "AK", name: "Alaska"),
        .init(abbreviation: "AZ", name: "Arizona"),
        .init(abbreviation: "AR", name: "Arkansas"),
        .init(abbreviation: "CA", name: "California"),
        .init(abbreviation: "CO", name: "Colorado"),
        .init(abbreviation: "CT", name: "Connecticut"),
        .init(abbreviation: "DE", name: "Delaware"),
        .init(abbreviation: "DC", name: "District of Columbia"),
        .init(abbreviation: "FL", name: "Florida"),
        .init(abbreviation: "GA", name: "Georgia"),
        .init(abbreviation: "HI", name: "Hawaii"),
        .init(abbreviation: "ID", name: "Idaho"),
        .init(abbreviation: "IL", name: "Illinois"),
        .init(abbreviation: "IN", name: "Indiana"),
        .init(abbreviation: "IA", name: "Iowa"),
        .init(abbreviation: "KS", name: "Kansas"),
        .init(abbreviation: "KY", name: "Kentucky"),
        .init(abbreviation: "LA", name: "Louisiana"),
        .init(abbreviation: "ME", name: "Maine"),
        .init(abbreviation: "MD", name: "Maryland"),
        .init(abbreviation: "MA", name: "Massachusetts"),
        .init(abbreviation: "MI", name: "Michigan"),
        .init(abbreviation: "MN", name: "Minnesota"),
        .init(abbreviation: "MS", name: "Mississippi"),
        .init(abbreviation: "MO", name: "Missouri"),
        .init(abbreviation: "MT", name: "Montana"),
        .init(abbreviation: "NE", name: "Nebraska"),
        .init(abbreviation: "NV", name: "Nevada"),
        .init(abbreviation: "NH", name: "New Hampshire"),
        .init(abbreviation: "NJ", name: "New Jersey"),
        .init(abbreviation: "NM", name: "New Mexico"),
        .newYork,
        .init(abbreviation: "NC", name: "North Carolina"),
        .init(abbreviation: "ND", name: "North Dakota"),
        .init(abbreviation: "OH", name: "Ohio"),
        .init(abbreviation: "OK", name: "Oklahoma"),
        .init(abbreviation: "OR", name: "Oregon"),
        .init(abbreviation: "PA", name: "Pennsylvania"),
        .init(abbreviation: "RI", name: "Rhode Island"),
        .init(abbreviation: "SC", name: "South Carolina"),
        .init(abbreviation: "SD", name: "South Dakota"),
        .init(abbreviation: "TN", name: "Tennessee"),
        .init(abbreviation: "TX", name: "Texas"),
        .init(abbreviation: "UT", name: "Utah"),
        .init(abbreviation: "VT", name: "Vermont"),
        .init(abbreviation: "VA", name: "Virginia"),
        .init(abbreviation: "WA", name: "Washington"),
        .init(abbreviation: "WV", name: "West Virginia"),
        .init(abbreviation: "WI", name: "Wisconsin"),
        .init(abbreviation: "WY", name: "Wyoming"),
    ]
}
