import Foundation

enum RuleReason: Equatable, Codable {
    case ignored
    case lockedRule
    case remembered
    case defaultInputSource
    case alreadyMatching
}

enum RuleDecision: Equatable {
    case keepCurrent(reason: RuleReason)
    case switchTo(inputSourceID: String, reason: RuleReason)
}
