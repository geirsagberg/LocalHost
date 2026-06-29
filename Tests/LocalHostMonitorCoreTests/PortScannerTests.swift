import XCTest
@testable import LocalHostMonitorCore

final class PortScannerTests: XCTestCase {
    func testParseLsofOutputKeepsLocalListeningPorts() {
        let output = """
        COMMAND   PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node      101 geir   21u  IPv4 0x0000000000000000      0t0  TCP 127.0.0.1:3000 (LISTEN)
        Python    102 geir    8u  IPv6 0x0000000000000000      0t0  TCP *:8000 (LISTEN)
        postgres  103 geir    9u  IPv4 0x0000000000000000      0t0  TCP 127.0.0.1:5432 (LISTEN)
        remote    104 geir   12u  IPv4 0x0000000000000000      0t0  TCP 192.168.1.10:9000 (LISTEN)
        """

        let endpoints = PortScanner.parseLsofOutput(output)

        XCTAssertEqual(endpoints.map(\.port), [3000, 5432, 8000])
        XCTAssertEqual(endpoints.first?.processName, "node")
        XCTAssertFalse(endpoints.contains { $0.port == 9000 })
    }

    func testParseLsofOutputPrefersLoopbackWhenPortAppearsTwice() {
        let output = """
        COMMAND   PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node      101 geir   21u  IPv4 0x0000000000000000      0t0  TCP *:5173 (LISTEN)
        node      101 geir   22u  IPv4 0x0000000000000000      0t0  TCP 127.0.0.1:5173 (LISTEN)
        """

        let endpoints = PortScanner.parseLsofOutput(output)

        XCTAssertEqual(endpoints.count, 1)
        XCTAssertEqual(endpoints[0].host, "127.0.0.1")
        XCTAssertEqual(endpoints[0].port, 5173)
    }
}
