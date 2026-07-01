import AppKit
import Foundation
import LocalHostMonitorCore

@MainActor
final class SitesViewModel: ObservableObject {
    @Published private(set) var sites: [LocalhostSite] = []
    @Published var includesHiddenSites = false
    @Published var includesNonOKSites = false
    @Published var alertMessage: UserAlertMessage?
    @Published private(set) var overrides: [String: SiteOverride] = [:] {
        didSet {
            preferencesStore.save(overrides)
        }
    }
    @Published private(set) var isScanning = false
    @Published private(set) var lastScanDate: Date?
    @Published private(set) var killingPorts: Set<Int> = []

    private let scanner: LocalhostScanner
    private let processTerminator: PortProcessTerminator
    private let preferencesStore: PreferencesStore
    private var refreshLoop: Task<Void, Never>?

    init(
        scanner: LocalhostScanner = LocalhostScanner(),
        processTerminator: PortProcessTerminator = PortProcessTerminator(),
        preferencesStore: PreferencesStore = PreferencesStore()
    ) {
        self.scanner = scanner
        self.processTerminator = processTerminator
        self.preferencesStore = preferencesStore
        self.overrides = preferencesStore.load()

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
            filter: defaultViewFilter
        )
    }

    var filteredSiteCount: Int {
        sites.count - visibleSitePresentations.count
    }

    var siteCountText: String {
        DefaultViewSummary(
            shownCount: visibleSitePresentations.count,
            totalCount: sites.count
        ).countText
    }

    var emptyStateTitle: String {
        if isLoadingInitialSites {
            return "Loading localhost sites"
        }

        if sites.isEmpty {
            return "No localhost sites"
        }

        return "No localhost sites visible"
    }

    var emptyStateMessage: String? {
        guard !isLoadingInitialSites, !sites.isEmpty else {
            return nil
        }

        if !includesHiddenSites && !includesNonOKSites {
            return "The default view is hiding explicitly hidden sites and non-OK localhost sites."
        }

        if !includesHiddenSites {
            return "The default view is hiding explicitly hidden localhost sites."
        }

        if !includesNonOKSites {
            return "The default view is hiding non-OK localhost sites."
        }

        return nil
    }

    var emptyStateRecoveryActions: [DefaultViewRecoveryAction] {
        guard !isLoadingInitialSites, !sites.isEmpty else {
            return []
        }

        let presentations = allSitePresentations
        var actions: [DefaultViewRecoveryAction] = []

        if !includesHiddenSites, presentations.contains(where: \.isHidden) {
            actions.append(.showHidden)
        }

        if !includesNonOKSites, presentations.contains(where: { !$0.site.isOK }) {
            actions.append(.showNonOK)
        }

        return actions
    }

    var isLoadingInitialSites: Bool {
        isScanning && lastScanDate == nil
    }

    private var allSitePresentations: [SitePresentation] {
        SitePresentation.presentations(for: sites, overrides: overrides)
    }

    private var defaultViewFilter: DefaultViewFilter {
        DefaultViewFilter(
            includesHiddenSites: includesHiddenSites,
            includesNonOKSites: includesNonOKSites
        )
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

    func killProcess(for presentation: SitePresentation) {
        let site = presentation.site
        guard !killingPorts.contains(site.port) else {
            return
        }

        let siteTitle = title(for: presentation)
        killingPorts.insert(site.port)
        sites.removeAll { $0.id == site.id }

        Task {
            do {
                _ = try await processTerminator.terminateProcessListening(on: site.port)
                killingPorts.remove(site.port)
                try? await Task.sleep(nanoseconds: 350_000_000)
                await refresh()
            } catch PortProcessTerminationError.administratorPromptCancelled {
                killingPorts.remove(site.port)
                await refresh()
            } catch {
                killingPorts.remove(site.port)
                alertMessage = UserAlertMessage(
                    title: "Couldn't kill \(siteTitle)",
                    message: error.localizedDescription
                )
                await refresh()
            }
        }
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

enum DefaultViewRecoveryAction: String, Identifiable {
    case showHidden
    case showNonOK

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .showHidden:
            return "Show hidden"
        case .showNonOK:
            return "Show non-OK"
        }
    }
}
