import Foundation

enum AppRule: Equatable, Codable {
    case remembered
    case ignored
    case locked(inputSourceID: String)
}
