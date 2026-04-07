import XCTest
@testable import InputSwitch

final class FileStoreTests: XCTestCase {
    func test_settings_store_returns_defaults_when_file_is_missing() throws {
        let directory = try makeTemporaryDirectory()
        let store = SettingsStore(baseDirectory: directory)

        let settings = store.load()

        XCTAssertNil(settings.defaultInputSourceID)
        XCTAssertTrue(settings.rules.isEmpty)
        XCTAssertFalse(settings.launchAtLoginEnabled)
    }

    func test_memory_store_persists_and_reloads_entries() throws {
        let directory = try makeTemporaryDirectory()
        let store = MemoryStore(baseDirectory: directory)

        try store.save(["bundle:com.googlecode.iterm2": "com.apple.keylayout.ABC"])
        let memory = store.load()

        XCTAssertEqual(memory["bundle:com.googlecode.iterm2"], "com.apple.keylayout.ABC")
    }

    func test_corrupt_settings_file_falls_back_to_defaults() throws {
        let directory = try makeTemporaryDirectory()
        let fileURL = directory.appendingPathComponent("settings.json")
        try Data("not-json".utf8).write(to: fileURL)
        let store = SettingsStore(baseDirectory: directory)

        let settings = store.load()

        XCTAssertNil(settings.defaultInputSourceID)
        XCTAssertTrue(settings.rules.isEmpty)
        XCTAssertFalse(settings.launchAtLoginEnabled)
    }

    func test_memory_store_returns_empty_dictionary_when_file_is_missing() throws {
        let directory = try makeTemporaryDirectory()
        let store = MemoryStore(baseDirectory: directory)

        let memory = store.load()

        XCTAssertTrue(memory.isEmpty)
    }

    func test_corrupt_memory_file_falls_back_to_empty_dictionary() throws {
        let directory = try makeTemporaryDirectory()
        let fileURL = directory.appendingPathComponent("memory.json")
        try Data("not-json".utf8).write(to: fileURL)
        let store = MemoryStore(baseDirectory: directory)

        let memory = store.load()

        XCTAssertTrue(memory.isEmpty)
    }

    func test_settings_store_save_throws_when_write_fails() throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("base-file".utf8).write(to: fileURL)
        let store = SettingsStore(baseDirectory: fileURL)

        XCTAssertThrowsError(try store.save(.default))
    }

    func test_memory_store_save_throws_when_write_fails() throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("base-file".utf8).write(to: fileURL)
        let store = MemoryStore(baseDirectory: fileURL)

        XCTAssertThrowsError(try store.save([:]))
    }
}

private func makeTemporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
