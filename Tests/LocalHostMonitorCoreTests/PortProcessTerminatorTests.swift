import XCTest
@testable import LocalHostMonitorCore

final class PortProcessTerminatorTests: XCTestCase {
    func testParsePIDsReturnsUniquePositiveIntegers() {
        let output = """
        123
        456
        123
        not-a-pid
        0
        """

        XCTAssertEqual(PortProcessTerminator.parsePIDs(from: output), [123, 456])
    }
}
