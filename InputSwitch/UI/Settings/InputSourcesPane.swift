import SwiftUI

struct InputSourcesPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        SettingsPaneContainer(
            title: "输入法列表",
            subtitle: "当前系统可选择的键盘输入源。"
        ) {
            if viewModel.availableInputSources.isEmpty {
                SettingsEmptyState(
                    title: "未发现输入法",
                    message: "请确认系统键盘输入源已启用，然后重启应用。",
                    systemImage: "keyboard.badge.ellipsis"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.availableInputSources, id: \.id) { source in
                        InputSourceRow(
                            source: source,
                            isDefault: viewModel.defaultInputSourceID == source.id,
                            setDefault: { viewModel.setDefaultInputSourceID(source.id) }
                        )
                    }
                }
            }
        }
    }
}

private struct InputSourceRow: View {
    let source: InputSourceDescriptor
    let isDefault: Bool
    let setDefault: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "keyboard")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(source.displayName)
                        .font(.headline)
                    if isDefault {
                        Text("默认")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.blue.opacity(0.14), in: Capsule())
                    }
                }
                Text(source.id)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if !isDefault {
                Button("设为默认", action: setDefault)
            }
        }
        .padding(14)
        .settingsCardStyle()
    }
}
