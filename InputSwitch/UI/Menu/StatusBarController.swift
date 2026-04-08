import AppKit

@MainActor
final class StatusBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let handler: (MenuAction) -> Void

    init(handler: @escaping (MenuAction) -> Void) {
        self.handler = handler
        super.init()
    }

    func render(model: StatusMenuModel) {
        if let button = statusItem.button {
            switch model.icon {
            case .image(let url):
                if let image = NSImage(contentsOf: url) {
                    image.size = NSSize(width: 18, height: 18)
                    button.image = image
                    button.imagePosition = .imageOnly
                    button.title = ""
                } else {
                    button.image = nil
                    button.title = "⌨︎"
                }
            case .text(let text):
                button.image = nil
                button.title = text
            }
        }

        let menu = NSMenu()
        for item in model.items {
            let menuItem = NSMenuItem(
                title: item.title,
                action: #selector(handleMenuItem(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.representedObject = item.action
            menuItem.isEnabled = item.action != .none
            menu.addItem(menuItem)
        }

        statusItem.menu = menu
    }

    @objc
    private func handleMenuItem(_ sender: NSMenuItem) {
        guard let action = sender.representedObject as? MenuAction else {
            return
        }

        handler(action)
    }
}
