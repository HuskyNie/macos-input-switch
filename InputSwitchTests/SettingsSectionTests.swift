import XCTest
@testable import InputSwitch

final class SettingsSectionTests: XCTestCase {
    func test_settings_sections_start_with_status_for_initial_sidebar_selection() {
        XCTAssertEqual(SettingsSection.allCases.first, .status)
        XCTAssertEqual(SettingsSection.status.rawValue, "当前状态")
    }

    func test_settings_sections_have_sidebar_icons() {
        XCTAssertEqual(SettingsSection.status.systemImage, "gauge")
        XCTAssertEqual(SettingsSection.rules.systemImage, "list.bullet.rectangle")
        XCTAssertEqual(SettingsSection.inputSources.systemImage, "keyboard")
        XCTAssertEqual(SettingsSection.general.systemImage, "gearshape")
        XCTAssertEqual(SettingsSection.diagnostics.systemImage, "doc.text.magnifyingglass")
    }
}
