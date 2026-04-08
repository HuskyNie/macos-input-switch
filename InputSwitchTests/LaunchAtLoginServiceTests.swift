import XCTest
import ServiceManagement
@testable import InputSwitch

final class LaunchAtLoginServiceTests: XCTestCase {
    func test_status_maps_service_statuses_to_domain_state() {
        XCTAssertEqual(makeService(status: .enabled).status(), .enabled)
        XCTAssertEqual(makeService(status: .requiresApproval).status(), .requiresApproval)
        XCTAssertEqual(makeService(status: .notRegistered).status(), .disabled)
        XCTAssertEqual(makeService(status: .notFound).status(), .notFound)
    }

    private func makeService(status: SMAppService.Status) -> LaunchAtLoginService {
        LaunchAtLoginService(service: StubMainAppService(status: status))
    }
}

private struct StubMainAppService: MainAppServiceControlling {
    let status: SMAppService.Status

    func register() throws {}

    func unregister() throws {}
}
