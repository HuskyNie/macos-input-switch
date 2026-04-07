import Foundation

enum ApplicationIdentityResolver {
    static func resolve(
        bundleID: String?,
        bundleURL: URL?,
        executableName: String,
        displayName: String
    ) -> ApplicationIdentity {
        ApplicationIdentity(
            bundleID: bundleID,
            bundlePath: bundleURL?.path,
            executableName: executableName,
            displayName: displayName
        )
    }
}
