import Foundation

struct StatusMenuItem: Equatable {
    let title: String
    let action: MenuAction
}

enum MenuAction: Equatable {
    case ignoreCurrentApp
    case clearCurrentMemory
    case pauseTemporarily
    case openSettings
    case quit
    case none
}

struct StatusMenuModel: Equatable {
    let items: [StatusMenuItem]

    static func make(
        activeAppName: String,
        currentInputSourceName: String,
        isPaused: Bool
    ) -> StatusMenuModel {
        let pauseTitle = isPaused ? "恢复自动切换" : "暂停自动切换（30 分钟）"

        return StatusMenuModel(
            items: [
                .init(title: "当前应用：\(activeAppName)", action: .none),
                .init(title: "当前输入法：\(currentInputSourceName)", action: .none),
                .init(title: "将当前应用标记为不管理", action: .ignoreCurrentApp),
                .init(title: "清除此应用记忆", action: .clearCurrentMemory),
                .init(title: pauseTitle, action: .pauseTemporarily),
                .init(title: "打开设置…", action: .openSettings),
                .init(title: "退出", action: .quit)
            ]
        )
    }
}
