import Foundation

struct StatusMenuItem: Equatable {
    let title: String
    let action: MenuAction
    let systemImageName: String?
    let isSeparator: Bool

    init(title: String, action: MenuAction, systemImageName: String? = nil) {
        self.title = title
        self.action = action
        self.systemImageName = systemImageName
        self.isSeparator = false
    }

    private init() {
        title = ""
        action = .none
        systemImageName = nil
        isSeparator = true
    }

    static var separator: StatusMenuItem { StatusMenuItem() }
}

enum StatusMenuIcon: Equatable {
    case templateGlyph(String, style: StatusMenuIconStyle)
}

enum StatusMenuIconStyle: Equatable {
    case outlined
    case filledCutout
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
        let pauseTitle = isPaused ? "恢复自动切换" : "暂停 30 分钟"
        let pauseIcon = isPaused ? "play.circle" : "pause.circle"

        return StatusMenuModel(
            icon: .templateGlyph(
                menuBarGlyph(for: currentInputSourceName, inputSourceID: currentInputSourceID),
                style: menuBarGlyphStyle(for: currentInputSourceName, inputSourceID: currentInputSourceID)
            ),
            items: [
                .init(title: "当前应用    \(activeAppName)", action: .none, systemImageName: "macwindow"),
                .init(title: "当前输入法  \(currentInputSourceName)", action: .none, systemImageName: "keyboard"),
                .separator,
                .init(title: "忽略当前应用", action: .ignoreCurrentApp, systemImageName: "nosign"),
                .init(title: "清除此应用记忆", action: .clearCurrentMemory, systemImageName: "trash"),
                .init(title: pauseTitle, action: .pauseTemporarily, systemImageName: pauseIcon),
                .separator,
                .init(title: "打开设置…", action: .openSettings, systemImageName: "gearshape"),
                .init(title: "退出 InputSwitch", action: .quit, systemImageName: "power")
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

    static func menuBarGlyphStyle(for inputSourceName: String, inputSourceID: String?) -> StatusMenuIconStyle {
        let loweredName = inputSourceName.lowercased()
        let loweredID = inputSourceID?.lowercased() ?? ""

        if loweredName == "abc" || loweredName == "u.s." || loweredName == "us" ||
            loweredID.contains("keylayout.abc") || loweredID.contains("keylayout.us") {
            return .outlined
        }

        return .filledCutout
    }
}
