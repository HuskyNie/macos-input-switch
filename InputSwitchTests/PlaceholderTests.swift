import XCTest
@testable import InputSwitch

@MainActor
final class PlaceholderTests: XCTestCase {
    func test_bootstrap_renders_status_menu_even_without_settings_view_model() {
        let inputSourceManager = StubInputSourceManager(
            currentInputSource: .init(id: "com.apple.keylayout.ABC", displayName: "ABC"),
            availableInputSources: [.init(id: "com.apple.keylayout.ABC", displayName: "ABC")]
        )
        let activeAppMonitor = StubActiveAppMonitor()
        let statusRenderer = SpyStatusMenuRenderer()
        let container = AppContainer(
            inputSourceManagerFactory: { inputSourceManager },
            activeAppMonitorFactory: { activeAppMonitor },
            statusBarControllerFactory: { _ in statusRenderer },
            frontmostApplicationProvider: {
                .init(
                    bundleID: "com.apple.finder",
                    bundlePath: "/System/Library/CoreServices/Finder.app",
                    executableName: "Finder",
                    displayName: "访达"
                )
            }
        )

        container.bootstrap()

        XCTAssertEqual(
            statusRenderer.models.last,
            StatusMenuModel.make(
                activeAppName: "访达",
                currentInputSourceName: "ABC",
                currentInputSourceID: "com.apple.keylayout.ABC",
                isPaused: false
            )
        )
        XCTAssertNil(container.settingsViewModel)
        XCTAssertTrue(inputSourceManager.didStart)
        XCTAssertTrue(activeAppMonitor.didStart)
        XCTAssertEqual(inputSourceManager.availableInputSourcesCallCount, 1)
    }

    func test_status_menu_refresh_does_not_requery_available_input_sources_without_settings_view_model() {
        let inputSourceManager = StubInputSourceManager(
            currentInputSource: .init(id: "com.apple.keylayout.ABC", displayName: "ABC"),
            availableInputSources: [.init(id: "com.apple.keylayout.ABC", displayName: "ABC")]
        )
        let statusRenderer = SpyStatusMenuRenderer()
        let container = AppContainer(
            inputSourceManagerFactory: { inputSourceManager },
            statusBarControllerFactory: { _ in statusRenderer },
            frontmostApplicationProvider: {
                .init(
                    bundleID: "com.apple.finder",
                    bundlePath: "/System/Library/CoreServices/Finder.app",
                    executableName: "Finder",
                    displayName: "访达"
                )
            }
        )

        container.bootstrap()
        inputSourceManager.onChange?(.init(id: "com.apple.keylayout.ABC", displayName: "ABC"))
        RunLoop.main.run(until: Date().addingTimeInterval(0.01))

        XCTAssertEqual(inputSourceManager.availableInputSourcesCallCount, 1)
    }

    func test_show_settings_uses_owned_settings_window_without_system_action() {
        var didShowSettings = false
        let container = AppContainer(
            activateAppAction: {},
            showSettingsAction: {
                didShowSettings = true
                return true
            }
        )

        container.showSettings()

        XCTAssertFalse(didShowSettings)
        XCTAssertNotNil(container.settingsViewModel)
    }

    func test_show_settings_creates_fallback_view_model_when_system_settings_action_fails() {
        let container = AppContainer(
            activateAppAction: {},
            showSettingsAction: {
                false
            }
        )

        container.showSettings()

        XCTAssertNotNil(container.settingsViewModel)
    }

    func test_show_settings_activates_app_before_opening_owned_window() {
        var callOrder: [String] = []
        let container = AppContainer(
            activateAppAction: {
                callOrder.append("activate")
            },
            showSettingsAction: {
                callOrder.append("show")
                return true
            }
        )

        container.showSettings()

        XCTAssertEqual(callOrder, ["activate"])
        XCTAssertNotNil(container.settingsViewModel)
    }

    func test_bind_settings_view_model_is_lazy_and_explicit() {
        let container = AppContainer()
        let viewModel = SettingsViewModel()

        XCTAssertNil(container.settingsViewModel)

        container.bindSettingsViewModel(viewModel)

        XCTAssertTrue(container.settingsViewModel === viewModel)

        container.unbindSettingsViewModel(viewModel)

        XCTAssertNil(container.settingsViewModel)
    }

    func test_active_app_activation_updates_bound_settings_view_model() {
        let activeAppMonitor = StubActiveAppMonitor()
        let container = AppContainer(
            activeAppMonitorFactory: { activeAppMonitor },
            frontmostApplicationProvider: {
                .init(
                    bundleID: "com.apple.finder",
                    bundlePath: "/System/Library/CoreServices/Finder.app",
                    executableName: "Finder",
                    displayName: "访达"
                )
            }
        )
        let viewModel = SettingsViewModel()

        container.bootstrap()
        container.bindSettingsViewModel(viewModel)
        activeAppMonitor.onActivation?(
            .init(
                bundleID: "com.apple.dt.Xcode",
                bundlePath: nil,
                executableName: "Xcode",
                displayName: "Xcode"
            )
        )
        RunLoop.main.run(until: Date().addingTimeInterval(0.01))

        XCTAssertEqual(viewModel.currentActiveAppDisplayName, "Xcode")
    }

    func test_pause_timer_clears_pause_state_when_it_expires() {
        let timer = StubTimer()
        let container = AppContainer(
            pauseTimerScheduler: { _, action in
                timer.action = action
                return timer
            }
        )

        container.togglePause()
        XCTAssertTrue(container.isPaused)

        timer.fire()
        RunLoop.main.run(until: Date().addingTimeInterval(0.01))

        XCTAssertFalse(container.isPaused)
        XCTAssertTrue(timer.didInvalidate)
    }
}

private final class StubTimer: AppTimerControlling {
    var action: (() -> Void)?
    var didInvalidate = false

    func invalidate() {
        didInvalidate = true
    }

    func fire() {
        action?()
    }
}

private final class StubInputSourceManager: InputSourceManaging {
    var onChange: ((InputSourceDescriptor) -> Void)?
    private let current: InputSourceDescriptor?
    private let sources: [InputSourceDescriptor]
    private(set) var didStart = false
    private(set) var availableInputSourcesCallCount = 0

    init(currentInputSource: InputSourceDescriptor?, availableInputSources: [InputSourceDescriptor]) {
        self.current = currentInputSource
        self.sources = availableInputSources
    }

    func start() {
        didStart = true
    }

    func availableInputSources() -> [InputSourceDescriptor] {
        availableInputSourcesCallCount += 1
        return sources
    }

    func currentInputSource() -> InputSourceDescriptor? {
        current
    }

    func switchToInputSource(id: String) -> Bool {
        true
    }
}

private final class StubActiveAppMonitor: ActiveAppMonitoring {
    var onActivation: ((ApplicationIdentity) -> Void)?
    private(set) var didStart = false

    func start() {
        didStart = true
    }
}

@MainActor
private final class SpyStatusMenuRenderer: StatusMenuRendering {
    private(set) var models: [StatusMenuModel] = []

    func render(model: StatusMenuModel) {
        models.append(model)
    }
}
