import AppKit

final class WorkspaceActiveAppMonitor: NSObject, ActiveAppMonitoring {
    var onActivation: ((ApplicationIdentity) -> Void)?

    private var isObserving = false

    deinit {
        if isObserving {
            NSWorkspace.shared.notificationCenter.removeObserver(self)
        }
    }

    func start() {
        guard !isObserving else {
            return
        }

        isObserving = true
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleApplicationDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func handleApplicationDidActivate(_ notification: Notification) {
        guard
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            let executableName = app.executableURL?.deletingPathExtension().lastPathComponent ?? app.localizedName
        else {
            return
        }

        let identity = ApplicationIdentityResolver.resolve(
            bundleID: app.bundleIdentifier,
            bundleURL: app.bundleURL,
            executableName: executableName,
            displayName: app.localizedName ?? executableName
        )
        onActivation?(identity)
    }
}
