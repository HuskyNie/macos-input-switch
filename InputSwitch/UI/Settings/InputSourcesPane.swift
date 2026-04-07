import SwiftUI

struct InputSourcesPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        List(viewModel.availableInputSources, id: \.id) { source in
            Text("\(source.displayName) [\(source.id)]")
        }
    }
}
