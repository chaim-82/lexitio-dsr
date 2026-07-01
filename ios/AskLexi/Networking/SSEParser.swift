import Foundation

/// One dispatched Server-Sent Event.
struct SSEEvent: Equatable {
    var event: String?
    var id: String?
    var data: String
}

/// Incremental parser for the SSE wire format (WHATWG EventSource rules), fed one
/// line at a time so it works with `URLSession.bytes(for:).lines`.
///
/// Kept pure and synchronous so it is trivially unit-testable. `consume(line:)`
/// returns an event only when a record terminates (a blank line).
struct SSEParser {
    private var dataLines: [String] = []
    private var eventType: String?
    private var lastEventID: String?

    /// Sentinel many LLM/OpenAI-style stream endpoints send to signal completion.
    static let doneToken = "[DONE]"

    /// Feed one line (without its trailing newline). Returns a completed event on
    /// a blank line, otherwise nil.
    mutating func consume(line: String) -> SSEEvent? {
        // Blank line → dispatch the buffered event (if any).
        if line.isEmpty {
            guard !dataLines.isEmpty || eventType != nil else {
                return nil
            }
            let event = SSEEvent(
                event: eventType,
                id: lastEventID,
                data: dataLines.joined(separator: "\n")
            )
            dataLines.removeAll(keepingCapacity: true)
            eventType = nil
            return event
        }

        // Comment line.
        if line.hasPrefix(":") { return nil }

        // Parse "field: value" (single optional space after the colon is stripped).
        let field: Substring
        var value: Substring = ""
        if let colon = line.firstIndex(of: ":") {
            field = line[line.startIndex..<colon]
            var afterColon = line.index(after: colon)
            if afterColon < line.endIndex, line[afterColon] == " " {
                afterColon = line.index(after: afterColon)
            }
            value = line[afterColon...]
        } else {
            field = Substring(line) // field name with empty value
        }

        switch field {
        case "data":
            dataLines.append(String(value))
        case "event":
            eventType = String(value)
        case "id":
            lastEventID = String(value)
        case "retry":
            break // reconnection time; not used here
        default:
            break // unknown field, ignore per spec
        }
        return nil
    }
}
