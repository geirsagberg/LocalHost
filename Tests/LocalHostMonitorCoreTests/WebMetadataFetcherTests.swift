import XCTest
@testable import LocalHostMonitorCore

final class WebMetadataFetcherTests: XCTestCase {
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
}
