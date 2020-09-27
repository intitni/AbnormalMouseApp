import CGEventOverride
import Foundation

protocol OverrideController {}

final class FakeOverrideController: OverrideController {
    var updateSettingsCount = 0
    func updateSettings() {
        updateSettingsCount += 1
    }
}

final class FakeCGEventHook: CGEventHookType {
    var isEnabled: Bool = false
    var manipulations = [AnyHashable: CGEventManipulation]()
    @discardableResult
    func activateIfPossible() -> Bool {
        isEnabled = true
        return true
    }

    func add(_ manipulation: CGEventManipulation, forKey key: AnyHashable) {
        manipulations[key] = manipulation
    }

    func removeManipulation(forKey key: AnyHashable) {
        manipulations[key] = nil
    }

    func deactivate() {
        isEnabled = false
    }
}
