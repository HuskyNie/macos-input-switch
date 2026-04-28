import AppKit

@MainActor
protocol StatusMenuRendering: AnyObject {
    func render(model: StatusMenuModel)
}

@MainActor
final class StatusBarController: NSObject, StatusMenuRendering {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let handler: (MenuAction) -> Void

    init(handler: @escaping (MenuAction) -> Void) {
        self.handler = handler
        super.init()
    }

    func render(model: StatusMenuModel) {
        if let button = statusItem.button {
            switch model.icon {
            case .templateGlyph(let glyph, let style):
                if let image = makeTemplateIcon(glyph: glyph, style: style) {
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
            if item.isSeparator {
                menu.addItem(.separator())
                continue
            }

            let menuItem = NSMenuItem(
                title: item.title,
                action: #selector(handleMenuItem(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.representedObject = item.action
            menuItem.isEnabled = item.action != .none
            if let systemImageName = item.systemImageName {
                menuItem.image = NSImage(systemSymbolName: systemImageName, accessibilityDescription: nil)
            }
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

    private func makeTemplateIcon(glyph: String, style: StatusMenuIconStyle) -> NSImage? {
        let size = NSSize(width: 22, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let badgeRect = NSRect(x: 1.5, y: 1.5, width: rect.width - 3, height: rect.height - 3)
            let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: 6, yRadius: 6)

            NSColor.labelColor.setFill()
            NSColor.labelColor.setStroke()

            switch style {
            case .outlined:
                badgePath.lineWidth = 1.8
                badgePath.stroke()
                self.drawGlyph(glyph, in: badgeRect, clearCutout: false)
            case .filledCutout:
                badgePath.fill()
                badgePath.lineWidth = 1.0
                badgePath.stroke()
                self.drawGlyph(glyph, in: badgeRect, clearCutout: true)
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    private func drawGlyph(_ glyph: String, in rect: NSRect, clearCutout: Bool) {
        let font = NSFont.systemFont(ofSize: 12, weight: .bold)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributed = NSAttributedString(
            string: glyph,
            attributes: [
                .font: font,
                .paragraphStyle: paragraph,
                .foregroundColor: clearCutout ? NSColor.clear : NSColor.labelColor
            ]
        )
        let textSize = attributed.size()
        let drawRect = NSRect(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2 - 0.5,
            width: textSize.width,
            height: textSize.height
        )

        if clearCutout, let context = NSGraphicsContext.current?.cgContext {
            context.saveGState()
            context.setBlendMode(.clear)
            attributed.draw(in: drawRect)
            context.restoreGState()
        } else {
            attributed.draw(in: drawRect)
        }
    }
}
