import SwiftUI

struct DiagnosticsPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        List(viewModel.diagnostics, id: \.self) { line in
            Text(line)
        }
    }
}
