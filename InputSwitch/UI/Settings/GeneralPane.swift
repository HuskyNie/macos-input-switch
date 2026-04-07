import SwiftUI

struct GeneralPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Toggle(
            "开机启动",
            isOn: Binding(
                get: { viewModel.launchAtLoginEnabled },
                set: { viewModel.setLaunchAtLogin($0) }
            )
        )
        .padding()
    }
}
