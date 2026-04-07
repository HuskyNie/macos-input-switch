import Carbon
import Foundation

final class TISInputSourceService: NSObject, InputSourceManaging {
    var onChange: ((InputSourceDescriptor) -> Void)?

    private var isObserving = false

    deinit {
        if isObserving {
            DistributedNotificationCenter.default().removeObserver(self)
        }
    }

    func start() {
        guard !isObserving else {
            return
        }

        isObserving = true
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleSelectedInputSourceDidChange(_:)),
            name: Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil
        )
    }

    func availableInputSources() -> [InputSourceDescriptor] {
        copySources().compactMap(descriptor(from:))
    }

    func currentInputSource() -> InputSourceDescriptor? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }
        return descriptor(from: source)
    }

    func switchToInputSource(id: String) {
        guard let source = copySources().first(where: { descriptor(from: $0)?.id == id }) else {
            return
        }

        TISSelectInputSource(source)
    }

    @objc private func handleSelectedInputSourceDidChange(_ notification: Notification) {
        guard let current = currentInputSource() else {
            return
        }
        onChange?(current)
    }

    private func copySources() -> [TISInputSource] {
        guard let sourceList = TISCreateInputSourceList(nil, false)?.takeRetainedValue() else {
            return []
        }

        return sourceList as Array as? [TISInputSource] ?? []
    }

    private func descriptor(from source: TISInputSource) -> InputSourceDescriptor? {
        guard
            let sourceIDPointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID),
            let sourceID = Unmanaged<CFString>.fromOpaque(sourceIDPointer).takeUnretainedValue() as String?
        else {
            return nil
        }

        let localizedName = TISGetInputSourceProperty(source, kTISPropertyLocalizedName)
            .map { Unmanaged<CFString>.fromOpaque($0).takeUnretainedValue() as String }
            ?? sourceID

        return InputSourceDescriptor(id: sourceID, displayName: localizedName)
    }
}
