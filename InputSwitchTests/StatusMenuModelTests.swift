import XCTest
@testable import InputSwitch

final class StatusMenuModelTests: XCTestCase {
    func test_menu_maps_abc_to_template_glyph_a() {
        let model = StatusMenuModel.make(
            activeAppName: "iTerm2",
            currentInputSourceName: "ABC",
            currentInputSourceID: "com.apple.keylayout.ABC",
            isPaused: false
        )

        XCTAssertEqual(model.icon, .templateGlyph("A", style: .outlined))
    }

    func test_menu_maps_shuangpin_to_template_glyph() {
        let model = StatusMenuModel.make(
            activeAppName: "iTerm2",
            currentInputSourceName: "Shuangpin – Simplified",
            currentInputSourceID: "com.apple.inputmethod.SCIM.Shuangpin",
            isPaused: false
        )

        XCTAssertEqual(model.icon, .templateGlyph("双", style: .filledCutout))
    }

    func test_menu_maps_wubi_to_template_glyph() {
        let model = StatusMenuModel.make(
            activeAppName: "iTerm2",
            currentInputSourceName: "五笔",
            currentInputSourceID: "im.wubi",
            isPaused: false
        )

        XCTAssertEqual(model.icon, .templateGlyph("五", style: .filledCutout))
    }

    func test_menu_falls_back_to_first_visible_character_for_unknown_input_source() {
        let model = StatusMenuModel.make(
            activeAppName: "iTerm2",
            currentInputSourceName: "搜狗输入法",
            currentInputSourceID: "com.sogou.inputmethod",
            isPaused: false
        )

        XCTAssertEqual(model.icon, .templateGlyph("搜", style: .filledCutout))
    }

    func test_menu_contains_grouped_actions_with_short_labels() {
        let model = StatusMenuModel.make(
            activeAppName: "iTerm2",
            currentInputSourceName: "ABC",
            currentInputSourceID: nil,
            isPaused: false
        )

        XCTAssertEqual(
            model.items.map(\.title),
            [
                "当前应用    iTerm2",
                "当前输入法  ABC",
                "",
                "忽略当前应用",
                "清除此应用记忆",
                "暂停 30 分钟",
                "",
                "打开设置…",
                "退出 InputSwitch"
            ]
        )
        XCTAssertEqual(model.items.filter(\.isSeparator).count, 2)
        XCTAssertEqual(model.items.compactMap(\.systemImageName), [
            "macwindow",
            "keyboard",
            "nosign",
            "trash",
            "pause.circle",
            "gearshape",
            "power"
        ])
        XCTAssertEqual(model.icon, .templateGlyph("A", style: .outlined))
    }

    func test_menu_uses_resume_action_when_paused() {
        let model = StatusMenuModel.make(
            activeAppName: "iTerm2",
            currentInputSourceName: "ABC",
            currentInputSourceID: nil,
            isPaused: true
        )

        XCTAssertTrue(model.items.contains(.init(title: "恢复自动切换", action: .pauseTemporarily, systemImageName: "play.circle")))
    }
}
