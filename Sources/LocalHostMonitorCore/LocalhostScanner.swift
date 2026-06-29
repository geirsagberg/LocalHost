import Foundation

public struct LocalhostScanner: Sendable {
    private let metadataFetcher: WebMetadataFetcher

    public init(metadataFetcher: WebMetadataFetcher = WebMetadataFetcher()) {
        self.metadataFetcher = metadataFetcher
    }

    public func scan() async -> [LocalhostSite] {
        let endpoints = (try? await PortScanner.currentListeningEndpoints()) ?? []
        return await scan(endpoints: endpoints)
    }

    public func scan(endpoints: [ListeningEndpoint]) async -> [LocalhostSite] {
        await withTaskGroup(of: LocalhostSite?.self) { group in
            for endpoint in endpoints {
                group.addTask {
                    guard let metadata = await metadataFetcher.fetchMetadata(for: endpoint) else {
                        return nil
                    }

                    return LocalhostSite(
                        url: metadata.url,
                        port: endpoint.port,
                        processName: endpoint.processName,
                        pid: endpoint.pid,
                        inferredTitle: metadata.inferredTitle,
                        httpStatusCode: metadata.statusCode
                    )
                }
            }

            var sites: [LocalhostSite] = []
            for await site in group {
                if let site {
                    sites.append(site)
                }
            }

            return sites.sorted { lhs, rhs in
                if lhs.port == rhs.port {
                    return lhs.displayURLString < rhs.displayURLString
                }

                return lhs.port < rhs.port
            }
        }
    }
}
