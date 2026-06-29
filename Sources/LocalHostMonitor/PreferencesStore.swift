import Foundation
import LocalHostMonitorCore

final class PreferencesStore {
    private let fileURL: URL
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let directoryURL = baseURL.appendingPathComponent("LocalHostMonitor", isDirectory: true)
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        self.fileURL = directoryURL.appendingPathComponent("Sites.json")
    }

    func load() -> [String: SiteOverride] {
        guard let data = try? Data(contentsOf: fileURL) else {
            return [:]
        }

        do {
            return try JSONDecoder().decode([String: SiteOverride].self, from: data)
        } catch {
            return [:]
        }
    }

    func save(_ overrides: [String: SiteOverride]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(overrides)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Preferences should never stop the monitor from working.
        }
    }
}
