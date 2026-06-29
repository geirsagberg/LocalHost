import Foundation

public struct SiteMetadata: Equatable, Sendable {
    public let url: URL
    public let inferredTitle: String?
    public let statusCode: Int

    public init(url: URL, inferredTitle: String?, statusCode: Int) {
        self.url = url
        self.inferredTitle = inferredTitle
        self.statusCode = statusCode
    }
}

public struct WebMetadataFetcher: Sendable {
    public var timeout: TimeInterval

    public init(timeout: TimeInterval = 1.2) {
        self.timeout = timeout
    }

    public func fetchMetadata(for endpoint: ListeningEndpoint) async -> SiteMetadata? {
        var responses: [SiteMetadata] = []

        for scheme in ["http", "https"] {
            for probeHost in probeHosts(for: endpoint) {
                if let metadata = await fetchMetadata(
                    scheme: scheme,
                    probeHost: probeHost,
                    port: endpoint.port
                ) {
                    responses.append(metadata)
                }
            }
        }

        return Self.preferredMetadata(from: responses)
    }

    static func preferredMetadata(from responses: [SiteMetadata]) -> SiteMetadata? {
        responses.min { lhs, rhs in
            statusPreference(lhs.statusCode) < statusPreference(rhs.statusCode)
        }
    }

    public static func extractTitle(from data: Data) -> String? {
        let prefixData = Data(data.prefix(200_000))
        let html = String(data: prefixData, encoding: .utf8)
            ?? String(data: prefixData, encoding: .isoLatin1)
            ?? ""

        return extractTitle(fromHTML: html)
    }

    public static func extractTitle(fromHTML html: String) -> String? {
        let nsHTML = html as NSString
        let expression = try! NSRegularExpression(
            pattern: #"<title\b[^>]*>(.*?)</title>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        let fullRange = NSRange(location: 0, length: nsHTML.length)

        guard let match = expression.firstMatch(in: html, range: fullRange),
              match.numberOfRanges >= 2 else {
            return nil
        }

        let rawTitle = nsHTML.substring(with: match.range(at: 1))
        let decodedTitle = decodeHTMLEntities(rawTitle)
        let normalizedTitle = decodedTitle
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return normalizedTitle.isEmpty ? nil : normalizedTitle
    }

    private func fetchMetadata(scheme: String, probeHost: String, port: Int) async -> SiteMetadata? {
        guard let probeURL = URL(string: "\(scheme)://\(probeHost):\(port)"),
              let displayURL = URL(string: "\(scheme)://localhost:\(port)") else {
            return nil
        }

        var request = URLRequest(url: probeURL, timeoutInterval: timeout)
        request.httpMethod = "GET"
        request.setValue("LocalHostMonitor/1.0", forHTTPHeaderField: "User-Agent")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession(
            configuration: configuration,
            delegate: LocalhostTrustDelegate(),
            delegateQueue: nil
        )
        defer {
            session.finishTasksAndInvalidate()
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return nil
            }

            return SiteMetadata(
                url: displayURL,
                inferredTitle: Self.extractTitle(from: data),
                statusCode: httpResponse.statusCode
            )
        } catch {
            return nil
        }
    }

    private func probeHosts(for endpoint: ListeningEndpoint) -> [String] {
        switch endpoint.host.lowercased() {
        case "::1":
            return ["[::1]", "localhost"]
        case "localhost":
            return ["localhost", "127.0.0.1"]
        default:
            return ["127.0.0.1", "localhost"]
        }
    }

    private static func statusPreference(_ statusCode: Int) -> (Int, Int) {
        switch statusCode {
        case 200..<300:
            return (0, statusCode)
        case 300..<400:
            return (1, statusCode)
        case 400..<500:
            return (2, statusCode)
        case 500..<600:
            return (3, statusCode)
        default:
            return (4, statusCode)
        }
    }

    private static func decodeHTMLEntities(_ value: String) -> String {
        var result = value
        let namedEntities = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
            "&apos;": "'"
        ]

        for (entity, replacement) in namedEntities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        let expression = try! NSRegularExpression(pattern: #"&#(x?[0-9a-fA-F]+);"#)
        let nsResult = result as NSString
        let matches = expression.matches(
            in: result,
            range: NSRange(location: 0, length: nsResult.length)
        )

        for match in matches.reversed() {
            let token = nsResult.substring(with: match.range(at: 1))
            let radix = token.lowercased().hasPrefix("x") ? 16 : 10
            let digits = radix == 16 ? String(token.dropFirst()) : token

            guard let scalarValue = UInt32(digits, radix: radix),
                  let scalar = UnicodeScalar(scalarValue) else {
                continue
            }

            result = (result as NSString).replacingCharacters(
                in: match.range(at: 0),
                with: String(Character(scalar))
            )
        }

        return result
    }
}

private final class LocalhostTrustDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              ["127.0.0.1", "::1", "localhost"].contains(challenge.protectionSpace.host),
              let serverTrust = challenge.protectionSpace.serverTrust else {
            return (.performDefaultHandling, nil)
        }

        return (.useCredential, URLCredential(trust: serverTrust))
    }
}
