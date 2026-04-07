import Foundation

final class LoopGuard {
    private let suppressionWindow: TimeInterval
    private var lastProgrammaticSwitch: (id: String, timestamp: Date)?

    init(suppressionWindow: TimeInterval = 0.8) {
        self.suppressionWindow = suppressionWindow
    }

    func markProgrammaticSwitch(to inputSourceID: String, now: Date = Date()) {
        lastProgrammaticSwitch = (id: inputSourceID, timestamp: now)
    }

    func shouldIgnoreInputChange(to inputSourceID: String, now: Date = Date()) -> Bool {
        guard let lastProgrammaticSwitch else {
            return false
        }

        let withinSuppressionWindow = now.timeIntervalSince(lastProgrammaticSwitch.timestamp) <= suppressionWindow
        return withinSuppressionWindow && lastProgrammaticSwitch.id == inputSourceID
    }
}
