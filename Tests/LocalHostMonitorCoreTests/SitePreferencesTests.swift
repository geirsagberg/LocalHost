import XCTest
@testable import LocalHostMonitorCore

final class SitePreferencesTests: XCTestCase {
    func testOverridesRoundTripThroughJSON() throws {
        let overrides = [
            "http://localhost:3000": SiteOverride(title: "Dashboard", emoji: .custom("🧪")),
            "http://localhost:5173": SiteOverride(title: nil, emoji: .cleared)
        ]

        let data = try JSONEncoder().encode(overrides)
        let decoded = try JSONDecoder().decode([String: SiteOverride].self, from: data)

        XCTAssertEqual(decoded, overrides)
    }

    func testClearedEmojiKeepsOverrideAlive() {
        XCTAssertFalse(SiteOverride(title: nil, emoji: .cleared).isEmpty)
        XCTAssertFalse(SiteOverride(title: nil, emoji: .automatic, isHidden: true).isEmpty)
        XCTAssertTrue(SiteOverride(title: "  ", emoji: .automatic).isEmpty)
    }

    func testMissingHiddenFlagDefaultsToFalse() throws {
        let json = """
        {
          "title": "Dashboard",
          "emoji": {
            "type": "automatic"
          }
        }
        """

        let override = try JSONDecoder().decode(SiteOverride.self, from: Data(json.utf8))

        XCTAssertEqual(override.title, "Dashboard")
        XCTAssertEqual(override.emoji, .automatic)
        XCTAssertFalse(override.isHidden)
    }
}
