import XCTest
@testable import InputSwitch

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func test_reload_maps_default_input_source_id_to_display_name() {
        let viewModel = SettingsViewModel()

        viewModel.reload(
            from: AppSettings(
                defaultInputSourceID: "com.apple.keylayout.ABC",
                rules: [:],
                launchAtLoginEnabled: false
            ),
            availableInputSources: [
                .init(id: "com.apple.keylayout.ABC", displayName: "ABC"),
                .init(id: "im.wubi", displayName: "简体五笔")
            ],
            diagnostics: []
        )

        XCTAssertEqual(viewModel.defaultInputSourceName, "ABC")
    }

    func test_reload_falls_back_to_input_source_id_when_display_name_is_unavailable() {
        let viewModel = SettingsViewModel()

        viewModel.reload(
            from: AppSettings(
                defaultInputSourceID: "missing.input.source",
                rules: [:],
                launchAtLoginEnabled: false
            ),
            availableInputSources: [
                .init(id: "com.apple.keylayout.ABC", displayName: "ABC")
            ],
            diagnostics: []
        )

        XCTAssertEqual(viewModel.defaultInputSourceName, "missing.input.source")
    }
}
