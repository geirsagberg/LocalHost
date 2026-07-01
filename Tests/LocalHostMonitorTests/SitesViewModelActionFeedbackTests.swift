import AppKit
import XCTest
@testable import LocalHostMonitor
import LocalHostMonitorCore

@MainActor
final class SitesViewModelActionFeedbackTests: XCTestCase {
    func testResetTitleOverrideAvailabilityTracksCurrentSitePreferences() async throws {
        let site = try makeSite(inferredTitle: "Vite App")
        let viewModel = makeViewModel(site: site)

        await viewModel.refresh()
        let presentation = try XCTUnwrap(viewModel.visibleSitePresentations.first)

        XCTAssertFalse(viewModel.canResetTitleOverride(for: presentation))

        viewModel.setTitleOverride(for: presentation, title: "Dashboard")
        XCTAssertTrue(viewModel.canResetTitleOverride(for: presentation))

        viewModel.setTitleOverride(for: presentation, title: " Vite App ")
        XCTAssertFalse(viewModel.canResetTitleOverride(for: presentation))

        viewModel.setTitleOverride(for: presentation, title: "Dashboard")
        viewModel.resetTitleOverride(for: presentation)
        XCTAssertFalse(viewModel.canResetTitleOverride(for: presentation))
    }

    func testCopyURLShowsLightweightFeedbackThenClears() async throws {
        let site = try makeSite()
        let viewModel = makeViewModel(
            site: site,
            copyFeedbackDurationNanoseconds: 0
        )

        await viewModel.refresh()
        let presentation = try XCTUnwrap(viewModel.visibleSitePresentations.first)

        viewModel.copyURL(presentation)

        XCTAssertEqual(NSPasteboard.general.string(forType: .string), presentation.urlText)
        XCTAssertTrue(viewModel.isURLCopyFeedbackVisible(for: presentation))

        await waitUntilCopyFeedbackClears(for: presentation, in: viewModel)
        XCTAssertFalse(viewModel.isURLCopyFeedbackVisible(for: presentation))
    }

    private func makeViewModel(
        site: LocalhostSite,
        copyFeedbackDurationNanoseconds: UInt64 = 1_500_000_000
    ) -> SitesViewModel {
        SitesViewModel(
            scanner: SequenceScanner(results: [[site]]),
            preferencesStore: PreferencesStore(fileURL: temporaryPreferencesURL()),
            copyFeedbackDurationNanoseconds: copyFeedbackDurationNanoseconds,
            startsRefreshLoop: false
        )
    }

    private func temporaryPreferencesURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("Sites.json")
    }

    private func makeSite(
        port: Int = 5173,
        processName: String? = "node",
        pid: Int? = 123,
        inferredTitle: String? = "Vite App"
    ) throws -> LocalhostSite {
        let url = try XCTUnwrap(URL(string: "http://localhost:\(port)"))
        return LocalhostSite(
            url: url,
            port: port,
            processName: processName,
            pid: pid,
            inferredTitle: inferredTitle,
            httpStatusCode: 200,
            detectedAt: Date(timeIntervalSinceReferenceDate: 1)
        )
    }

    private func waitUntilCopyFeedbackClears(
        for presentation: SitePresentation,
        in viewModel: SitesViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 {
            if !viewModel.isURLCopyFeedbackVisible(for: presentation) {
                return
            }

            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTFail("Timed out waiting for copy feedback to clear", file: file, line: line)
    }
}

private actor SequenceScanner: LocalhostScanning {
    private let results: [[LocalhostSite]]
    private var scans = 0

    init(results: [[LocalhostSite]]) {
        self.results = results
    }

    func scan() async -> [LocalhostSite] {
        let result = results[min(scans, results.count - 1)]
        scans += 1
        return result
    }
}
