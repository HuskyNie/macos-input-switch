import Foundation

struct ApplicationIdentity: Hashable, Codable {
    let bundleID: String?
    let bundlePath: String?
    let executableName: String
    let displayName: String

    var matchKey: String {
        if let bundleID, !bundleID.isEmpty { return "bundle:\(bundleID)" }
        if let bundlePath, !bundlePath.isEmpty { return "path:\(bundlePath)" }
        return "exec:\(executableName)"
    }
}
