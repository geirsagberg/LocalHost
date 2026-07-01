import XCTest
@testable import LocalHostMonitor
import LocalHostMonitorCore

@MainActor
final class SitesViewModelAccessibilityTests: XCTestCase {
    func testTitleResetAvailabilityTracksCustomTitleState() async throws {
        let site = try makeSite()
        let viewModel = makeViewModel(sites: [site])

        await viewModel.refresh()
        let presentation = try XCTUnwrap(viewModel.visibleSitePresentations.first)

        XCTAssertFalse(viewModel.canResetTitleOverride(for: presentation))

        viewModel.setTitleOverride(for: presentation, title: "Dashboard")

        XCTAssertTrue(viewModel.canResetTitleOverride(for: presentation))
        XCTAssertTrue(try XCTUnwrap(viewModel.visibleSitePresentations.first).hasTitleOverride)

        viewModel.resetTitleOverride(for: presentation)

        XCTAssertFalse(viewModel.canResetTitleOverride(for: presentation))
        XCTAssertFalse(try XCTUnwrap(viewModel.visibleSitePresentations.first).hasTitleOverride)
    }

    func testCopyURLFeedbackMovesToMostRecentlyCopiedSite() async throws {
        let firstSite = try makeSite(port: 5173)
        let secondSite = try makeSite(port: 3000)
        let viewModel = makeViewModel(sites: [firstSite, secondSite])

        await viewModel.refresh()
        let presentations = viewModel.visibleSitePresentations
        let firstPresentation = try XCTUnwrap(presentations.first)
        let secondPresentation = try XCTUnwrap(presentations.dropFirst().first)

        viewModel.copyURL(firstPresentation)

        XCTAssertEqual(viewModel.copyFeedbackText(for: firstPresentation), "Copied")
        XCTAssertNil(viewModel.copyFeedbackText(for: secondPresentation))

        viewModel.copyURL(secondPresentation)

        XCTAssertNil(viewModel.copyFeedbackText(for: firstPresentation))
        XCTAssertEqual(viewModel.copyFeedbackText(for: secondPresentation), "Copied")
    }

    private func makeViewModel(sites: [LocalhostSite]) -> SitesViewModel {
        SitesViewModel(
            scanner: StaticScanner(sites: sites),
            preferencesStore: PreferencesStore(fileURL: temporaryPreferencesURL()),
            copyFeedbackDurationNanoseconds: 60_000_000_000,
            startsRefreshLoop: false
        )
    }

    private func temporaryPreferencesURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("Sites.json")
    }

    private func makeSite(port: Int = 5173) throws -> LocalhostSite {
        let url = try XCTUnwrap(URL(string: "http://localhost:\(port)"))
        return LocalhostSite(
            url: url,
            port: port,
            processName: "node",
            pid: 123,
            inferredTitle: "Vite App",
            httpStatusCode: 200,
            detectedAt: Date(timeIntervalSinceReferenceDate: 1)
        )
    }
}

private struct StaticScanner: LocalhostScanning {
    let sites: [LocalhostSite]

    func scan() async -> [LocalhostSite] {
        sites
    }
}
