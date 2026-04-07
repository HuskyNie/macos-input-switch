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
        let pidResult = AXUIElementGetPid(focusedApplication as! AXUIElement, &processID)
        return validatedProcessID(result: pidResult, pid: processID)
    }

    static func validatedProcessID(result: AXError, pid: pid_t) -> pid_t? {
        guard result == .success else {
            return nil
        }
        return pid
    }
}
