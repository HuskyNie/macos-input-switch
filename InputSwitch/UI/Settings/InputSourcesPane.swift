import SwiftUI

struct InputSourcesPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        List(viewModel.availableInputSources, id: \.id) { source in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(source.displayName)
                    Text(source.id)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if viewModel.defaultInputSourceID == source.id {
                    Text("默认")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button("设为默认") {
                        viewModel.setDefaultInputSourceID(source.id)
                    }
                }
            }
        }
    }
}
