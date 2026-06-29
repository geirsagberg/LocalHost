import Foundation

public enum PortScanner {
    private static let tcpListenExpression = try! NSRegularExpression(
        pattern: #"TCP\s+(.+):(\d+)\s+\(LISTEN\)"#,
        options: [.caseInsensitive]
    )

    public static func currentListeningEndpoints() async throws -> [ListeningEndpoint] {
        try await Task.detached(priority: .utility) {
            try runLsof()
        }.value
    }

    public static func parseLsofOutput(_ output: String) -> [ListeningEndpoint] {
        var endpointsByPort: [Int: ListeningEndpoint] = [:]

        for lineSubstring in output.split(separator: "\n") {
            let line = String(lineSubstring)
            guard line.localizedCaseInsensitiveContains("TCP"),
                  line.localizedCaseInsensitiveContains("(LISTEN)") else {
                continue
            }

            let nsLine = line as NSString
            let range = NSRange(location: 0, length: nsLine.length)
            guard let match = tcpListenExpression.firstMatch(in: line, range: range),
                  match.numberOfRanges >= 3 else {
                continue
            }

            let rawHost = nsLine.substring(with: match.range(at: 1))
            let portString = nsLine.substring(with: match.range(at: 2))
            guard let port = Int(portString),
                  isLocalBindableHost(rawHost) else {
                continue
            }

            let fields = line.split(whereSeparator: { $0.isWhitespace })
            let processName = fields.first.map(String.init)
            let pid = fields.dropFirst().first.flatMap { Int($0) }
            let endpoint = ListeningEndpoint(
                host: normalizedHost(rawHost),
                port: port,
                pid: pid,
                processName: processName
            )

            if shouldReplace(existing: endpointsByPort[port], with: endpoint) {
                endpointsByPort[port] = endpoint
            }
        }

        return endpointsByPort.values.sorted { lhs, rhs in
            if lhs.port == rhs.port {
                return (lhs.processName ?? "") < (rhs.processName ?? "")
            }

            return lhs.port < rhs.port
        }
    }

    private static func runLsof() throws -> [ListeningEndpoint] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-nP", "-iTCP", "-sTCP:LISTEN"]

        let standardOutput = Pipe()
        let standardError = Pipe()
        process.standardOutput = standardOutput
        process.standardError = standardError

        try process.run()
        process.waitUntilExit()

        let data = standardOutput.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }

        return parseLsofOutput(output)
    }

    private static func shouldReplace(existing: ListeningEndpoint?, with candidate: ListeningEndpoint) -> Bool {
        guard let existing else {
            return true
        }

        return hostPreferenceScore(candidate.host) > hostPreferenceScore(existing.host)
    }

    private static func hostPreferenceScore(_ host: String) -> Int {
        switch host.lowercased() {
        case "localhost", "127.0.0.1", "::1":
            return 3
        case "0.0.0.0", "::", "*":
            return 2
        default:
            return 1
        }
    }

    private static func isLocalBindableHost(_ host: String) -> Bool {
        let normalized = normalizedHost(host).lowercased()
        return normalized == "*"
            || normalized == "localhost"
            || normalized == "0.0.0.0"
            || normalized == "::"
            || normalized == "::1"
            || normalized.hasPrefix("127.")
    }

    private static func normalizedHost(_ host: String) -> String {
        host
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
    }
}
