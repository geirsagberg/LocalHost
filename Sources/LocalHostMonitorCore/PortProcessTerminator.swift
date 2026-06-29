import Foundation

public enum PortProcessTerminationError: Error, LocalizedError, Sendable {
    case invalidPort(Int)
    case noListeningProcess(port: Int)
    case administratorPromptCancelled
    case commandFailed(command: String, status: Int32, message: String)

    public var errorDescription: String? {
        switch self {
        case .invalidPort(let port):
            return "Port \(port) is not valid."
        case .noListeningProcess(let port):
            return "No process is currently listening on port \(port)."
        case .administratorPromptCancelled:
            return "Administrator authorization was cancelled."
        case .commandFailed(let command, let status, let message):
            let details = message.trimmingCharacters(in: .whitespacesAndNewlines)
            if details.isEmpty {
                return "\(command) failed with status \(status)."
            }

            return "\(command) failed with status \(status): \(details)"
        }
    }

    var canRetryWithAdministratorPrivileges: Bool {
        switch self {
        case .commandFailed(_, _, let message):
            let lowercasedMessage = message.lowercased()
            return lowercasedMessage.contains("operation not permitted")
                || lowercasedMessage.contains("permission denied")
                || lowercasedMessage.contains("not permitted")
        case .invalidPort, .noListeningProcess, .administratorPromptCancelled:
            return false
        }
    }
}

public struct PortProcessTerminator: Sendable {
    public init() {}

    public func terminateProcessListening(on port: Int) async throws -> [Int] {
        try Self.validate(port: port)

        return try await Task.detached(priority: .userInitiated) {
            let pids: [Int]

            do {
                pids = try Self.listeningPIDs(on: port)
            } catch let error as PortProcessTerminationError where error.canRetryWithAdministratorPrivileges {
                return try Self.terminateWithAdministratorPrivileges(port: port, knownPIDs: [])
            }

            if pids.isEmpty {
                throw PortProcessTerminationError.noListeningProcess(port: port)
            }

            do {
                try Self.terminate(pids: pids)
                return pids
            } catch let error as PortProcessTerminationError where error.canRetryWithAdministratorPrivileges {
                return try Self.terminateWithAdministratorPrivileges(port: port, knownPIDs: pids)
            }
        }.value
    }

    static func parsePIDs(from output: String) -> [Int] {
        var seenPIDs: Set<Int> = []

        return output
            .split(whereSeparator: { $0.isWhitespace })
            .compactMap { Int($0) }
            .filter { pid in
                guard pid > 0, !seenPIDs.contains(pid) else {
                    return false
                }

                seenPIDs.insert(pid)
                return true
            }
    }

    private static func validate(port: Int) throws {
        guard (1...65_535).contains(port) else {
            throw PortProcessTerminationError.invalidPort(port)
        }
    }

    private static func listeningPIDs(on port: Int) throws -> [Int] {
        let result = try runProcess(
            executablePath: "/usr/sbin/lsof",
            arguments: ["-nP", "-tiTCP:\(port)", "-sTCP:LISTEN"]
        )
        let pids = parsePIDs(from: result.standardOutput)

        if pids.isEmpty && result.status != 0 {
            let message = result.combinedOutput
            if message.lowercased().contains("permission") || message.lowercased().contains("not permitted") {
                throw PortProcessTerminationError.commandFailed(
                    command: "lsof",
                    status: result.status,
                    message: message
                )
            }
        }

        return pids
    }

    private static func terminate(pids: [Int]) throws {
        guard !pids.isEmpty else {
            return
        }

        let result = try runProcess(
            executablePath: "/bin/kill",
            arguments: ["-TERM"] + pids.map(String.init)
        )

        guard result.status == 0 else {
            throw PortProcessTerminationError.commandFailed(
                command: "kill",
                status: result.status,
                message: result.combinedOutput
            )
        }
    }

    private static func terminateWithAdministratorPrivileges(port: Int, knownPIDs: [Int]) throws -> [Int] {
        let shellCommand: String

        if knownPIDs.isEmpty {
            shellCommand = "pids=$(/usr/sbin/lsof -nP -tiTCP:\(port) -sTCP:LISTEN); if [ -z \"$pids\" ]; then exit 66; fi; /bin/kill -TERM $pids; printf '%s\\n' $pids"
        } else {
            let pidList = knownPIDs.map(String.init).joined(separator: " ")
            shellCommand = "/bin/kill -TERM \(pidList); printf '%s\\n' \(pidList)"
        }

        let script = "do shell script \(appleScriptStringLiteral(shellCommand)) with administrator privileges"
        let result = try runProcess(
            executablePath: "/usr/bin/osascript",
            arguments: ["-e", script]
        )

        if result.status != 0 {
            if result.combinedOutput.contains("User canceled") || result.combinedOutput.contains("-128") {
                throw PortProcessTerminationError.administratorPromptCancelled
            }

            if result.combinedOutput.contains("66") {
                throw PortProcessTerminationError.noListeningProcess(port: port)
            }

            throw PortProcessTerminationError.commandFailed(
                command: "administrator kill",
                status: result.status,
                message: result.combinedOutput
            )
        }

        let terminatedPIDs = parsePIDs(from: result.standardOutput)
        return terminatedPIDs.isEmpty ? knownPIDs : terminatedPIDs
    }

    private static func runProcess(executablePath: String, arguments: [String]) throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let standardOutput = Pipe()
        let standardError = Pipe()
        process.standardOutput = standardOutput
        process.standardError = standardError

        try process.run()
        process.waitUntilExit()

        let outputData = standardOutput.fileHandleForReading.readDataToEndOfFile()
        let errorData = standardError.fileHandleForReading.readDataToEndOfFile()

        return CommandResult(
            status: process.terminationStatus,
            standardOutput: String(data: outputData, encoding: .utf8) ?? "",
            standardError: String(data: errorData, encoding: .utf8) ?? ""
        )
    }

    private static func appleScriptStringLiteral(_ value: String) -> String {
        let escapedValue = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        return "\"\(escapedValue)\""
    }
}

private struct CommandResult: Sendable {
    let status: Int32
    let standardOutput: String
    let standardError: String

    var combinedOutput: String {
        [standardOutput, standardError]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
