import XCTest
@testable import LocalHostMonitor
import LocalHostMonitorCore

@MainActor
final class SitesViewModelTerminationTests: XCTestCase {
    func testKillProcessConfirmationIncludesLocalhostSiteAndProcessFacts() async throws {
        let site = try makeSite()
        let scanner = SequenceScanner(results: [[site], []])
        let terminator = RecordingTerminator(result: .success([123]))
        let confirmer = RecordingConfirmer(results: [true])
        let viewModel = makeViewModel(
            scanner: scanner,
            terminator: terminator,
            confirmer: confirmer
        )

        await viewModel.refresh()
        let presentation = try XCTUnwrap(viewModel.visibleSitePresentations.first)

        await viewModel.killProcess(for: presentation)

        XCTAssertEqual(confirmer.confirmedDetails, [
            ProcessTerminationConfirmationDetails(
                title: "Vite App",
                urlText: "http://localhost:5173",
                processName: "node",
                pid: 123,
                port: 5173
            )
        ])
        let requestedPorts = await terminator.requestedPorts()
        let scanCount = await scanner.scanCount()
        XCTAssertEqual(requestedPorts, [5173])
        XCTAssertEqual(scanCount, 2)
        XCTAssertTrue(viewModel.sites.isEmpty)
    }

    func testCancellingConfirmationLeavesLocalhostSiteUnchanged() async throws {
        let site = try makeSite()
        let scanner = SequenceScanner(results: [[site]])
        let terminator = RecordingTerminator(result: .failure(UnexpectedTerminationError()))
        let confirmer = RecordingConfirmer(results: [false])
        let viewModel = makeViewModel(
            scanner: scanner,
            terminator: terminator,
            confirmer: confirmer
        )

        await viewModel.refresh()
        let presentation = try XCTUnwrap(viewModel.visibleSitePresentations.first)

        await viewModel.killProcess(for: presentation)

        XCTAssertEqual(viewModel.sites, [site])
        XCTAssertFalse(viewModel.isKilling(presentation))
        XCTAssertNil(viewModel.alertMessage)
        let requestedPorts = await terminator.requestedPorts()
        let scanCount = await scanner.scanCount()
        XCTAssertEqual(requestedPorts, [])
        XCTAssertEqual(scanCount, 1)
    }

    func testConfirmedKillKeepsLocalhostSiteVisibleWhileTerminationRunsThenRefreshesAfterSuccess() async throws {
        let site = try makeSite()
        let scanner = SequenceScanner(results: [[site], []])
        let terminator = BlockingTerminator()
        let confirmer = RecordingConfirmer(results: [true])
        let viewModel = makeViewModel(
            scanner: scanner,
            terminator: terminator,
            confirmer: confirmer
        )

        await viewModel.refresh()
        let presentation = try XCTUnwrap(viewModel.visibleSitePresentations.first)

        let killTask = Task {
            await viewModel.killProcess(for: presentation)
        }
        await waitUntilTerminatorStarts(terminator)

        XCTAssertEqual(viewModel.sites, [site])
        XCTAssertEqual(viewModel.visibleSitePresentations.map(\.id), [site.id])
        XCTAssertTrue(viewModel.isKilling(presentation))

        await terminator.succeed(with: [123])
        await killTask.value

        XCTAssertFalse(viewModel.isKilling(presentation))
        XCTAssertTrue(viewModel.sites.isEmpty)
        let scanCount = await scanner.scanCount()
        XCTAssertEqual(scanCount, 2)
    }

    func testFailedKillKeepsLocalhostSiteVisibleAndShowsRecoveryAlert() async throws {
        let site = try makeSite()
        let scanner = SequenceScanner(results: [[site]])
        let terminator = RecordingTerminator(
            result: .failure(
                PortProcessTerminationError.commandFailed(
                    command: "kill",
                    status: 1,
                    message: "Operation not permitted"
                )
            )
        )
        let confirmer = RecordingConfirmer(results: [true])
        let viewModel = makeViewModel(
            scanner: scanner,
            terminator: terminator,
            confirmer: confirmer
        )

        await viewModel.refresh()
        let presentation = try XCTUnwrap(viewModel.visibleSitePresentations.first)

        await viewModel.killProcess(for: presentation)

        XCTAssertEqual(viewModel.sites, [site])
        XCTAssertFalse(viewModel.isKilling(presentation))
        XCTAssertEqual(viewModel.alertMessage?.title, "Couldn't kill Vite App")
        XCTAssertTrue(viewModel.alertMessage?.message.contains("Operation not permitted") == true)
        XCTAssertTrue(viewModel.alertMessage?.message.contains("Refresh") == true)
        let scanCount = await scanner.scanCount()
        XCTAssertEqual(scanCount, 1)
    }

    func testAdministratorCancelledKillKeepsLocalhostSiteVisibleAndShowsCancellationAlert() async throws {
        let site = try makeSite()
        let scanner = SequenceScanner(results: [[site]])
        let terminator = RecordingTerminator(
            result: .failure(PortProcessTerminationError.administratorPromptCancelled)
        )
        let confirmer = RecordingConfirmer(results: [true])
        let viewModel = makeViewModel(
            scanner: scanner,
            terminator: terminator,
            confirmer: confirmer
        )

        await viewModel.refresh()
        let presentation = try XCTUnwrap(viewModel.visibleSitePresentations.first)

        await viewModel.killProcess(for: presentation)

        XCTAssertEqual(viewModel.sites, [site])
        XCTAssertFalse(viewModel.isKilling(presentation))
        XCTAssertEqual(viewModel.alertMessage?.title, "Kill process cancelled")
        XCTAssertTrue(viewModel.alertMessage?.message.contains("was not killed") == true)
        let scanCount = await scanner.scanCount()
        XCTAssertEqual(scanCount, 1)
    }

    private func makeViewModel(
        scanner: LocalhostScanning,
        terminator: ProcessTerminating,
        confirmer: ProcessTerminationConfirming
    ) -> SitesViewModel {
        SitesViewModel(
            scanner: scanner,
            processTerminator: terminator,
            processTerminationConfirmer: confirmer,
            preferencesStore: PreferencesStore(fileURL: temporaryPreferencesURL()),
            postTerminationRefreshDelayNanoseconds: 0,
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

    private func waitUntilTerminatorStarts(
        _ terminator: BlockingTerminator,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 {
            if await terminator.hasStarted {
                return
            }

            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTFail("Timed out waiting for termination to start", file: file, line: line)
    }
}

private final class RecordingConfirmer: ProcessTerminationConfirming {
    private var results: [Bool]
    private(set) var confirmedDetails: [ProcessTerminationConfirmationDetails] = []

    init(results: [Bool]) {
        self.results = results
    }

    @MainActor
    func confirmProcessTermination(details: ProcessTerminationConfirmationDetails) async -> Bool {
        confirmedDetails.append(details)
        return results.isEmpty ? false : results.removeFirst()
    }
}

private actor SequenceScanner: LocalhostScanning {
    private let results: [[LocalhostSite]]
    private var scans = 0

    init(results: [[LocalhostSite]]) {
        self.results = results
    }

    func scanCount() -> Int {
        scans
    }

    func scan() async -> [LocalhostSite] {
        let result = results[min(scans, results.count - 1)]
        scans += 1
        return result
    }
}

private actor RecordingTerminator: ProcessTerminating {
    private let result: Result<[Int], Error>
    private var ports: [Int] = []

    init(result: Result<[Int], Error>) {
        self.result = result
    }

    func requestedPorts() -> [Int] {
        ports
    }

    func terminateProcessListening(on port: Int) async throws -> [Int] {
        ports.append(port)
        return try result.get()
    }
}

private actor BlockingTerminator: ProcessTerminating {
    private var continuation: CheckedContinuation<[Int], Error>?

    var hasStarted: Bool {
        continuation != nil
    }

    func terminateProcessListening(on port: Int) async throws -> [Int] {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func succeed(with pids: [Int]) {
        continuation?.resume(returning: pids)
        continuation = nil
    }
}

private struct UnexpectedTerminationError: Error {}
