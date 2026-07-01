import SwiftUI
import UIKit

/// Shows the rights summary, the deadline math, and the demand-letter draft with
/// copy / share affordances and a route to the attorney handoff.
struct DepositResultView: View {
    let result: DepositResult

    @State private var showShare = false
    @State private var didCopy = false
    @State private var showHandoff = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                deadlineCard
                rightsCard
                letterCard
                SecondaryButton(title: Strings.depositReviewWithLawyer,
                                systemImage: "person.badge.shield.checkmark") {
                    showHandoff = true
                }
                DisclaimerFooter()
            }
            .padding(Theme.Spacing.md)
        }
        .background(BrandBackground())
        .navigationTitle(Strings.depositTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [result.letter])
        }
        .sheet(isPresented: $showHandoff) {
            HandoffView(prefillSummary: handoffSummary)
        }
    }

    private var handoffSummary: String {
        "Security deposit dispute in \(result.intake.state.name). Deposit \(result.intake.formattedAmount), moved out and the deadline picture: \(result.deadline.isOverdue ? "deadline passed" : "\(result.deadline.daysRemaining) days remaining")."
    }

    // MARK: Cards

    private var deadlineCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                SectionHeader(title: Strings.depositDeadlineTitle)
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                    Text("\(max(0, result.deadline.isOverdue ? abs(result.deadline.daysRemaining) : result.deadline.daysRemaining))")
                        .font(Typography.display(40))
                        .foregroundStyle(result.deadline.isOverdue ? Theme.danger : Theme.brandPrimary)
                    Text(result.deadline.isOverdue ? "days past the typical deadline" : "days may remain")
                        .font(Typography.body)
                        .foregroundStyle(Theme.textSecondary)
                }
                Text("Typical window: \(result.deadline.returnDays) days after move-out · \(result.deadline.citation)")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var rightsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                SectionHeader(title: Strings.depositRightsTitle)
                MarkdownText(markdown: result.rightsMarkdown)
            }
        }
    }

    private var letterCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionHeader(title: Strings.depositLetterTitle)
                Text(result.letter)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: Theme.Spacing.md) {
                    SecondaryButton(
                        title: didCopy ? Strings.copied : Strings.depositCopyLetter,
                        systemImage: didCopy ? "checkmark" : "doc.on.doc") {
                        UIPasteboard.general.string = result.letter
                        withAnimation { didCopy = true }
                    }
                    SecondaryButton(title: Strings.depositShareLetter, systemImage: "square.and.arrow.up") {
                        showShare = true
                    }
                }
            }
        }
    }
}
