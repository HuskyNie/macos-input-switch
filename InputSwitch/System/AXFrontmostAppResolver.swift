import ApplicationServices
import Foundation

enum AXFrontmostAppResolver {
    static func frontmostProcessID() -> pid_t? {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedApplication: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApplication
        )
        guard result == .success, let focusedApplication else {
            return nil
        }

        var processID: pid_t = 0
        AXUIElementGetPid(focusedApplication as! AXUIElement, &processID)
        return processID
    }
}
