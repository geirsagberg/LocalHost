import XCTest
@testable import LocalHostMonitorCore

final class LocalhostSiteTests: XCTestCase {
    func testIsOKOnlyMatchesStatus200() throws {
        let okSite = try makeSite(statusCode: 200)
        let notFoundSite = try makeSite(statusCode: 404)

        XCTAssertTrue(okSite.isOK)
        XCTAssertFalse(notFoundSite.isOK)
    }

    private func makeSite(statusCode: Int) throws -> LocalhostSite {
        let url = try XCTUnwrap(URL(string: "http://localhost:\(statusCode)"))
        return LocalhostSite(
            url: url,
            port: statusCode,
            processName: "test-server",
            pid: 123,
            inferredTitle: "Test",
            httpStatusCode: statusCode
        )
    }
}
