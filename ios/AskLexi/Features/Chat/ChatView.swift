import SwiftUI
import SwiftData

/// Entry wrapper that builds the `ChatViewModel` from the environment once the
/// view appears (view models can't read `@Environment` in `init`).
struct ChatView: View {
    let conversationID: String?
    let seedPrompt: String?

    @Environment(AppEnvironment.self) private var environment
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var vm: ChatViewModel?

    var body: some View {
        Group {
            if let vm {
                ChatScreen(vm: vm)
            } else {
                LoadingStateView()
            }
        }
        .task {
            guard vm == nil else { return }
            let model = ChatViewModel(
                conversationID: conversationID,
                chat: environment.chat,
                jurisdiction: appState.jurisdiction,
                seedPrompt: seedPrompt)
            await model.onAppear(context: modelContext)
            vm = model
        }
    }
}

private struct ChatScreen: View {
    @Bindable var vm: ChatViewModel
    @State private var showHandoff = false
    @FocusState private var inputFocused: Bool

    // No NavigationStack here: the enclosing context supplies one (the tab wraps
    // this in a stack; when pushed from Home it's already inside Home's stack).
    var body: some View {
        VStack(spacing: 0) {
            messagesArea
            inputArea
        }
        .background(BrandBackground())
        .navigationTitle(Strings.askLexi)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                JurisdictionBadge(jurisdiction: vm.jurisdiction)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showHandoff = true
                } label: {
                    Label(Strings.talkToLawyer, systemImage: "person.badge.shield.checkmark")
                }
                .accessibilityLabel(Strings.talkToLawyer)
            }
        }
        .sheet(isPresented: $showHandoff) {
            HandoffView(prefillSummary: lastUserMessage)
        }
    }

    private var lastUserMessage: String {
        vm.messages.last(where: { $0.role == .user })?.text ?? ""
    }

    // MARK: Messages

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if vm.isEmpty {
                    EmptyStateView(
                        systemImage: "bubble.left.and.text.bubble.right",
                        title: Strings.chatEmptyTitle,
                        message: Strings.chatEmptyBody)
                        .padding(.top, Theme.Spacing.xxl)
                } else {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        ForEach(vm.messages) { message in
                            MessageBubble(message: message).id(message.id)
                        }
                        if let error = vm.errorMessage {
                            InlineErrorBanner(message: error)
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
                Color.clear.frame(height: 1).id("bottom")
            }
            .onChange(of: vm.messages.last?.text) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    // MARK: Input

    private var inputArea: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if !vm.suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(vm.suggestions, id: \.self) { suggestion in
                            SuggestionChip(title: suggestion) { vm.tapSuggestion(suggestion) }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }

            HStack(alignment: .bottom, spacing: Theme.Spacing.sm) {
                TextField(Strings.chatInputPlaceholder, text: $vm.input, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(Theme.Spacing.sm)
                    .background(Theme.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                        .strokeBorder(Theme.stroke, lineWidth: 1))
                    .focused($inputFocused)
                    .accessibilityLabel(Strings.chatInputPlaceholder)

                Button {
                    inputFocused = false
                    Task { await vm.send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(vm.canSend ? Theme.brandPrimary : Theme.textSecondary.opacity(0.4))
                }
                .disabled(!vm.canSend)
                .accessibilityLabel(Strings.a11ySendMessage)
            }
            .padding(.horizontal, Theme.Spacing.md)

            DisclaimerFooter().padding(.bottom, Theme.Spacing.xs)
        }
        .padding(.top, Theme.Spacing.sm)
        .background(Theme.surface)
    }
}

/// A single chat bubble. User messages are pine-tinted and right-aligned; Lexi's
/// are on an elevated surface with markdown rendering.
struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: Theme.Spacing.xl) }
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                if isUser {
                    Text(message.text)
                        .font(Typography.body)
                        .foregroundStyle(.white)
                } else if message.text.isEmpty && message.isStreaming {
                    ThinkingIndicator()
                } else {
                    MarkdownText(markdown: message.text)
                }
            }
            .padding(Theme.Spacing.md)
            .background(isUser ? Theme.brandPrimary : Theme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(isUser ? Color.clear : Theme.stroke, lineWidth: 1))
            if !isUser { Spacer(minLength: Theme.Spacing.xl) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isUser ? Strings.a11yYourMessage : Strings.a11yLexiMessage)
        .accessibilityValue(message.text)
    }
}

private struct ThinkingIndicator: View {
    @State private var animating = false
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Theme.textSecondary)
                    .frame(width: 7, height: 7)
                    .opacity(animating ? 0.3 : 1)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.2),
                               value: animating)
            }
        }
        .onAppear { animating = true }
        .accessibilityLabel(Strings.lexiThinking)
    }
}

private struct InlineErrorBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.circle")
            Text(message).font(Typography.caption)
        }
        .foregroundStyle(Theme.danger)
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.danger.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }
}
