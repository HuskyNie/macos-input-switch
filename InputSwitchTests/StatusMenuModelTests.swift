import XCTest
@testable import InputSwitch

final class StatusMenuModelTests: XCTestCase {
    func test_menu_contains_only_the_confirmed_minimal_actions() {
        let model = StatusMenuModel.make(
            activeAppName: "iTerm2",
            currentInputSourceName: "ABC",
            isPaused: false
        )

        XCTAssertEqual(
            model.items.map(\.title),
            [
                "当前应用：iTerm2",
                "当前输入法：ABC",
                "将当前应用标记为不管理",
                "清除此应用记忆",
                "暂停自动切换（30 分钟）",
                "打开设置…",
                "退出"
            ]
        )
    }
}
