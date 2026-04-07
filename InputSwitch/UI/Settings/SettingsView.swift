import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink("当前状态") {
                    StatusPane(viewModel: viewModel)
                }
                NavigationLink("规则列表") {
                    RulesPane(viewModel: viewModel)
                }
                NavigationLink("输入法列表") {
                    InputSourcesPane(viewModel: viewModel)
                }
                NavigationLink("通用设置") {
                    GeneralPane(viewModel: viewModel)
                }
                NavigationLink("日志与诊断") {
                    DiagnosticsPane(viewModel: viewModel)
                }
            }
            .navigationTitle("设置")
            .listStyle(.sidebar)
        } detail: {
            StatusPane(viewModel: viewModel)
        }
        .frame(minWidth: 760, minHeight: 480)
    }
}
