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
            case .glyph(let glyph):
                if let image = makeTemplateIcon(glyph: glyph) {
                    button.image = image
                    button.imagePosition = .imageOnly
                    button.title = ""
                } else {
                    button.image = nil
                    button.title = glyph
                }
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

    private func makeTemplateIcon(glyph: String) -> NSImage? {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let font = NSFont.systemFont(ofSize: 12, weight: .semibold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.labelColor
            ]
            let attributed = NSAttributedString(string: glyph, attributes: attributes)
            let textSize = attributed.size()
            let drawRect = NSRect(
                x: rect.midX - textSize.width / 2,
                y: rect.midY - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            attributed.draw(in: drawRect)
            return true
        }
        image.isTemplate = true
        return image
    }
}
