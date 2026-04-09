import Foundation

struct AppSettings: Codable, Equatable {
    var defaultInputSourceID: String?
    var rules: [String: AppRule]
    var launchAtLoginEnabled: Bool
    var debugLoggingEnabled: Bool

    static let `default` = AppSettings(
        defaultInputSourceID: nil,
        rules: [:],
        launchAtLoginEnabled: false,
        debugLoggingEnabled: false
    )

    private enum CodingKeys: String, CodingKey {
        case defaultInputSourceID
        case rules
        case launchAtLoginEnabled
        case debugLoggingEnabled
    }

    init(
        defaultInputSourceID: String? = nil,
        rules: [String: AppRule] = [:],
        launchAtLoginEnabled: Bool = false,
        debugLoggingEnabled: Bool = false
    ) {
        self.defaultInputSourceID = defaultInputSourceID
        self.rules = rules
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.debugLoggingEnabled = debugLoggingEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultInputSourceID = try container.decodeIfPresent(String.self, forKey: .defaultInputSourceID)
        rules = try container.decode([String: AppRule].self, forKey: .rules)
        launchAtLoginEnabled = try container.decode(Bool.self, forKey: .launchAtLoginEnabled)
        debugLoggingEnabled = try container.decodeIfPresent(Bool.self, forKey: .debugLoggingEnabled) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(defaultInputSourceID, forKey: .defaultInputSourceID)
        try container.encode(rules, forKey: .rules)
        try container.encode(launchAtLoginEnabled, forKey: .launchAtLoginEnabled)
        try container.encode(debugLoggingEnabled, forKey: .debugLoggingEnabled)
    }
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
