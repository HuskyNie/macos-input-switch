import Foundation

struct StatusMenuItem: Equatable {
    let title: String
    let action: MenuAction
}

enum StatusMenuIcon: Equatable {
    case glyph(String)
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
    let icon: StatusMenuIcon
    let items: [StatusMenuItem]

    static func make(
        activeAppName: String,
        currentInputSourceName: String,
        currentInputSourceID: String? = nil,
        isPaused: Bool
    ) -> StatusMenuModel {
        let pauseTitle = isPaused ? "恢复自动切换" : "暂停自动切换（30 分钟）"

        return StatusMenuModel(
            icon: .glyph(menuBarGlyph(for: currentInputSourceName, inputSourceID: currentInputSourceID)),
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

    static func menuBarGlyph(for inputSourceName: String, inputSourceID: String?) -> String {
        let loweredName = inputSourceName.lowercased()
        let loweredID = inputSourceID?.lowercased() ?? ""

        if loweredName == "abc" || loweredName == "u.s." || loweredName == "us" ||
            loweredID.contains("keylayout.abc") || loweredID.contains("keylayout.us") {
            return "A"
        }

        if inputSourceName.contains("双拼") || loweredName.contains("shuangpin") || loweredID.contains("shuangpin") {
            return "双"
        }

        if inputSourceName.contains("五笔") || loweredName.contains("wubi") || loweredID.contains("wubi") {
            return "五"
        }

        if inputSourceName.contains("拼音") || loweredName.contains("pinyin") || loweredID.contains("pinyin") {
            return "拼"
        }

        if let character = inputSourceName.first(where: { !$0.isWhitespace && !$0.isPunctuation }) {
            return String(character)
        }

        return "⌨︎"
    }
}
