import SwiftUI

/// A parsed markdown block. Lexi replies are lightweight markdown (headings,
/// paragraphs, bullet and numbered lists, plus inline bold/italic/code/links),
/// so we parse block structure ourselves and hand inline spans to Foundation's
/// `AttributedString(markdown:)`. No third-party dependency.
enum MarkdownBlock: Equatable, Identifiable {
    case heading(level: Int, text: AttributedString)
    case paragraph(AttributedString)
    case bulleted([AttributedString])
    case numbered([AttributedString])

    var id: String {
        switch self {
        case .heading(let level, let text): return "h\(level):\(text.characters.count):\(String(text.characters))"
        case .paragraph(let text): return "p:\(String(text.characters))"
        case .bulleted(let items): return "ul:\(items.count):\(items.first.map { String($0.characters) } ?? "")"
        case .numbered(let items): return "ol:\(items.count):\(items.first.map { String($0.characters) } ?? "")"
        }
    }
}

enum MarkdownParser {
    /// Parse markdown text into a sequence of blocks.
    static func parse(_ markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraphLines: [String] = []
        var bullets: [String] = []
        var numbers: [String] = []

        func flushParagraph() {
            guard !paragraphLines.isEmpty else { return }
            blocks.append(.paragraph(inline(paragraphLines.joined(separator: " "))))
            paragraphLines.removeAll()
        }
        func flushBullets() {
            guard !bullets.isEmpty else { return }
            blocks.append(.bulleted(bullets.map(inline)))
            bullets.removeAll()
        }
        func flushNumbers() {
            guard !numbers.isEmpty else { return }
            blocks.append(.numbered(numbers.map(inline)))
            numbers.removeAll()
        }
        func flushAll() { flushParagraph(); flushBullets(); flushNumbers() }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                flushAll()
                continue
            }
            if let heading = headingLevel(line) {
                flushAll()
                let text = String(line.drop(while: { $0 == "#" })).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(level: heading, text: inline(text)))
                continue
            }
            if let bullet = bulletContent(line) {
                flushParagraph(); flushNumbers()
                bullets.append(bullet)
                continue
            }
            if let numbered = numberedContent(line) {
                flushParagraph(); flushBullets()
                numbers.append(numbered)
                continue
            }
            // Plain text line → accumulate into the current paragraph.
            flushBullets(); flushNumbers()
            paragraphLines.append(line)
        }
        flushAll()
        return blocks
    }

    /// Render inline markdown (bold/italic/code/links) to an AttributedString,
    /// falling back to plain text if parsing fails.
    static func inline(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace)
        if let attributed = try? AttributedString(markdown: text, options: options) {
            return attributed
        }
        return AttributedString(text)
    }

    // MARK: Line classification

    private static func headingLevel(_ line: String) -> Int? {
        guard line.hasPrefix("#") else { return nil }
        let hashes = line.prefix(while: { $0 == "#" }).count
        guard hashes <= 6, line.count > hashes, line[line.index(line.startIndex, offsetBy: hashes)] == " " else {
            return nil
        }
        return hashes
    }

    private static func bulletContent(_ line: String) -> String? {
        for marker in ["- ", "* ", "• "] where line.hasPrefix(marker) {
            return String(line.dropFirst(marker.count))
        }
        return nil
    }

    private static func numberedContent(_ line: String) -> String? {
        // Match "<digits>. " or "<digits>) ".
        let digits = line.prefix(while: { $0.isNumber })
        guard !digits.isEmpty else { return nil }
        let rest = line.dropFirst(digits.count)
        guard rest.hasPrefix(". ") || rest.hasPrefix(") ") else { return nil }
        return String(rest.dropFirst(2))
    }
}

/// Renders parsed markdown as native SwiftUI Text blocks with brand styling.
struct MarkdownText: View {
    let markdown: String
    var textColor: Color = Theme.textPrimary

    private var blocks: [MarkdownBlock] { MarkdownParser.parse(markdown) }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(blocks) { block in
                switch block {
                case .heading(let level, let text):
                    Text(text)
                        .font(.system(size: headingSize(level), weight: .semibold, design: .serif))
                        .foregroundStyle(textColor)
                case .paragraph(let text):
                    Text(text).font(Typography.body).foregroundStyle(textColor)
                case .bulleted(let items):
                    listRows(items, ordered: false)
                case .numbered(let items):
                    listRows(items, ordered: true)
                }
            }
        }
        .tint(Theme.brandPrimary) // link color
    }

    private func listRows(_ items: [AttributedString], ordered: Bool) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                    Text(ordered ? "\(index + 1)." : "•")
                        .font(Typography.body)
                        .foregroundStyle(Theme.brandPrimary)
                    Text(item).font(Typography.body).foregroundStyle(textColor)
                }
            }
        }
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level {
        case 1: return 24
        case 2: return 20
        default: return 17
        }
    }
}
