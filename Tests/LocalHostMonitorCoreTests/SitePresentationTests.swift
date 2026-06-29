import XCTest
@testable import LocalHostMonitorCore

final class SitePresentationTests: XCTestCase {
    func testPresentationCombinesSiteMetadataAndPreferences() throws {
        let site = try makeSite(
            port: 5173,
            processName: "node",
            pid: 123,
            inferredTitle: " Vite App ",
            statusCode: 200
        )
        let override = SiteOverride(
            title: "Dashboard",
            emoji: .custom("🧪"),
            isHidden: true
        )

        let presentation = SitePresentation(site: site, override: override)

        XCTAssertEqual(presentation.title, "Dashboard")
        XCTAssertEqual(presentation.emoji, "🧪")
        XCTAssertEqual(presentation.urlText, "http://localhost:5173")
        XCTAssertEqual(presentation.statusText, "HTTP 200")
        XCTAssertEqual(presentation.processName, "node")
        XCTAssertEqual(presentation.pidText, "PID 123")
        XCTAssertTrue(presentation.isHidden)
        XCTAssertFalse(presentation.isVisibleInDefaultView)
        XCTAssertEqual(presentation.menuTitle, "🧪 Dashboard :5173")
    }

    func testPresentationFallsBackToInferredTitleAndAutomaticEmoji() throws {
        let site = try makeSite(
            port: 3000,
            processName: nil,
            pid: nil,
            inferredTitle: "  Preview ",
            statusCode: 200
        )

        let presentation = SitePresentation(site: site)

        XCTAssertEqual(presentation.title, "Preview")
        XCTAssertEqual(presentation.emoji, EmojiAssigner.emoji(for: site.preferenceKey))
        XCTAssertNil(presentation.processName)
        XCTAssertNil(presentation.pidText)
        XCTAssertFalse(presentation.isHidden)
        XCTAssertTrue(presentation.isVisibleInDefaultView)
        XCTAssertEqual(presentation.menuTitle, "\(EmojiAssigner.emoji(for: site.preferenceKey)) Preview :3000")
    }

    func testMenuTitleIncludesStatusForNonOKSites() throws {
        let site = try makeSite(
            port: 4040,
            processName: "server",
            pid: 456,
            inferredTitle: "Missing",
            statusCode: 404
        )

        let presentation = SitePresentation(
            site: site,
            override: SiteOverride(emoji: .cleared)
        )

        XCTAssertFalse(presentation.isVisibleInDefaultView)
        XCTAssertEqual(presentation.menuTitle, "Missing :4040 HTTP 404")
    }

    func testVisiblePresentationsRespectDefaultViewRules() throws {
        let visibleSite = try makeSite(port: 3000, statusCode: 200)
        let hiddenSite = try makeSite(port: 5173, statusCode: 200)
        let notOKSite = try makeSite(port: 8080, statusCode: 500)
        let sites = [visibleSite, hiddenSite, notOKSite]
        let overrides = [
            hiddenSite.preferenceKey: SiteOverride(isHidden: true)
        ]

        let defaultView = SitePresentation.visiblePresentations(
            for: sites,
            overrides: overrides,
            showsAllResponses: false
        )
        let allEntries = SitePresentation.visiblePresentations(
            for: sites,
            overrides: overrides,
            showsAllResponses: true
        )

        XCTAssertEqual(defaultView.map(\.site.port), [3000])
        XCTAssertEqual(allEntries.map(\.site.port), [3000, 5173, 8080])
    }

    func testTitleOverrideValueDropsEquivalentTitles() throws {
        let site = try makeSite(
            port: 3000,
            inferredTitle: "Inferred",
            statusCode: 200
        )

        XCTAssertNil(SitePresentation.titleOverrideValue(for: site, rawTitle: " "))
        XCTAssertNil(SitePresentation.titleOverrideValue(for: site, rawTitle: " Inferred "))
        XCTAssertNil(SitePresentation.titleOverrideValue(for: site, rawTitle: "localhost:3000"))
        XCTAssertEqual(
            SitePresentation.titleOverrideValue(for: site, rawTitle: " Dashboard "),
            "Dashboard"
        )
    }

    func testEmojiPreferenceUsesMostRecentlyInsertedEmoji() {
        XCTAssertEqual(SitePresentation.emojiPreference(for: ""), .cleared)
        XCTAssertEqual(SitePresentation.emojiPreference(for: "🚀🧪"), .custom("🧪"))
    }

    private func makeSite(
        port: Int,
        processName: String? = "test-server",
        pid: Int? = 123,
        inferredTitle: String? = "Test",
        statusCode: Int
    ) throws -> LocalhostSite {
        let url = try XCTUnwrap(URL(string: "http://localhost:\(port)"))
        return LocalhostSite(
            url: url,
            port: port,
            processName: processName,
            pid: pid,
            inferredTitle: inferredTitle,
            httpStatusCode: statusCode,
            detectedAt: Date(timeIntervalSince1970: 0)
        )
    }
}
