import XCTest
@testable import AskLexi

final class MarkdownParserTests: XCTestCase {

    func testParagraphParsing() {
        let blocks = MarkdownParser.parse("Hello world.")
        XCTAssertEqual(blocks.count, 1)
        guard case .paragraph = blocks.first else {
            return XCTFail("Expected paragraph")
        }
    }

    func testHeadingLevels() {
        let blocks = MarkdownParser.parse("# Title\n## Subtitle")
        XCTAssertEqual(blocks.count, 2)
        if case .heading(let l1, _) = blocks[0] { XCTAssertEqual(l1, 1) } else { XCTFail() }
        if case .heading(let l2, _) = blocks[1] { XCTAssertEqual(l2, 2) } else { XCTFail() }
    }

    func testBulletedList() {
        let blocks = MarkdownParser.parse("- one\n- two\n- three")
        XCTAssertEqual(blocks.count, 1)
        guard case .bulleted(let items) = blocks.first else {
            return XCTFail("Expected bulleted list")
        }
        XCTAssertEqual(items.count, 3)
    }

    func testNumberedList() {
        let blocks = MarkdownParser.parse("1. first\n2. second")
        guard case .numbered(let items) = blocks.first else {
            return XCTFail("Expected numbered list")
        }
        XCTAssertEqual(items.count, 2)
    }

    func testMixedBlocksSeparatedByBlankLines() {
        let markdown = "# Rights\n\nYou have options.\n\n- Option A\n- Option B"
        let blocks = MarkdownParser.parse(markdown)
        XCTAssertEqual(blocks.count, 3)
        guard case .heading = blocks[0] else { return XCTFail() }
        guard case .paragraph = blocks[1] else { return XCTFail() }
        guard case .bulleted = blocks[2] else { return XCTFail() }
    }

    func testInlineBoldIsInterpreted() {
        let attributed = MarkdownParser.inline("This is **bold** text")
        // Rendered characters drop the asterisks when markdown is interpreted.
        XCTAssertFalse(String(attributed.characters).contains("**"))
        XCTAssertTrue(String(attributed.characters).contains("bold"))
    }

    func testHashWithoutSpaceIsNotHeading() {
        let blocks = MarkdownParser.parse("#hashtag not a heading")
        guard case .paragraph = blocks.first else {
            return XCTFail("Expected paragraph, not heading")
        }
    }
}
