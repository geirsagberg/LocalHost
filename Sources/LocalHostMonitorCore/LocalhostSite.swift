import Foundation

public struct LocalhostSite: Identifiable, Equatable, Sendable {
    public let id: String
    public let preferenceKey: String
    public let url: URL
    public let port: Int
    public let processName: String?
    public let pid: Int?
    public let inferredTitle: String?
    public let httpStatusCode: Int
    public let detectedAt: Date

    public init(
        url: URL,
        port: Int,
        processName: String?,
        pid: Int?,
        inferredTitle: String?,
        httpStatusCode: Int,
        detectedAt: Date = Date()
    ) {
        self.url = url
        self.port = port
        self.processName = processName
        self.pid = pid
        self.inferredTitle = inferredTitle
        self.httpStatusCode = httpStatusCode
        self.detectedAt = detectedAt
        self.id = url.absoluteString
        self.preferenceKey = url.absoluteString
    }

    public var isOK: Bool {
        httpStatusCode == 200
    }

    public var fallbackTitle: String {
        if let host = url.host(percentEncoded: false) {
            return "\(host):\(port)"
        }

        return "localhost:\(port)"
    }

    public var displayURLString: String {
        url.absoluteString
    }
}
