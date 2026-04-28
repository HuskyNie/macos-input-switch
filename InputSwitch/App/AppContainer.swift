import AppKit
import Foundation

protocol AppTimerControlling {
    func invalidate()
}

final class FoundationAppTimerController: AppTimerControlling {
    private var timer: Timer?

    init(timer: Timer) {
        self.timer = timer
    }

    func invalidate() {
        timer?.invalidate()
        timer = nil
    }
}

@MainActor
final class AppContainer {
    private let fileManager: FileManager
    private let permissionService: PermissionService
    private let diagnosticsLogger: DiagnosticsLogger
    private let launchAtLoginService: LaunchAtLoginService
    private let inputSourceManagerFactory: () -> any InputSourceManaging
    private let activeAppMonitorFactory: () -> any ActiveAppMonitoring
    private let statusBarControllerFactory: (@escaping (MenuAction) -> Void) -> any StatusMenuRendering
    private let frontmostApplicationProvider: () -> ApplicationIdentity?
    private let activateAppAction: () -> Void
    private let showSettingsAction: () -> Bool
    private let pauseTimerScheduler: (TimeInterval, @escaping @Sendable () -> Void) -> any AppTimerControlling

    private var settingsStore: SettingsStore?
    private var memoryStore: MemoryStore?
    private var inputSourceManager: (any InputSourceManaging)?
    private var activeAppMonitor: (any ActiveAppMonitoring)?
    private var switchCoordinator: SwitchCoordinator?
    private(set) weak var settingsViewModel: SettingsViewModel?
    private var fallbackSettingsViewModel: SettingsViewModel?
    private var settingsWindowController: SettingsWindowController?
    private var statusBarController: (any StatusMenuRendering)?
    private var pauseTimer: (any AppTimerControlling)?

    private var currentSettings: AppSettings = .default
    private var currentLaunchAtLoginState: LaunchAtLoginState = .disabled
    private var currentActiveApp: ApplicationIdentity?
    private var currentInputSource: InputSourceDescriptor?
    private var availableInputSources: [InputSourceDescriptor] = []
    private var pausedUntil: Date?

    init(
        fileManager: FileManager = .default,
        permissionService: PermissionService = PermissionService(),
        diagnosticsLogger: DiagnosticsLogger = DiagnosticsLogger(),
        launchAtLoginService: LaunchAtLoginService = LaunchAtLoginService(),
        inputSourceManagerFactory: @escaping () -> any InputSourceManaging = { TISInputSourceService() },
        activeAppMonitorFactory: @escaping () -> any ActiveAppMonitoring = { WorkspaceActiveAppMonitor() },
        statusBarControllerFactory: @escaping (@escaping (MenuAction) -> Void) -> any StatusMenuRendering = { handler in
            StatusBarController(handler: handler)
        },
        frontmostApplicationProvider: @escaping () -> ApplicationIdentity? = {
            AppContainer.resolveFrontmostApplicationIdentity()
        },
        activateAppAction: @escaping () -> Void = {
            NSApp.activate(ignoringOtherApps: true)
        },
        showSettingsAction: @escaping () -> Bool = {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        },
        pauseTimerScheduler: @escaping (TimeInterval, @escaping @Sendable () -> Void) -> any AppTimerControlling = { interval, action in
            FoundationAppTimerController(
                timer: Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
                    action()
                }
            )
        }
    ) {
        self.fileManager = fileManager
        self.permissionService = permissionService
        self.diagnosticsLogger = diagnosticsLogger
        self.launchAtLoginService = launchAtLoginService
        self.inputSourceManagerFactory = inputSourceManagerFactory
        self.activeAppMonitorFactory = activeAppMonitorFactory
        self.statusBarControllerFactory = statusBarControllerFactory
        self.frontmostApplicationProvider = frontmostApplicationProvider
        self.activateAppAction = activateAppAction
        self.showSettingsAction = showSettingsAction
        self.pauseTimerScheduler = pauseTimerScheduler
    }

    func bootstrap() {
        guard statusBarController == nil else {
            return
        }

        let baseDirectory = makeBaseDirectory()
        let settingsStore = SettingsStore(baseDirectory: baseDirectory)
        let memoryStore = MemoryStore(baseDirectory: baseDirectory)
        let inputSourceManager = inputSourceManagerFactory()
        let activeAppMonitor = activeAppMonitorFactory()
        let statusBarController = statusBarControllerFactory { [weak self] action in
            Task { @MainActor in
                self?.handleMenuAction(action)
            }
        }

        self.settingsStore = settingsStore
        self.memoryStore = memoryStore
        self.inputSourceManager = inputSourceManager
        self.activeAppMonitor = activeAppMonitor
        self.statusBarController = statusBarController

        currentSettings = settingsStore.load()
        availableInputSources = inputSourceManager.availableInputSources()
        currentInputSource = inputSourceManager.currentInputSource()
        currentActiveApp = frontmostApplicationProvider()

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
        log("已发现输入法：\(availableInputSources.count)")

        refreshUI()
    }

    var isPaused: Bool {
        guard let pausedUntil else {
            return false
        }
        return pausedUntil > Date()
    }

    func bindSettingsViewModel(_ viewModel: SettingsViewModel) {
        settingsViewModel = viewModel
        configureCallbacks(for: viewModel)
        refreshUI()
    }

    func unbindSettingsViewModel(_ viewModel: SettingsViewModel) {
        guard settingsViewModel === viewModel else {
            return
        }
        settingsViewModel = nil
    }

    func showSettings() {
        activateAppAction()
        showFallbackSettingsWindow()
    }

    private func showFallbackSettingsWindow() {
        let viewModel = settingsViewModel ?? fallbackSettingsViewModel ?? SettingsViewModel()
        fallbackSettingsViewModel = viewModel
        bindSettingsViewModel(viewModel)

        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(viewModel: viewModel)
        }
        settingsWindowController?.show()
    }

    private func handleAppActivation(_ app: ApplicationIdentity) {
        guard !isInputSwitchApp(app) else {
            return
        }

        currentActiveApp = app
        refreshUI()

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
            showSettings()
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

    private func setDefaultInputSource(_ inputSourceID: String?) {
        var updatedSettings = currentSettings
        updatedSettings.defaultInputSourceID = inputSourceID

        do {
            try persistSettings(updatedSettings)
            rebuildCoordinator()

            if let inputSourceID {
                let displayName = availableInputSources.first(where: { $0.id == inputSourceID })?.displayName ?? inputSourceID
                log("默认输入法已设置为：\(displayName)")
            } else {
                log("已清除默认输入法")
            }
        } catch {
            log("保存默认输入法失败：\(error.localizedDescription)")
            refreshUI()
        }
    }

    private func upsertRule(key: String, rule: AppRule) {
        var updatedSettings = currentSettings
        updatedSettings.rules[key] = rule

        do {
            try persistSettings(updatedSettings)
            rebuildCoordinator()
            log("已保存规则：\(key)")
        } catch {
            log("保存规则失败：\(error.localizedDescription)")
            refreshUI()
        }
    }

    private func deleteRule(key: String) {
        guard currentSettings.rules[key] != nil else {
            log("规则不存在：\(key)")
            return
        }

        var updatedSettings = currentSettings
        updatedSettings.rules.removeValue(forKey: key)

        do {
            try persistSettings(updatedSettings)
            rebuildCoordinator()
            log("已删除规则：\(key)")
        } catch {
            log("删除规则失败：\(error.localizedDescription)")
            refreshUI()
        }
    }

    func togglePause() {
        if isPaused {
            pausedUntil = nil
            invalidatePauseTimer()
            log("已恢复自动切换")
        } else {
            pausedUntil = Date().addingTimeInterval(30 * 60)
            schedulePauseTimer()
            log("已暂停自动切换 30 分钟")
        }
        updateStatusMenu()
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        guard settingsViewModel != nil else {
            return
        }

        do {
            try launchAtLoginService.setEnabled(enabled)

            let launchAtLoginState = launchAtLoginService.status()
            currentLaunchAtLoginState = launchAtLoginState
            var updatedSettings = currentSettings
            updatedSettings.launchAtLoginEnabled = launchAtLoginState.isActive
            try persistSettings(updatedSettings)

            switch launchAtLoginState {
            case .enabled:
                log("开机启动已开启")
            case .requiresApproval:
                log("开机启动状态已提交，等待系统批准")
            case .disabled:
                log("开机启动已关闭")
            case .notFound:
                log("找不到开机启动服务")
            }
        } catch {
            currentLaunchAtLoginState = launchAtLoginService.status()
            log("设置开机启动失败：\(error.localizedDescription)")
            refreshUI()
        }
    }

    private func syncLaunchAtLoginState() {
        let actualState = launchAtLoginService.status()
        currentLaunchAtLoginState = actualState
        let actualEnabled = actualState.isActive
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

    private func setDebugLogging(_ enabled: Bool) {
        var updatedSettings = currentSettings
        updatedSettings.debugLoggingEnabled = enabled

        do {
            try persistSettings(updatedSettings)
            log(enabled ? "已启用 Debug 日志" : "已关闭 Debug 日志")
        } catch {
            log("保存 Debug 日志设置失败：\(error.localizedDescription)")
            refreshUI()
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
            memoryStore: memoryStore,
            availableInputSourceIDsProvider: { [weak self] in
                Set(self?.availableInputSources.map(\.id) ?? [])
            },
            diagnostics: { [weak self] message in
                self?.log(message)
            },
            debugDiagnostics: { [weak self] message in
                self?.debugLog(message)
            }
        )

        if let currentActiveApp, !isPaused {
            switchCoordinator?.handleAppDidActivate(currentActiveApp)
        }
    }

    private func refreshUI() {
        if let settingsViewModel {
            settingsViewModel.reload(
                from: currentSettings,
                launchAtLoginState: currentLaunchAtLoginState,
                availableInputSources: availableInputSources,
                diagnostics: diagnosticsLogger.entries,
                currentActiveApp: currentActiveApp
            )
        }
        updateStatusMenu()
    }

    private func updateStatusMenu() {
        statusBarController?.render(
            model: StatusMenuModel.make(
                activeAppName: currentActiveApp?.displayName ?? "未检测到",
                currentInputSourceName: currentInputSource?.displayName ?? "未检测到",
                currentInputSourceID: currentInputSource?.id,
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

    private static func resolveFrontmostApplicationIdentity() -> ApplicationIdentity? {
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
        print(message)
        refreshUI()
    }

    private func debugLog(_ message: String) {
        guard currentSettings.debugLoggingEnabled else {
            return
        }
        diagnosticsLogger.log(message)
        print(message)
        refreshUI()
    }

    private func configureCallbacks(for viewModel: SettingsViewModel) {
        viewModel.onLaunchAtLoginToggle = { [weak self] enabled in
            Task { @MainActor in
                self?.setLaunchAtLogin(enabled)
            }
        }
        viewModel.onDefaultInputSourceChange = { [weak self] inputSourceID in
            Task { @MainActor in
                self?.setDefaultInputSource(inputSourceID)
            }
        }
        viewModel.onDebugLoggingToggle = { [weak self] enabled in
            Task { @MainActor in
                self?.setDebugLogging(enabled)
            }
        }
        viewModel.onUpsertRule = { [weak self] key, rule in
            Task { @MainActor in
                self?.upsertRule(key: key, rule: rule)
            }
        }
        viewModel.onDeleteRule = { [weak self] key in
            Task { @MainActor in
                self?.deleteRule(key: key)
            }
        }
    }

    private func schedulePauseTimer() {
        invalidatePauseTimer()

        guard let pausedUntil else {
            return
        }

        let interval = pausedUntil.timeIntervalSinceNow
        guard interval > 0 else {
            handlePauseTimerFired()
            return
        }

        pauseTimer = pauseTimerScheduler(interval) { [weak self] in
            Task { @MainActor in
                self?.handlePauseTimerFired()
            }
        }
    }

    private func invalidatePauseTimer() {
        pauseTimer?.invalidate()
        pauseTimer = nil
    }

    private func handlePauseTimerFired() {
        invalidatePauseTimer()

        guard pausedUntil != nil else {
            return
        }

        pausedUntil = nil
        log("暂停已到期，已恢复自动切换")
        updateStatusMenu()
    }

    private func isInputSwitchApp(_ app: ApplicationIdentity) -> Bool {
        if let bundleID = Bundle.main.bundleIdentifier, app.bundleID == bundleID {
            return true
        }

        let bundlePath = Bundle.main.bundleURL.path
        if app.bundlePath == bundlePath {
            return true
        }

        return false
    }
}
