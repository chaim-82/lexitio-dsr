import SwiftUI

/// Attorney handoff: a brief form that posts a reverse-auction marketplace
/// request, then a confirmation that sets expectations. Copy is careful never to
/// imply Lexi/Lexitio is a law firm or that an attorney-client relationship
/// exists.
struct HandoffView: View {
    var prefillSummary: String = ""

    @Environment(AppEnvironment.self) private var environment
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var vm: HandoffViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    content(vm: vm)
                } else {
                    LoadingStateView()
                }
            }
            .background(BrandBackground())
            .navigationTitle(Strings.handoffTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.close) { dismiss() }
                }
            }
        }
        .task {
            if vm == nil { vm = HandoffViewModel(prefillSummary: prefillSummary) }
        }
    }

    @ViewBuilder
    private func content(vm: HandoffViewModel) -> some View {
        if vm.phase == .submitted {
            confirmation
        } else {
            form(model: vm)
        }
    }

    @ViewBuilder
    private func form(model: HandoffViewModel) -> some View {
        @Bindable var vm = model
        Form {
            Section {
                Text(Strings.handoffIntro)
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondary)
                    .listRowBackground(Color.clear)
            }
            Section(Strings.handoffIssueLabel) {
                TextEditor(text: $vm.summary)
                    .frame(minHeight: 120)
                    .overlay(alignment: .topLeading) {
                        if vm.summary.isEmpty {
                            Text(Strings.handoffIssuePlaceholder)
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }
                    .accessibilityLabel(Strings.handoffIssueLabel)
            }
            Section(Strings.handoffBudgetLabel) {
                TextField(Strings.depositAmountPlaceholder, text: $vm.budgetText)
                    .keyboardType(.decimalPad)
            }
            if case .failed(let message) = vm.phase {
                Section {
                    Text(message).font(Typography.caption).foregroundStyle(Theme.danger)
                        .listRowBackground(Color.clear)
                }
            }
            Section {
                PrimaryButton(
                    title: Strings.handoffSubmit,
                    isLoading: vm.phase == .submitting,
                    isEnabled: vm.canSubmit
                ) {
                    Task { await vm.submit(using: environment.marketplace, jurisdiction: appState.jurisdiction) }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var confirmation: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.brandPrimary)
            Text(Strings.handoffConfirmTitle)
                .font(Typography.title())
                .foregroundStyle(Theme.textPrimary)
            Text(Strings.handoffConfirmBody)
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)
            Spacer()
            PrimaryButton(title: Strings.handoffBackHome) { dismiss() }
                .padding(.horizontal, Theme.Spacing.lg)
        }
        .padding(.bottom, Theme.Spacing.lg)
    }
}
