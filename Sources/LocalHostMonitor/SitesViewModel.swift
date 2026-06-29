import AppKit
import Foundation
import LocalHostMonitorCore

@MainActor
final class SitesViewModel: ObservableObject {
    @Published private(set) var sites: [LocalhostSite] = []
    @Published var showsAllResponses = false
    @Published private(set) var overrides: [String: SiteOverride] = [:] {
        didSet {
            preferencesStore.save(overrides)
        }
    }
    @Published private(set) var isScanning = false
    @Published private(set) var lastScanDate: Date?

    private let scanner: LocalhostScanner
    private let preferencesStore: PreferencesStore
    private var refreshLoop: Task<Void, Never>?

    init(
        scanner: LocalhostScanner = LocalhostScanner(),
        preferencesStore: PreferencesStore = PreferencesStore()
    ) {
        self.scanner = scanner
        self.preferencesStore = preferencesStore
        self.overrides = preferencesStore.load()

        refreshLoop = Task { [weak self] in
            await self?.refresh()

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                await self?.refresh()
            }
        }
    }

    deinit {
        refreshLoop?.cancel()
    }

    var visibleSites: [LocalhostSite] {
        showsAllResponses ? sites : sites.filter(\.isOK)
    }

    var hiddenResponseCount: Int {
        sites.count - visibleSites.count
    }

    var siteCountText: String {
        if hiddenResponseCount > 0 {
            return "\(visibleSites.count)/\(sites.count)"
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

    func site(withID id: LocalhostSite.ID) -> LocalhostSite? {
        sites.first { $0.id == id }
    }

    func title(for site: LocalhostSite) -> String {
        if let override = overrides[site.preferenceKey]?.title?.trimmedForDisplay,
           !override.isEmpty {
            return override
        }

        if let inferredTitle = site.inferredTitle?.trimmedForDisplay,
           !inferredTitle.isEmpty {
            return inferredTitle
        }

        return site.fallbackTitle
    }

    func setTitleOverride(for site: LocalhostSite, title rawTitle: String) {
        let trimmedTitle = rawTitle.trimmedForDisplay
        let inferredTitle = site.inferredTitle?.trimmedForDisplay ?? ""

        updateOverride(for: site.preferenceKey) { override in
            if trimmedTitle.isEmpty
                || trimmedTitle == inferredTitle
                || trimmedTitle == site.fallbackTitle {
                override.title = nil
            } else {
                override.title = trimmedTitle
            }
        }
    }

    func resetTitleOverride(for site: LocalhostSite) {
        updateOverride(for: site.preferenceKey) { override in
            override.title = nil
        }
    }

    func emoji(for site: LocalhostSite) -> String? {
        switch overrides[site.preferenceKey]?.emoji ?? .automatic {
        case .automatic:
            return EmojiAssigner.emoji(for: site.preferenceKey)
        case .cleared:
            return nil
        case .custom(let value):
            let trimmedValue = value.trimmedForDisplay
            return trimmedValue.isEmpty ? nil : String(trimmedValue.prefix(1))
        }
    }

    func emojiFieldText(for site: LocalhostSite) -> String {
        emoji(for: site) ?? ""
    }

    func setEmojiFieldText(for site: LocalhostSite, value rawValue: String) {
        let trimmedValue = rawValue.trimmedForDisplay

        updateOverride(for: site.preferenceKey) { override in
            if trimmedValue.isEmpty {
                override.emoji = .cleared
            } else {
                override.emoji = .custom(String(trimmedValue.prefix(1)))
            }
        }
    }

    func clearEmoji(for site: LocalhostSite) {
        updateOverride(for: site.preferenceKey) { override in
            override.emoji = .cleared
        }
    }

    func resetEmoji(for site: LocalhostSite) {
        updateOverride(for: site.preferenceKey) { override in
            override.emoji = .automatic
        }
    }

    func open(_ site: LocalhostSite) {
        NSWorkspace.shared.open(site.url)
    }

    func copyURL(_ site: LocalhostSite) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(site.displayURLString, forType: .string)
    }

    func menuTitle(for site: LocalhostSite) -> String {
        let title = title(for: site)
        let statusSuffix = site.isOK ? "" : " HTTP \(site.httpStatusCode)"

        if let emoji = emoji(for: site), !emoji.isEmpty {
            return "\(emoji) \(title) :\(site.port)\(statusSuffix)"
        }

        return "\(title) :\(site.port)\(statusSuffix)"
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

private extension String {
    var trimmedForDisplay: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
