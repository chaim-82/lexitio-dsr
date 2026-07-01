import Foundation
import SwiftData
import Observation

/// A message as rendered in the chat UI.
struct ChatMessage: Identifiable, Equatable {
    let id: String
    let role: MessageRole
    var text: String
    var isStreaming: Bool

    init(id: String = UUID().uuidString, role: MessageRole, text: String, isStreaming: Bool = false) {
        self.id = id
        self.role = role
        self.text = text
        self.isStreaming = isStreaming
    }
}

@MainActor
@Observable
final class ChatViewModel {
    private(set) var messages: [ChatMessage] = []
    var input: String = ""
    private(set) var suggestions: [String] = []
    private(set) var isStreaming = false
    private(set) var errorMessage: String?
    private(set) var conversationID: String?
    let jurisdiction: USState

    private let chat: any ChatServicing
    private var modelContext: ModelContext?
    private var streamTask: Task<Void, Never>?

    init(conversationID: String?, chat: any ChatServicing, jurisdiction: USState, seedPrompt: String? = nil) {
        self.conversationID = conversationID
        self.chat = chat
        self.jurisdiction = jurisdiction
        if let seedPrompt { self.input = seedPrompt }
    }

    var isEmpty: Bool { messages.isEmpty }
    var canSend: Bool { !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isStreaming }

    /// Attach the SwiftData context for caching and load any existing history.
    func onAppear(context: ModelContext) async {
        modelContext = context
        if messages.isEmpty, let id = conversationID {
            await loadConversation(id: id)
        }
    }

    func tapSuggestion(_ text: String) {
        input = text
        Task { await send() }
    }

    func send() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }
        input = ""
        suggestions = []
        errorMessage = nil

        messages.append(ChatMessage(role: .user, text: text))
        let assistant = ChatMessage(role: .assistant, text: "", isStreaming: true)
        messages.append(assistant)
        isStreaming = true

        let request = SendMessageRequest(
            conversationId: conversationID,
            content: text,
            jurisdiction: jurisdiction.abbreviation)

        streamTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await event in self.chat.streamMessage(request) {
                    if Task.isCancelled { break }
                    switch event {
                    case .conversationId(let id): self.conversationID = id
                    case .delta(let delta): self.append(delta, to: assistant.id)
                    case .suggestions(let suggestions): self.suggestions = suggestions
                    case .done: break
                    }
                }
            } catch {
                self.handleStreamFailure(error, assistantID: assistant.id)
            }
            self.finishStreaming(assistantID: assistant.id)
        }
        await streamTask?.value
    }

    func cancelStreaming() {
        streamTask?.cancel()
        isStreaming = false
    }

    // MARK: Mutation helpers

    private func append(_ delta: String, to id: String) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].text += delta
    }

    private func finishStreaming(assistantID: String) {
        if let index = messages.firstIndex(where: { $0.id == assistantID }) {
            messages[index].isStreaming = false
            // Drop an empty assistant bubble left behind by an error.
            if messages[index].text.isEmpty { messages.remove(at: index) }
        }
        isStreaming = false
        persist()
    }

    private func handleStreamFailure(_ error: Error, assistantID: String) {
        errorMessage = (error as? APIError)?.userMessage ?? Strings.chatSendError
    }

    // MARK: Persistence

    private func loadConversation(id: String) async {
        // Prefer local cache, then network.
        if let context = modelContext,
           let cached = try? context.fetch(
            FetchDescriptor<CachedConversation>(
                predicate: #Predicate { $0.id == id })).first {
            messages = cached.messages
                .sorted { $0.createdAt < $1.createdAt }
                .map { ChatMessage(id: $0.id, role: $0.role, text: $0.content) }
            if !messages.isEmpty { return }
        }
        if let remote = try? await chat.fetchConversation(id: id), let msgs = remote.messages {
            messages = msgs.map { ChatMessage(id: $0.id, role: $0.role, text: $0.content) }
        }
    }

    private func persist() {
        guard let context = modelContext, let id = conversationID, !messages.isEmpty else { return }
        let title = messages.first(where: { $0.role == .user })?.text ?? Strings.newConversation
        let descriptor = FetchDescriptor<CachedConversation>(predicate: #Predicate { $0.id == id })
        let conversation: CachedConversation
        if let existing = try? context.fetch(descriptor).first {
            conversation = existing
            conversation.messages.forEach(context.delete)
            conversation.messages = []
            conversation.updatedAt = .now
        } else {
            conversation = CachedConversation(
                id: id, title: String(title.prefix(80)), jurisdiction: jurisdiction.abbreviation)
            context.insert(conversation)
        }
        for message in messages where !message.isStreaming {
            let cached = CachedMessage(
                id: message.id, roleRaw: message.role.rawValue, content: message.text)
            cached.conversation = conversation
            conversation.messages.append(cached)
        }
        try? context.save()
    }
}
