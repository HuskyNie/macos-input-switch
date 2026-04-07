import XCTest
@testable import InputSwitch

final class DiagnosticsLoggerTests: XCTestCase {
    func test_logger_keeps_only_recent_entries() {
        let logger = DiagnosticsLogger(limit: 2)

        logger.log("first")
        logger.log("second")
        logger.log("third")

        XCTAssertEqual(logger.entries, ["second", "third"])
    }
}
