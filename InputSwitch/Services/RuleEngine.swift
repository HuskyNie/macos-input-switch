import Foundation

struct RuleEngine {
    func resolve(
        app: ApplicationIdentity,
        current: InputSourceDescriptor?,
        rules: [String: AppRule],
        memories: [String: String],
        defaultInputSourceID: String
    ) -> RuleDecision {
        let key = app.matchKey

        if case .ignored? = rules[key] {
            return .keepCurrent(reason: .ignored)
        }

        if case .locked(let lockedID)? = rules[key] {
            if current?.id == lockedID {
                return .keepCurrent(reason: .alreadyMatching)
            }
            return .switchTo(inputSourceID: lockedID, reason: .lockedRule)
        }

        if let rememberedID = memories[key] {
            if current?.id == rememberedID {
                return .keepCurrent(reason: .alreadyMatching)
            }
            return .switchTo(inputSourceID: rememberedID, reason: .remembered)
        }

        if current?.id == defaultInputSourceID {
            return .keepCurrent(reason: .alreadyMatching)
        }

        return .switchTo(inputSourceID: defaultInputSourceID, reason: .defaultInputSource)
    }
}
