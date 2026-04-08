import Foundation

struct InputSourceDescriptor: Equatable, Codable {
    let id: String
    let displayName: String
    let iconURL: URL?

    init(id: String, displayName: String, iconURL: URL? = nil) {
        self.id = id
        self.displayName = displayName
        self.iconURL = iconURL
    }
}
