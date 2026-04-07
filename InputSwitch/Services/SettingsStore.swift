import Foundation

struct AppSettings: Codable, Equatable {
    var defaultInputSourceID: String?
    var rules: [String: AppRule]
    var launchAtLoginEnabled: Bool

    static let `default` = AppSettings(
        defaultInputSourceID: nil,
        rules: [:],
        launchAtLoginEnabled: false
    )
}

final class SettingsStore {
    private let fileURL: URL
    private let writer = AtomicFileWriter()

    init(baseDirectory: URL) {
        self.fileURL = baseDirectory.appendingPathComponent("settings.json")
    }

    func load() -> AppSettings {
        guard
            let data = try? Data(contentsOf: fileURL),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    func save(_ settings: AppSettings) throws {
        try writer.write(settings, to: fileURL)
    }
}
