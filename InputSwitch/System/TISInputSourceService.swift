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

    func switchToInputSource(id: String) -> Bool {
        guard let source = copySources().first(where: { descriptor(from: $0)?.id == id }) else {
            return false
        }

        return TISSelectInputSource(source) == noErr
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

        return (sourceList as Array as? [TISInputSource] ?? []).filter(isSelectableKeyboardInputSource)
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

        return InputSourceDescriptor(
            id: sourceID,
            displayName: localizedName,
            iconURL: urlProperty(kTISPropertyIconImageURL, from: source)
        )
    }

    static func isSelectableKeyboardInputSource(
        category: CFString?,
        isSelectCapable: Bool,
        isEnabled: Bool
    ) -> Bool {
        category == kTISCategoryKeyboardInputSource && isSelectCapable && isEnabled
    }

    private func isSelectableKeyboardInputSource(_ source: TISInputSource) -> Bool {
        let category = stringProperty(kTISPropertyInputSourceCategory, from: source)
        let isSelectCapable = boolProperty(kTISPropertyInputSourceIsSelectCapable, from: source) ?? false
        let isEnabled = boolProperty(kTISPropertyInputSourceIsEnabled, from: source) ?? false
        return Self.isSelectableKeyboardInputSource(
            category: category,
            isSelectCapable: isSelectCapable,
            isEnabled: isEnabled
        )
    }

    private func stringProperty(_ key: CFString, from source: TISInputSource) -> CFString? {
        guard let pointer = TISGetInputSourceProperty(source, key) else {
            return nil
        }
        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue()
    }

    private func boolProperty(_ key: CFString, from source: TISInputSource) -> Bool? {
        guard let pointer = TISGetInputSourceProperty(source, key) else {
            return nil
        }
        let value = Unmanaged<CFBoolean>.fromOpaque(pointer).takeUnretainedValue()
        return CFBooleanGetValue(value)
    }

    private func urlProperty(_ key: CFString, from source: TISInputSource) -> URL? {
        guard let pointer = TISGetInputSourceProperty(source, key) else {
            return nil
        }
        return Unmanaged<CFURL>.fromOpaque(pointer).takeUnretainedValue() as URL
    }
}
