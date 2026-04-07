import Foundation

protocol InputSourceManaging: AnyObject {
    var onChange: ((InputSourceDescriptor) -> Void)? { get set }

    func start()
    func availableInputSources() -> [InputSourceDescriptor]
    func currentInputSource() -> InputSourceDescriptor?
    func switchToInputSource(id: String)
}
