import AppKit
import Foundation

@MainActor
final class AppContainer {
    private let fileManager: FileManager
    private let permissionService: PermissionService
    private let diagnosticsLogger: DiagnosticsLogger
    private let launchAtLoginService: LaunchAtLoginService

    private var settingsStore: SettingsStore?
    private var memoryStore: MemoryStore?
    private var inputSourceManager: TISInputSourceService?
    private var activeAppMonitor: WorkspaceActiveAppMonitor?
    private var switchCoordinator: SwitchCoordinator?
    private var settingsViewModel: SettingsViewModel?
    private var settingsWindowController: SettingsWindowController?
    private var statusBarController: StatusBarController?

    private var currentSettings: AppSettings = .default
    private var currentActiveApp: ApplicationIdentity?
    private var currentInputSource: InputSourceDescriptor?
    private var pausedUntil: Date?

    init(
        fileManager: FileManager = .default,
        permissionService: PermissionService = PermissionService(),
        diagnosticsLogger: DiagnosticsLogger = DiagnosticsLogger(),
        launchAtLoginService: LaunchAtLoginService = LaunchAtLoginService()
    ) {
        self.fileManager = fileManager
        self.permissionService = permissionService
        self.diagnosticsLogger = diagnosticsLogger
        self.launchAtLoginService = launchAtLoginService
    }

    func bootstrap() {
        guard statusBarController == nil else {
            return
        }

        let baseDirectory = makeBaseDirectory()
        let settingsStore = SettingsStore(baseDirectory: baseDirectory)
        let memoryStore = MemoryStore(baseDirectory: baseDirectory)
        let inputSourceManager = TISInputSourceService()
        let activeAppMonitor = WorkspaceActiveAppMonitor()
        let settingsViewModel = SettingsViewModel()
        let settingsWindowController = SettingsWindowController(viewModel: settingsViewModel)
        let statusBarController = StatusBarController { [weak self] action in
            Task { @MainActor in
                self?.handleMenuAction(action)
            }
        }

        self.settingsStore = settingsStore
        self.memoryStore = memoryStore
        self.inputSourceManager = inputSourceManager
        self.activeAppMonitor = activeAppMonitor
        self.settingsViewModel = settingsViewModel
        self.settingsWindowController = settingsWindowController
        self.statusBarController = statusBarController

        currentSettings = settingsStore.load()
        currentInputSource = inputSourceManager.currentInputSource()
        currentActiveApp = frontmostApplicationIdentity()

        settingsViewModel.onLaunchAtLoginToggle = { [weak self] enabled in
            Task { @MainActor in
                self?.setLaunchAtLogin(enabled)
            }
        }
        inputSourceManager.onChange = { [weak self] inputSource in
            Task { @MainActor in
                self?.handleInputSourceChange(inputSource)
            }
        }
        activeAppMonitor.onActivation = { [weak self] app in
            Task { @MainActor in
                self?.handleAppActivation(app)
            }
        }

        syncLaunchAtLoginState()
        rebuildCoordinator()

        inputSourceManager.start()
        activeAppMonitor.start()

        log("辅助功能权限：\(permissionService.accessibilityEnabled() ? "已授权" : "未授权")")
        log("已发现输入法：\(inputSourceManager.availableInputSources().count)")

        refreshUI()

        if let currentActiveApp {
            handleAppActivation(currentActiveApp)
        }
    }

    private var isPaused: Bool {
        guard let pausedUntil else {
            return false
        }
        return pausedUntil > Date()
    }

    private func handleAppActivation(_ app: ApplicationIdentity) {
        currentActiveApp = app
        updateStatusMenu()

        guard !isPaused else {
            log("自动切换已暂停，忽略应用切换：\(app.displayName)")
            return
        }

        switchCoordinator?.handleAppDidActivate(app)
    }

    private func handleInputSourceChange(_ inputSource: InputSourceDescriptor) {
        currentInputSource = inputSource
        do {
            try switchCoordinator?.handleInputSourceDidChange(to: inputSource)
        } catch {
            log("记忆输入法失败：\(error.localizedDescription)")
        }
        refreshUI()
    }

    private func handleMenuAction(_ action: MenuAction) {
        switch action {
        case .ignoreCurrentApp:
            ignoreCurrentApp()
        case .clearCurrentMemory:
            clearCurrentMemory()
        case .pauseTemporarily:
            togglePause()
        case .openSettings:
            settingsWindowController?.show()
        case .quit:
            NSApp.terminate(nil)
        case .none:
            break
        }
    }

    private func ignoreCurrentApp() {
        guard let currentActiveApp else {
            log("无法标记忽略：当前没有活动应用")
            return
        }

        var updatedSettings = currentSettings
        updatedSettings.rules[currentActiveApp.matchKey] = .ignored

        do {
            try persistSettings(updatedSettings)
            rebuildCoordinator()
            log("已忽略应用：\(currentActiveApp.displayName)")
        } catch {
            log("保存忽略规则失败：\(error.localizedDescription)")
        }
    }

    private func clearCurrentMemory() {
        guard let currentActiveApp else {
            log("无法清除记忆：当前没有活动应用")
            return
        }
        guard let memoryStore else {
            return
        }

        var memories = memoryStore.load()
        if memories.removeValue(forKey: currentActiveApp.matchKey) == nil {
            log("当前应用没有可清除的记忆：\(currentActiveApp.displayName)")
            return
        }

        do {
            try memoryStore.save(memories)
            rebuildCoordinator()
            log("已清除应用记忆：\(currentActiveApp.displayName)")
        } catch {
            log("清除应用记忆失败：\(error.localizedDescription)")
        }
    }

    private func togglePause() {
        if isPaused {
            pausedUntil = nil
            log("已恢复自动切换")
        } else {
            pausedUntil = Date().addingTimeInterval(30 * 60)
            log("已暂停自动切换 30 分钟")
        }
        updateStatusMenu()
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        guard let settingsViewModel else {
            return
        }

        do {
            try launchAtLoginService.setEnabled(enabled)

            var updatedSettings = currentSettings
            updatedSettings.launchAtLoginEnabled = launchAtLoginService.isEnabled()
            try persistSettings(updatedSettings)

            if updatedSettings.launchAtLoginEnabled == enabled {
                log("开机启动已\(enabled ? "开启" : "关闭")")
            } else {
                log("开机启动状态已提交，等待系统确认")
            }
        } catch {
            settingsViewModel.launchAtLoginEnabled = currentSettings.launchAtLoginEnabled
            log("设置开机启动失败：\(error.localizedDescription)")
            refreshUI()
        }
    }

    private func syncLaunchAtLoginState() {
        let actualEnabled = launchAtLoginService.isEnabled()
        guard actualEnabled != currentSettings.launchAtLoginEnabled else {
            return
        }

        var updatedSettings = currentSettings
        updatedSettings.launchAtLoginEnabled = actualEnabled
        currentSettings = updatedSettings

        do {
            try settingsStore?.save(updatedSettings)
            log("已同步开机启动状态")
        } catch {
            log("同步开机启动状态失败：\(error.localizedDescription)")
        }
    }

    private func rebuildCoordinator() {
        guard let settingsStore, let memoryStore, let inputSourceManager else {
            return
        }

        switchCoordinator = SwitchCoordinator(
            ruleEngine: RuleEngine(),
            inputSourceManager: inputSourceManager,
            settingsStore: settingsStore,
            memoryStore: memoryStore
        )

        if let currentActiveApp, !isPaused {
            switchCoordinator?.handleAppDidActivate(currentActiveApp)
        }
    }

    private func refreshUI() {
        guard let settingsViewModel else {
            return
        }

        settingsViewModel.reload(
            from: currentSettings,
            availableInputSources: inputSourceManager?.availableInputSources() ?? [],
            diagnostics: diagnosticsLogger.entries
        )
        updateStatusMenu()
    }

    private func updateStatusMenu() {
        statusBarController?.render(
            model: StatusMenuModel.make(
                activeAppName: currentActiveApp?.displayName ?? "未检测到",
                currentInputSourceName: currentInputSource?.displayName ?? "未检测到",
                isPaused: isPaused
            )
        )
    }

    private func persistSettings(_ settings: AppSettings) throws {
        try settingsStore?.save(settings)
        currentSettings = settings
        refreshUI()
    }

    private func makeBaseDirectory() -> URL {
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let baseDirectory = appSupportDirectory.appendingPathComponent("InputSwitch", isDirectory: true)

        do {
            try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
            return baseDirectory
        } catch {
            let fallbackDirectory = fileManager.temporaryDirectory
                .appendingPathComponent("InputSwitch", isDirectory: true)
            try? fileManager.createDirectory(at: fallbackDirectory, withIntermediateDirectories: true)
            diagnosticsLogger.log("创建应用数据目录失败，已回退到临时目录：\(error.localizedDescription)")
            return fallbackDirectory
        }
    }

    private func frontmostApplicationIdentity() -> ApplicationIdentity? {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let executableName = app.executableURL?.deletingPathExtension().lastPathComponent
            ?? app.localizedName
            ?? "Unknown"
        return ApplicationIdentityResolver.resolve(
            bundleID: app.bundleIdentifier,
            bundleURL: app.bundleURL,
            executableName: executableName,
            displayName: app.localizedName ?? executableName
        )
    }

    private func log(_ message: String) {
        diagnosticsLogger.log(message)
        refreshUI()
    }
}
