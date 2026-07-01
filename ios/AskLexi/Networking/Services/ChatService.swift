import Foundation

/// A single event emitted while a Lexi response streams in.
enum ChatStreamEvent: Sendable, Equatable {
    /// The (possibly newly created) conversation id for this exchange.
    case conversationId(String)
    /// An incremental text delta to append to the assistant message.
    case delta(String)
    /// Suggested follow-up prompts, delivered near the end of a response.
    case suggestions([String])
    /// The response is complete.
    case done
}

protocol ChatServicing: Sendable {
    /// Stream a Lexi response for the given message. Falls back to a single
    /// delta if the backend responds non-streaming.
    func streamMessage(_ request: SendMessageRequest) -> AsyncThrowingStream<ChatStreamEvent, Error>
    func fetchConversations() async throws -> [ConversationDTO]
    func fetchConversation(id: String) async throws -> ConversationDTO
}

// MARK: - Live

struct LiveChatService: ChatServicing {
    let api: APIClient

    func streamMessage(_ request: SendMessageRequest) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let endpoint = Endpoint(
                        .post, "chat",
                        body: Endpoint.json(request),
                        accept: "text/event-stream")
                    let (bytes, response) = try await api.bytes(for: endpoint)
                    let contentType = response.value(forHTTPHeaderField: "Content-Type") ?? ""

                    if contentType.contains("text/event-stream") {
                        var parser = SSEParser()
                        for try await line in bytes.lines {
                            if let event = parser.consume(line: line),
                               emit(event.data, to: continuation) {
                                break // terminal chunk
                            }
                        }
                    } else {
                        // Non-streaming fallback: accumulate and emit once.
                        var data = Data()
                        for try await byte in bytes { data.append(byte) }
                        _ = emit(String(decoding: data, as: UTF8.self), to: continuation)
                    }
                    continuation.yield(.done)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Decodes one SSE `data:` payload and yields the mapped events. Returns
    /// true when this payload signals completion.
    private func emit(_ payload: String,
                      to continuation: AsyncThrowingStream<ChatStreamEvent, Error>.Continuation) -> Bool {
        if payload == SSEParser.doneToken { return true }
        guard let chunk = try? JSONCoding.decoder.decode(
            ChatStreamChunk.self, from: Data(payload.utf8)) else {
            // Tolerate raw text deltas that aren't JSON-wrapped.
            if !payload.isEmpty { continuation.yield(.delta(payload)) }
            return false
        }
        if let id = chunk.conversationId { continuation.yield(.conversationId(id)) }
        if let delta = chunk.delta, !delta.isEmpty { continuation.yield(.delta(delta)) }
        if let suggestions = chunk.suggestions { continuation.yield(.suggestions(suggestions)) }
        return chunk.done == true
    }

    func fetchConversations() async throws -> [ConversationDTO] {
        try await api.send(Endpoint(.get, "conversations"))
    }

    func fetchConversation(id: String) async throws -> ConversationDTO {
        try await api.send(Endpoint(.get, "conversations/\(id)"))
    }
}

// MARK: - Stub

/// Simulates a streaming Lexi response so the whole app is usable offline / in
/// the simulator. Mirrors the shape of the live stream (id → deltas → suggestions
/// → done). See BACKEND_TODO.md for the endpoints this stands in for.
struct StubChatService: ChatServicing {
    func streamMessage(_ request: SendMessageRequest) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        let jurisdiction = request.jurisdiction ?? "your state"
        let reply = """
        Here's how this generally works in \(jurisdiction). I can explain your \
        rights, the typical deadlines, and your options — but remember this is \
        legal information, not legal advice.

        A few things usually matter most:
        1. The written notice and any timelines that have started.
        2. The documents you already have (your lease, receipts, photos).
        3. What outcome you're hoping for.

        Tell me a bit more and I'll walk you through the next step.
        """
        let suggestions = [
            "What are my deadlines?",
            "What documents should I gather?",
            "Can I take this to small claims?",
        ]

        return AsyncThrowingStream { continuation in
            let task = Task {
                continuation.yield(.conversationId(
                    request.conversationId ?? "stub-\(request.content.count)"))
                for word in reply.split(separator: " ", omittingEmptySubsequences: false) {
                    if Task.isCancelled { break }
                    continuation.yield(.delta(String(word) + " "))
                    try? await Task.sleep(for: .milliseconds(18))
                }
                continuation.yield(.suggestions(suggestions))
                continuation.yield(.done)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func fetchConversations() async throws -> [ConversationDTO] {
        [
            ConversationDTO(id: "c1", title: "Security deposit not returned",
                            jurisdiction: "NY", updatedAt: nil, messages: nil),
            ConversationDTO(id: "c2", title: "Landlord won't make repairs",
                            jurisdiction: "NY", updatedAt: nil, messages: nil),
        ]
    }

    func fetchConversation(id: String) async throws -> ConversationDTO {
        ConversationDTO(
            id: id, title: "Conversation", jurisdiction: "NY", updatedAt: nil,
            messages: [
                MessageDTO(id: "m1", role: .user,
                           content: "My landlord hasn't returned my deposit.", createdAt: nil),
                MessageDTO(id: "m2", role: .assistant,
                           content: "Let's look at your rights and the deadline that applies.",
                           createdAt: nil),
            ])
    }
}
