import SwiftUI

struct StatusPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        SettingsPaneContainer(
            title: "当前状态",
            subtitle: "查看 InputSwitch 当前识别到的应用、输入法和规则概况。"
        ) {
            LazyVGrid(columns: [.init(.adaptive(minimum: 220), spacing: 14)], spacing: 14) {
                StatusSummaryCard(
                    title: "当前前台应用",
                    value: viewModel.currentActiveAppDisplayName,
                    systemImage: "macwindow"
                )
                StatusSummaryCard(
                    title: "默认输入法",
                    value: viewModel.defaultInputSourceName,
                    systemImage: "keyboard"
                )
                StatusSummaryCard(
                    title: "规则数量",
                    value: "\(viewModel.rules.count) 条",
                    systemImage: "list.bullet.rectangle"
                )
            }
        }
    }
}

private struct StatusSummaryCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .settingsCardStyle()
    }
}
