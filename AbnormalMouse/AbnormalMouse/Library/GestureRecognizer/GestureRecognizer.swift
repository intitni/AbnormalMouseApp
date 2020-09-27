import AppKit
import Combine

enum GestureRecognizers {}

class GestureRecognizer {
    private var gesturesThatForceToFail = [Cancellable & GestureRecognizer]()

    final var shouldDiscardEvent: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier != "com.intii.AbnormalMouse"
    }

    /// When this gesture is actively running, force to fail the target gesture recognizer.
    final func force(cancel otherGestureRecognizer: Cancellable & GestureRecognizer) {
        gesturesThatForceToFail.append(otherGestureRecognizer)
    }

    final func cancelOtherGestures() {
        gesturesThatForceToFail.forEach { $0.cancel() }
    }
}
