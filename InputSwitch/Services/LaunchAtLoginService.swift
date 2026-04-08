import Foundation
import ServiceManagement

enum LaunchAtLoginState: Equatable {
    case enabled
    case requiresApproval
    case disabled
    case notFound

    init(serviceStatus: SMAppService.Status) {
        switch serviceStatus {
        case .enabled:
            self = .enabled
        case .requiresApproval:
            self = .requiresApproval
        case .notRegistered:
            self = .disabled
        case .notFound:
            self = .notFound
        @unknown default:
            self = .disabled
        }
    }

    var isActive: Bool {
        switch self {
        case .enabled, .requiresApproval:
            return true
        case .disabled, .notFound:
            return false
        }
    }

    var statusMessage: String {
        switch self {
        case .enabled:
            return "已启用"
        case .requiresApproval:
            return "等待系统批准"
        case .disabled:
            return "未启用"
        case .notFound:
            return "找不到登录项服务"
        }
    }
}

protocol MainAppServiceControlling {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

struct MainAppServiceController: MainAppServiceControlling {
    var status: SMAppService.Status {
        SMAppService.mainApp.status
    }

    func register() throws {
        try SMAppService.mainApp.register()
    }

    func unregister() throws {
        try SMAppService.mainApp.unregister()
    }
}

final class LaunchAtLoginService {
    private let service: any MainAppServiceControlling

    init(service: any MainAppServiceControlling = MainAppServiceController()) {
        self.service = service
    }

    func status() -> LaunchAtLoginState {
        LaunchAtLoginState(serviceStatus: service.status)
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try service.register()
        } else {
            try service.unregister()
        }
    }
}
