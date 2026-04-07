import Foundation

protocol ActiveAppMonitoring: AnyObject {
    var onActivation: ((ApplicationIdentity) -> Void)? { get set }

    func start()
}
