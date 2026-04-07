import ApplicationServices
import Foundation

struct PermissionService {
    func accessibilityEnabled() -> Bool {
        AXIsProcessTrusted()
    }
}
