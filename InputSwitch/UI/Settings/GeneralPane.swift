import SwiftUI

struct GeneralPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(
                "开机启动",
                isOn: Binding(
                    get: { viewModel.launchAtLoginEnabled },
                    set: { viewModel.setLaunchAtLogin($0) }
                )
            )
            Text(viewModel.launchAtLoginStatusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
