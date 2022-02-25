import AppKit
import Combine

enum KeyCombinationInvalidReason {
    case leftRightMouseButtonNeedModifier
    case needsKeyboardEventListener
}

final class KeyCombinationValidityChecker {
    let persisted: Readonly<Persisted>

    init(persisted: Readonly<Persisted>) {
        self.persisted = persisted
    }

    func checkValidity(_ keyCombination: KeyCombination?) -> KeyCombinationInvalidReason? {
        switch keyCombination?.activator {
        case .none:
            return nil
        case .key:
            return persisted.advanced.listenToKeyboardEvent
                ? nil
                : .needsKeyboardEventListener
        case .mouse:
            return KeyCombinationLeftRightMouseKeyValidityChecker().checkIsValid(keyCombination)
                ? nil
                : .leftRightMouseButtonNeedModifier
        }
    }
}

final class KeyCombinationLeftRightMouseKeyValidityChecker {
    func checkIsValid(_ keyCombination: KeyCombination?) -> Bool {
        if let kc = keyCombination, case let .mouse(index) = kc.activator,
           index == 1 || index == 0
        {
            return !kc.modifiers.isEmpty
        }
        return true
    }
}

extension KeyCombination {
    var validated: Self? {
        KeyCombinationLeftRightMouseKeyValidityChecker().checkIsValid(self)
            ? self
            : nil
    }
}
