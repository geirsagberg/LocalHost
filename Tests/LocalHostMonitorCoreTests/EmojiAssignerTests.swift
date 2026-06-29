import XCTest
@testable import LocalHostMonitorCore

final class EmojiAssignerTests: XCTestCase {
    func testEmojiIsDeterministicForTheSameKey() {
        let key = "http://localhost:3000"

        let first = EmojiAssigner.emoji(for: key)
        let second = EmojiAssigner.emoji(for: key)

        XCTAssertEqual(first, second)
        XCTAssertTrue(EmojiAssigner.choices.contains(first))
    }
}
