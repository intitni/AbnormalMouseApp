import Combine
import Foundation

enum GestureRecognizers {}

class GestureRecognizer {
    private var gesturesThatForceToFail = [Cancellable & GestureRecognizer]()

    /// When this gesture is actively running, force to fail the target gesture recognizer.
    final func force(cancel otherGestureRecognizer: Cancellable & GestureRecognizer) {
        gesturesThatForceToFail.append(otherGestureRecognizer)
    }

    final func cancelOtherGestures() {
        gesturesThatForceToFail.forEach { $0.cancel() }
    }
}
