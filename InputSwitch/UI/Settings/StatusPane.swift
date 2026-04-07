import SwiftUI

struct StatusPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Text("默认输入法：\(viewModel.defaultInputSourceName)")
            Text("规则数量：\(viewModel.rules.count)")
        }
        .formStyle(.grouped)
        .padding()
    }
}
