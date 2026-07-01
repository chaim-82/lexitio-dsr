import Foundation

/// Structured intake for the security deposit flow.
struct DepositIntake: Equatable, Sendable {
    var state: USState
    var moveOutDate: Date
    var depositAmountCents: Int
    var itemizationReceived: Bool

    /// Currency-formatted deposit amount (USD).
    var formattedAmount: String {
        Self.currency(cents: depositAmountCents)
    }

    static func currency(cents: Int) -> String {
        let value = Decimal(cents) / 100
        return value.formatted(.currency(code: "USD").precision(.fractionLength(cents % 100 == 0 ? 0 : 2)))
    }
}

/// Builds the rights summary and demand-letter draft from the intake + deadline.
/// Pure functions so the generated text is testable and deterministic.
enum DepositContentBuilder {

    /// Markdown rights summary shown above the letter.
    static func rightsSummary(intake: DepositIntake, deadline: DepositDeadline) -> String {
        let amount = intake.formattedAmount
        let cite = deadline.citation
        var lines: [String] = []
        lines.append("In **\(intake.state.name)**, a landlord generally must return your security deposit — or give you an itemized statement of any deductions — within **\(deadline.returnDays) days** of the end of your tenancy (\(cite)).")
        lines.append("")
        lines.append("- Your deposit: **\(amount)**")
        if intake.itemizationReceived {
            lines.append("- You reported you **did** receive an itemized statement of deductions. You can dispute charges you believe are improper.")
        } else {
            lines.append("- You reported you **did not** receive an itemized statement. In many states, failing to itemize on time can limit or forfeit a landlord's right to keep any of the deposit.")
        }
        if deadline.isOverdue {
            lines.append("- The typical deadline appears to have **passed** (about \(abs(deadline.daysRemaining)) day(s) ago). A written demand is often the right next step.")
        } else {
            lines.append("- About **\(max(0, deadline.daysRemaining)) day(s)** may remain before the typical deadline (around \(formattedDate(deadline.deadlineDate))).")
        }
        lines.append("")
        lines.append("This is legal information to help you understand your options — not legal advice.")
        return lines.joined(separator: "\n")
    }

    /// A ready-to-send demand letter as plain text (for copy / share sheet).
    static func demandLetter(intake: DepositIntake, deadline: DepositDeadline) -> String {
        let amount = intake.formattedAmount
        let today = formattedDate(.now)
        let moveOut = formattedDate(intake.moveOutDate)
        let responseWindow = max(7, min(14, deadline.returnDays))

        return """
        \(today)

        [Your Name]
        [Your Current Address]
        [City, State ZIP]

        [Landlord / Property Manager Name]
        [Landlord Address]
        [City, State ZIP]

        Re: Return of Security Deposit — [Rental Property Address]

        Dear [Landlord Name],

        I am writing regarding the security deposit of \(amount) that I paid in \
        connection with my tenancy at the above property. My tenancy ended on \
        \(moveOut).

        Under \(deadline.citation), a landlord in \(intake.state.name) is generally \
        required to return a tenant's security deposit, or provide an itemized \
        statement of any lawful deductions, within \(deadline.returnDays) days after \
        the tenancy ends. \(itemizationSentence(intake: intake))

        I request that you return the full deposit of \(amount), or provide a written, \
        itemized statement of any deductions together with any remaining balance, \
        within \(responseWindow) days of the date of this letter. Please send payment \
        and any statement to my address above.

        If I do not receive a response within that time, I may pursue the remedies \
        available to me, which can include filing a claim in small claims court.

        Thank you for your prompt attention to this matter.

        Sincerely,

        [Your Name]
        [Phone] · [Email]

        —
        Prepared with Lexi (asklexi.legal). This letter is a self-help template and \
        is legal information, not legal advice.
        """
    }

    private static func itemizationSentence(intake: DepositIntake) -> String {
        intake.itemizationReceived
            ? "I have received a statement of deductions, and I dispute the charges that I believe are not permitted."
            : "To date, I have not received an itemized statement of any deductions."
    }

    private static func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).day().year())
    }
}
