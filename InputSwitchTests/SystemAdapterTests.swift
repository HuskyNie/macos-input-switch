import ApplicationServices
import Carbon
import XCTest
@testable import InputSwitch

final class SystemAdapterTests: XCTestCase {
    func test_input_source_filter_requires_keyboard_category_select_capability_and_enabled_state() {
        XCTAssertTrue(
            TISInputSourceService.isSelectableKeyboardInputSource(
                category: kTISCategoryKeyboardInputSource,
                isSelectCapable: true,
                isEnabled: true
            )
        )

        XCTAssertFalse(
            TISInputSourceService.isSelectableKeyboardInputSource(
                category: kTISCategoryPaletteInputSource,
                isSelectCapable: true,
                isEnabled: true
            )
        )

        XCTAssertFalse(
            TISInputSourceService.isSelectableKeyboardInputSource(
                category: kTISCategoryKeyboardInputSource,
                isSelectCapable: false,
                isEnabled: true
            )
        )

        XCTAssertFalse(
            TISInputSourceService.isSelectableKeyboardInputSource(
                category: kTISCategoryKeyboardInputSource,
                isSelectCapable: true,
                isEnabled: false
            )
        )
    }

    func test_frontmost_app_resolver_returns_pid_only_for_successful_ax_lookup() {
        XCTAssertEqual(AXFrontmostAppResolver.validatedProcessID(result: .success, pid: 42), 42)
        XCTAssertNil(AXFrontmostAppResolver.validatedProcessID(result: .failure, pid: 42))
    }
}
