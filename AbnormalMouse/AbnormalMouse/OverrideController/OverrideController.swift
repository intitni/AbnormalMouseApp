import AppKit
import CGEventOverride
import Combine
import Foundation

protocol OverrideController {}

class BaseOverrideController {
    var isDisabled: Bool = false
    let sharedPersisted: Readonly<Persisted.Advanced>
    var cancellables: Set<AnyCancellable> = .init()

    init(sharedPersisted: Readonly<Persisted.Advanced>) {
        self.sharedPersisted = sharedPersisted

        let updateSettings = { [weak self] in
            guard let self = self,
                  let id = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            else { return }
            if self.sharedPersisted.gloablExcludedApplications.contains(where: {
                $0.bundleIdentifier == id
            }) {
                self.isDisabled = true
            } else {
                self.isDisabled = false
            }
        }

        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .sink { _ in updateSettings() }
            .store(in: &cancellables)

        updateSettings()
    }
}

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
