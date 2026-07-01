import SwiftUI

/// The generated output of the deposit flow, used as a navigation destination.
struct DepositResult: Identifiable, Hashable {
    let id = UUID()
    let intake: DepositIntake
    let deadline: DepositDeadline
    let rightsMarkdown: String
    let letter: String

    static func == (lhs: DepositResult, rhs: DepositResult) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Structured intake for the Security Deposit wedge flow.
struct DepositIntakeView: View {
    @Environment(AppState.self) private var appState

    @State private var state: USState = .newYork
    @State private var moveOutDate = Date.now
    @State private var amountText = ""
    @State private var itemizationReceived = false
    @State private var result: DepositResult?
    @State private var didSeedState = false

    private var amountCents: Int {
        // Parse a lenient dollar string ("1,250.50", "$1250") into cents.
        let cleaned = amountText.filter { $0.isNumber || $0 == "." }
        guard let dollars = Decimal(string: cleaned) else { return 0 }
        let cents = (dollars * 100) as NSDecimalNumber
        return cents.intValue
    }

    private var canGenerate: Bool { amountCents > 0 }

    var body: some View {
        Form {
            Section {
                Text(Strings.depositIntro)
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondary)
                    .listRowBackground(Color.clear)
            }

            Section(Strings.depositState) {
                NavigationLink {
                    StatePickerView(selection: $state)
                        .navigationTitle(Strings.depositState)
                } label: {
                    HStack {
                        Text(Strings.depositState)
                        Spacer()
                        Text(state.name).foregroundStyle(Theme.textSecondary)
                    }
                }
            }

            Section(Strings.depositMoveOut) {
                DatePicker(Strings.depositMoveOut, selection: $moveOutDate,
                           in: ...Date.now, displayedComponents: .date)
                    .datePickerStyle(.compact)
                Text(Strings.depositDaysElapsedNote)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Section(Strings.depositAmount) {
                TextField(Strings.depositAmountPlaceholder, text: $amountText)
                    .keyboardType(.decimalPad)
                    .accessibilityLabel(Strings.depositAmount)
            }

            Section {
                Toggle(Strings.depositItemization, isOn: $itemizationReceived)
                    .tint(Theme.brandPrimary)
            }

            Section {
                PrimaryButton(title: Strings.depositGenerate, isEnabled: canGenerate) {
                    generate()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } footer: {
                DisclaimerFooter().padding(.top, Theme.Spacing.sm)
            }
        }
        .scrollContentBackground(.hidden)
        .background(BrandBackground())
        .navigationTitle(Strings.depositTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $result) { result in
            DepositResultView(result: result)
        }
        .onAppear {
            guard !didSeedState else { return }
            state = appState.jurisdiction
            didSeedState = true
        }
    }

    private func generate() {
        let intake = DepositIntake(
            state: state,
            moveOutDate: moveOutDate,
            depositAmountCents: amountCents,
            itemizationReceived: itemizationReceived)
        let deadline = DepositDeadlineCalculator.compute(
            stateCode: state.abbreviation, moveOutDate: moveOutDate)
        result = DepositResult(
            intake: intake,
            deadline: deadline,
            rightsMarkdown: DepositContentBuilder.rightsSummary(intake: intake, deadline: deadline),
            letter: DepositContentBuilder.demandLetter(intake: intake, deadline: deadline))
    }
}
