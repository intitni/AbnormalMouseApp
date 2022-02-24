import AppKit
import Combine

final class ActivatorValidityChecker {
    func checkValidity(_ activator: Activator) -> Bool {
        let isMouseLeftOrRight = activator.keyCombination.activator == .mouse(0)
            || activator.keyCombination.activator == .mouse(0)
        let hasNoModifier = activator.keyCombination.modifiers.isEmpty
        return !(isMouseLeftOrRight && hasNoModifier)
    }
}
