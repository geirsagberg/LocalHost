import XCTest
@testable import LocalHostMonitorCore

final class WebMetadataFetcherTests: XCTestCase {
    func testPreferredMetadataChoosesSuccessfulStatusOverServerError() throws {
        let serverError = try makeMetadata(statusCode: 500)
        let ok = try makeMetadata(statusCode: 200)

        XCTAssertEqual(
            WebMetadataFetcher.preferredMetadata(from: [serverError, ok]),
            ok
        )
    }

    func testPreferredMetadataAllowsRedirectsOverServerError() throws {
        let serverError = try makeMetadata(statusCode: 500)
        let redirect = try makeMetadata(statusCode: 302)

        XCTAssertEqual(
            WebMetadataFetcher.preferredMetadata(from: [serverError, redirect]),
            redirect
        )
    }

    func testExtractTitleNormalizesWhitespaceAndEntities() {
        let html = """
        <!doctype html>
        <html>
          <head>
            <title>
              Local &amp; Useful &#x1F680;
            </title>
          </head>
        </html>
        """

        XCTAssertEqual(
            WebMetadataFetcher.extractTitle(fromHTML: html),
            "Local & Useful 🚀"
        )
    }

    func testExtractTitleReturnsNilWhenTitleIsMissing() {
        XCTAssertNil(WebMetadataFetcher.extractTitle(fromHTML: "<main>No title</main>"))
    }

    private func makeMetadata(statusCode: Int) throws -> SiteMetadata {
        SiteMetadata(
            url: try XCTUnwrap(URL(string: "http://localhost:\(statusCode)")),
            inferredTitle: "HTTP \(statusCode)",
            statusCode: statusCode
        )
    }
}
