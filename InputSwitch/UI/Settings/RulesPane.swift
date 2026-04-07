import SwiftUI

struct RulesPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        List(viewModel.rules) { entry in
            Text("\(entry.key) -> \(String(describing: entry.rule))")
        }
    }
}
