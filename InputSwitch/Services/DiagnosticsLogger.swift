import Foundation

final class DiagnosticsLogger {
    private let limit: Int

    private(set) var entries: [String] = []

    init(limit: Int = 100) {
        self.limit = max(1, limit)
    }

    func log(_ entry: String) {
        entries.append(entry)
        if entries.count > limit {
            entries.removeFirst(entries.count - limit)
        }
    }
}
