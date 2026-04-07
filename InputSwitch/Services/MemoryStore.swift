import Foundation

final class MemoryStore {
    private let fileURL: URL
    private let writer = AtomicFileWriter()

    init(baseDirectory: URL) {
        self.fileURL = baseDirectory.appendingPathComponent("memory.json")
    }

    func load() -> [String: String] {
        guard
            let data = try? Data(contentsOf: fileURL),
            let memory = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            return [:]
        }
        return memory
    }

    func save(_ memory: [String: String]) {
        try? writer.write(memory, to: fileURL)
    }
}
