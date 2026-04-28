import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    init(viewModel: SettingsViewModel) {
        let rootView = SettingsView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)

        window.title = "InputSwitch 设置"
        window.styleMask.insert([.closable, .miniaturizable, .resizable, .titled])
        window.setContentSize(NSSize(width: 820, height: 520))
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        shouldCascadeWindows = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
}
