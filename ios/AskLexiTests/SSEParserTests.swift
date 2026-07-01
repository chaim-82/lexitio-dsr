import XCTest
@testable import AskLexi

final class SSEParserTests: XCTestCase {

    private func events(from lines: [String]) -> [SSEEvent] {
        var parser = SSEParser()
        var out: [SSEEvent] = []
        for line in lines {
            if let event = parser.consume(line: line) { out.append(event) }
        }
        return out
    }

    func testSingleDataEventDispatchesOnBlankLine() {
        let events = events(from: ["data: hello", ""])
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.data, "hello")
    }

    func testMultipleDataLinesAreJoinedWithNewline() {
        let events = events(from: ["data: line1", "data: line2", ""])
        XCTAssertEqual(events.first?.data, "line1\nline2")
    }

    func testEventTypeAndIdAreCaptured() {
        let events = events(from: ["event: token", "id: 42", "data: x", ""])
        XCTAssertEqual(events.first?.event, "token")
        XCTAssertEqual(events.first?.id, "42")
        XCTAssertEqual(events.first?.data, "x")
    }

    func testCommentAndNoDataProduceNoEvent() {
        let events = events(from: [": this is a comment", ""])
        XCTAssertTrue(events.isEmpty)
    }

    func testLeadingSpaceAfterColonIsStripped() {
        let events = events(from: ["data:  two spaces", ""])
        // Only one leading space is stripped per spec.
        XCTAssertEqual(events.first?.data, " two spaces")
    }

    func testDoneSentinelIsPreservedAsData() {
        let events = events(from: ["data: [DONE]", ""])
        XCTAssertEqual(events.first?.data, SSEParser.doneToken)
    }

    func testFieldWithoutColonHasEmptyValue() {
        // A bare "data" line contributes an empty data line.
        let events = events(from: ["data", ""])
        XCTAssertEqual(events.first?.data, "")
    }

    func testTwoEventsBackToBack() {
        let events = events(from: ["data: a", "", "data: b", ""])
        XCTAssertEqual(events.map(\.data), ["a", "b"])
    }
}
