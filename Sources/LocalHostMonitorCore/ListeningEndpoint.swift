import Foundation

public struct ListeningEndpoint: Hashable, Sendable {
    public let host: String
    public let port: Int
    public let pid: Int?
    public let processName: String?

    public init(host: String, port: Int, pid: Int?, processName: String?) {
        self.host = host
        self.port = port
        self.pid = pid
        self.processName = processName
    }
}
