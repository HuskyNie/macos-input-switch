import SwiftUI

@main
struct InputSwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsSceneRoot(container: appDelegate.container)
        }
    }
}

private struct SettingsSceneRoot: View {
    let container: AppContainer

    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        SettingsView(viewModel: viewModel)
            .onAppear {
                container.bindSettingsViewModel(viewModel)
            }
            .onDisappear {
                container.unbindSettingsViewModel(viewModel)
            }
    }
}
