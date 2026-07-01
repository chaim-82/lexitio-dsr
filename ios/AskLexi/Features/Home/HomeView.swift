import SwiftUI
import SwiftData

/// Navigation targets reachable from Home.
enum HomeRoute: Hashable {
    case chat(seed: String?)
    case conversation(id: String)
    case deposit
    case handoff
}

/// Home: greeting, Ask Lexi entry, the featured Security Deposit flow, recent
/// conversations, and quick topics.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \CachedConversation.updatedAt, order: .reverse)
    private var conversations: [CachedConversation]

    @State private var path = NavigationPath()

    private let quickTopics: [(title: String, prompt: String)] = [
        (Strings.topicEviction, "I received an eviction notice. What are my rights and next steps?"),
        (Strings.topicRepairs, "My landlord won't make necessary repairs. What can I do?"),
        (Strings.topicLeaseReview, "Can you help me understand a clause in my lease?"),
        (Strings.topicSmallClaims, "How does small claims court work for a landlord dispute?"),
    ]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    greeting
                    askEntry
                    featuredDepositCard
                    recentSection
                    quickTopicsSection
                    DisclaimerFooter().padding(.top, Theme.Spacing.sm)
                }
                .padding(Theme.Spacing.md)
            }
            .background(BrandBackground())
            .navigationTitle(Strings.appName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { Wordmark(size: .small) }
                ToolbarItem(placement: .topBarTrailing) {
                    JurisdictionBadge(jurisdiction: appState.jurisdiction)
                }
            }
            .navigationDestination(for: HomeRoute.self, destination: destination)
        }
    }

    @ViewBuilder
    private func destination(_ route: HomeRoute) -> some View {
        switch route {
        case .chat(let seed):
            ChatView(conversationID: nil, seedPrompt: seed)
        case .conversation(let id):
            ChatView(conversationID: id, seedPrompt: nil)
        case .deposit:
            DepositIntakeView()
        case .handoff:
            HandoffView(prefillSummary: "")
        }
    }

    // MARK: Sections

    private var greeting: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(Strings.homeGreeting(appState.currentUser?.name))
                .font(Typography.display(30))
                .foregroundStyle(Theme.textPrimary)
            Text(Strings.homePrompt)
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var askEntry: some View {
        Button {
            path.append(HomeRoute.chat(seed: nil))
        } label: {
            HStack {
                Image(systemName: "sparkle.magnifyingglass")
                    .foregroundStyle(Theme.brandPrimary)
                Text(Strings.askAnything)
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(Theme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Strings.askLexi)
    }

    private var featuredDepositCard: some View {
        Button {
            path.append(HomeRoute.deposit)
        } label: {
            Card {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Image(systemName: "house.and.flag.fill")
                            .foregroundStyle(Theme.brandAccent)
                        Text(Strings.featuredDepositTitle)
                            .font(Typography.headline)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Text(Strings.featuredDepositSubtitle)
                        .font(Typography.body)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Spacer()
                        Text(Strings.startDepositFlow)
                            .font(Typography.bodyEmphasized)
                            .foregroundStyle(Theme.brandPrimary)
                        Image(systemName: "arrow.right").foregroundStyle(Theme.brandPrimary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint(Strings.featuredDepositSubtitle)
    }

    @ViewBuilder
    private var recentSection: some View {
        if !conversations.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                SectionHeader(title: Strings.recentConversations)
                ForEach(conversations.prefix(5)) { conversation in
                    Button {
                        path.append(HomeRoute.conversation(id: conversation.id))
                    } label: {
                        RecentRow(conversation: conversation)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var quickTopicsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: Strings.quickTopics)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                      spacing: Theme.Spacing.sm) {
                ForEach(quickTopics, id: \.title) { topic in
                    Button {
                        path.append(HomeRoute.chat(seed: topic.prompt))
                    } label: {
                        Text(topic.title)
                            .font(Typography.bodyEmphasized)
                            .foregroundStyle(Theme.brandPrimary)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(Theme.brandPrimary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct RecentRow: View {
    let conversation: CachedConversation
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "bubble.left")
                .foregroundStyle(Theme.brandPrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.title)
                    .font(Typography.body)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
            if let code = conversation.jurisdiction, let state = USState.named(code) {
                JurisdictionBadge(jurisdiction: state)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
            .strokeBorder(Theme.stroke, lineWidth: 1))
    }
}
