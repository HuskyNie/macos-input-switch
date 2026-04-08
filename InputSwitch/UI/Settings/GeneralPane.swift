import SwiftUI

struct GeneralPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(
                "默认输入法",
                selection: Binding(
                    get: { viewModel.defaultInputSourceID ?? "" },
                    set: { viewModel.setDefaultInputSourceID($0.isEmpty ? nil : $0) }
                )
            ) {
                Text("未设置").tag("")
                ForEach(viewModel.availableInputSources, id: \.id) { source in
                    Text(source.displayName).tag(source.id)
                }
            }
            .pickerStyle(.menu)

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
