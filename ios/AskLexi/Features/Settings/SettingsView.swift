import SwiftUI

/// Wraps a URL so it can drive `.sheet(item:)`.
private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppEnvironment.self) private var environment

    @State private var jurisdiction: USState = .newYork
    @State private var legalPage: IdentifiableURL?
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    private var manager: SubscriptionManager { environment.subscriptionManager }

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                subscriptionSection
                jurisdictionSection
                legalSection
                dangerSection
            }
            .scrollContentBackground(.hidden)
            .background(BrandBackground())
            .navigationTitle(Strings.settingsTitle)
            .sheet(item: $legalPage) { page in SafariView(url: page.url) }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert(Strings.deleteConfirmTitle, isPresented: $showDeleteConfirm) {
                Button(Strings.cancel, role: .cancel) {}
                Button(Strings.deleteConfirmAction, role: .destructive) {
                    Task { await deleteAccount() }
                }
            } message: {
                Text(Strings.deleteConfirmBody)
            }
            .alert(Strings.genericErrorTitle, isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } })) {
                Button(Strings.done, role: .cancel) {}
            } message: {
                Text(deleteError ?? "")
            }
            .onAppear { jurisdiction = appState.jurisdiction }
        }
    }

    // MARK: Sections

    private var accountSection: some View {
        Section(Strings.settingsAccount) {
            if let user = appState.currentUser {
                LabeledContent("Name", value: user.name ?? "—")
                LabeledContent("Email", value: user.email ?? "—")
            } else {
                Text("Signed in").foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var subscriptionSection: some View {
        Section(Strings.settingsSubscription) {
            LabeledContent(Strings.currentPlan, value: manager.activeTier.displayName)
            Button {
                showPaywall = true
            } label: {
                Label(Strings.paywallTitle, systemImage: "sparkles")
            }
        }
    }

    private var jurisdictionSection: some View {
        Section(Strings.settingsJurisdiction) {
            NavigationLink {
                StatePickerView(selection: $jurisdiction) { state in
                    appState.setJurisdiction(state)
                }
                .navigationTitle(Strings.settingsJurisdiction)
            } label: {
                HStack {
                    Text(Strings.settingsJurisdiction)
                    Spacer()
                    Text(appState.jurisdiction.name).foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private var legalSection: some View {
        Section(Strings.settingsLegal) {
            legalRow(Strings.legalTerms, url: Config.LegalURLs.terms)
            legalRow(Strings.legalPrivacy, url: Config.LegalURLs.privacy)
            legalRow(Strings.legalDisclaimer, url: Config.LegalURLs.disclaimer)
            Text(Strings.uplFooter)
                .font(Typography.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func legalRow(_ title: String, url: URL) -> some View {
        Button { legalPage = IdentifiableURL(url: url) } label: {
            HStack {
                Text(title).foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right.square").foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                Task { await appState.signOut() }
            } label: {
                Label(Strings.settingsSignOut, systemImage: "rectangle.portrait.and.arrow.right")
            }
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                if isDeleting {
                    ProgressView()
                } else {
                    Label(Strings.settingsDeleteAccount, systemImage: "trash")
                        .foregroundStyle(Theme.danger)
                }
            }
            .disabled(isDeleting)
        } footer: {
            Wordmark(size: .small).padding(.top, Theme.Spacing.md)
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await appState.deleteAccount()
        } catch let error as APIError {
            deleteError = error.userMessage
        } catch {
            deleteError = Strings.genericErrorBody
        }
    }
}
