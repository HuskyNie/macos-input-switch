import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case status = "当前状态"
    case rules = "规则列表"
    case inputSources = "输入法列表"
    case general = "通用设置"
    case diagnostics = "日志与诊断"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .status:
            return "gauge"
        case .rules:
            return "list.bullet.rectangle"
        case .inputSources:
            return "keyboard"
        case .general:
            return "gearshape"
        case .diagnostics:
            return "doc.text.magnifyingglass"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var selection: SettingsSection? = .status

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("设置")
            .listStyle(.sidebar)
        } detail: {
            detailView(for: selection ?? .status)
        }
        .frame(minWidth: 760, minHeight: 480)
    }

    @ViewBuilder
    private func detailView(for section: SettingsSection) -> some View {
        switch section {
        case .status:
            StatusPane(viewModel: viewModel)
        case .rules:
            RulesPane(viewModel: viewModel)
        case .inputSources:
            InputSourcesPane(viewModel: viewModel)
        case .general:
            GeneralPane(viewModel: viewModel)
        case .diagnostics:
            DiagnosticsPane(viewModel: viewModel)
        }
    }
}
