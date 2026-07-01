import AppKit
import Foundation
import LocalHostMonitorCore

@MainActor
final class SitesViewModel: ObservableObject {
    @Published private(set) var sites: [LocalhostSite] = []
    @Published var showsAllResponses = false
    @Published var alertMessage: UserAlertMessage?
    @Published private(set) var overrides: [String: SiteOverride] = [:] {
        didSet {
            preferencesStore.save(overrides)
        }
    }
    @Published private(set) var isScanning = false
    @Published private(set) var lastScanDate: Date?
    @Published private(set) var killingPorts: Set<Int> = []

    private let scanner: LocalhostScanning
    private let processTerminator: ProcessTerminating
    private let processTerminationConfirmer: ProcessTerminationConfirming
    private let preferencesStore: PreferencesStore
    private let postTerminationRefreshDelayNanoseconds: UInt64
    private var refreshLoop: Task<Void, Never>?
    private var confirmingPorts: Set<Int> = []

    init(
        scanner: LocalhostScanning = LocalhostScanner(),
        processTerminator: ProcessTerminating = PortProcessTerminator(),
        processTerminationConfirmer: ProcessTerminationConfirming = NativeProcessTerminationConfirmer(),
        preferencesStore: PreferencesStore = PreferencesStore(),
        postTerminationRefreshDelayNanoseconds: UInt64 = 350_000_000,
        startsRefreshLoop: Bool = true
    ) {
        self.scanner = scanner
        self.processTerminator = processTerminator
        self.processTerminationConfirmer = processTerminationConfirmer
        self.preferencesStore = preferencesStore
        self.postTerminationRefreshDelayNanoseconds = postTerminationRefreshDelayNanoseconds
        self.overrides = preferencesStore.load()

        guard startsRefreshLoop else {
            return
        }

        refreshLoop = Task { [weak self] in
            await self?.refresh()

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                await self?.refresh()
            }
        }
    }

    deinit {
        refreshLoop?.cancel()
    }

    var visibleSitePresentations: [SitePresentation] {
        SitePresentation.visiblePresentations(
            for: sites,
            overrides: overrides,
            showsAllResponses: showsAllResponses
        )
    }

    var filteredSiteCount: Int {
        sites.count - visibleSitePresentations.count
    }

    var siteCountText: String {
        if filteredSiteCount > 0 {
            return "\(visibleSitePresentations.count)/\(sites.count)"
        }

        return "\(sites.count)"
    }

    func refresh() async {
        guard !isScanning else {
            return
        }

        isScanning = true
        let scannedSites = await scanner.scan()
        sites = scannedSites
        lastScanDate = Date()
        isScanning = false
    }

    private func presentation(for site: LocalhostSite) -> SitePresentation {
        SitePresentation(site: site, override: overrides[site.preferenceKey])
    }

    private func currentPresentation(for presentation: SitePresentation) -> SitePresentation {
        self.presentation(for: presentation.site)
    }

    func title(for presentation: SitePresentation) -> String {
        currentPresentation(for: presentation).title
    }

    func setTitleOverride(for presentation: SitePresentation, title rawTitle: String) {
        let site = presentation.site
        updateOverride(for: site.preferenceKey) { override in
            override.title = SitePresentation.titleOverrideValue(for: site, rawTitle: rawTitle)
        }
    }

    func resetTitleOverride(for presentation: SitePresentation) {
        updateOverride(for: presentation.site.preferenceKey) { override in
            override.title = nil
        }
    }

    func emojiFieldText(for presentation: SitePresentation) -> String {
        currentPresentation(for: presentation).emoji ?? ""
    }

    func setEmojiFieldText(for presentation: SitePresentation, value rawValue: String) {
        updateOverride(for: presentation.site.preferenceKey) { override in
            override.emoji = SitePresentation.emojiPreference(for: rawValue)
        }
    }

    func isHidden(_ presentation: SitePresentation) -> Bool {
        currentPresentation(for: presentation).isHidden
    }

    func setHidden(_ isHidden: Bool, for presentation: SitePresentation) {
        updateOverride(for: presentation.site.preferenceKey) { override in
            override.isHidden = isHidden
        }
    }

    func open(_ presentation: SitePresentation) {
        NSWorkspace.shared.open(presentation.site.url)
    }

    func copyURL(_ presentation: SitePresentation) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(presentation.urlText, forType: .string)
    }

    func isKilling(_ presentation: SitePresentation) -> Bool {
        killingPorts.contains(presentation.site.port)
    }

    func killProcess(for presentation: SitePresentation) async {
        let site = presentation.site
        guard !confirmingPorts.contains(site.port), !killingPorts.contains(site.port) else {
            return
        }

        confirmingPorts.insert(site.port)
        let confirmationDetails = ProcessTerminationConfirmationDetails(
            presentation: currentPresentation(for: presentation)
        )
        let isConfirmed = await processTerminationConfirmer.confirmProcessTermination(
            details: confirmationDetails
        )
        confirmingPorts.remove(site.port)

        guard isConfirmed, !killingPorts.contains(site.port) else {
            return
        }

        killingPorts.insert(site.port)

        do {
            _ = try await processTerminator.terminateProcessListening(on: site.port)
            try? await Task.sleep(nanoseconds: postTerminationRefreshDelayNanoseconds)
            await refresh()
        } catch PortProcessTerminationError.administratorPromptCancelled {
            alertMessage = UserAlertMessage(
                title: "Kill process cancelled",
                message: "Administrator authorization was cancelled. \(confirmationDetails.title) was not killed."
            )
        } catch {
            alertMessage = UserAlertMessage(
                title: "Couldn't kill \(confirmationDetails.title)",
                message: "\(error.localizedDescription)\n\nRefresh to scan the current localhost sites."
            )
        }

        killingPorts.remove(site.port)
    }

    private func updateOverride(for key: String, mutate: (inout SiteOverride) -> Void) {
        var override = overrides[key] ?? SiteOverride()
        mutate(&override)

        if override.isEmpty {
            overrides.removeValue(forKey: key)
        } else {
            overrides[key] = override
        }
    }
}

struct UserAlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

protocol LocalhostScanning {
    func scan() async -> [LocalhostSite]
}

extension LocalhostScanner: LocalhostScanning {}

protocol ProcessTerminating {
    func terminateProcessListening(on port: Int) async throws -> [Int]
}

extension PortProcessTerminator: ProcessTerminating {}

struct ProcessTerminationConfirmationDetails: Equatable, Sendable {
    let title: String
    let urlText: String
    let processName: String?
    let pid: Int?
    let port: Int

    init(title: String, urlText: String, processName: String?, pid: Int?, port: Int) {
        self.title = title
        self.urlText = urlText
        self.processName = processName
        self.pid = pid
        self.port = port
    }

    init(presentation: SitePresentation) {
        self.title = presentation.title
        self.urlText = presentation.urlText
        self.processName = presentation.processName
        self.pid = presentation.site.pid
        self.port = presentation.site.port
    }
}

protocol ProcessTerminationConfirming {
    @MainActor
    func confirmProcessTermination(details: ProcessTerminationConfirmationDetails) async -> Bool
}

struct NativeProcessTerminationConfirmer: ProcessTerminationConfirming {
    @MainActor
    func confirmProcessTermination(details: ProcessTerminationConfirmationDetails) async -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Kill process for \(details.title)?"
        alert.informativeText = informativeText(for: details)
        alert.addButton(withTitle: "Kill Process")
        alert.addButton(withTitle: "Cancel")

        return alert.runModal() == .alertFirstButtonReturn
    }

    private func informativeText(for details: ProcessTerminationConfirmationDetails) -> String {
        var facts = [
            "URL: \(details.urlText)"
        ]

        if let processName = details.processName {
            facts.append("Process: \(processName)")
        }

        if let pid = details.pid {
            facts.append("PID: \(pid)")
        }

        facts.append("Port: \(details.port)")
        facts.append("")
        facts.append("This will send TERM to the process listening on this port.")

        return facts.joined(separator: "\n")
    }
}
