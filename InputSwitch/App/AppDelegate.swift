import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let container = AppContainer()

    func applicationDidFinishLaunching(_ notification: Notification) {
        container.bootstrap()
    }
}
