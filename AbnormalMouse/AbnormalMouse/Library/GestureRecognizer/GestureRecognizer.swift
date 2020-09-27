import AppKit
import Combine

enum GestureRecognizers {}

private var allGestureRecognizers = [GestureRecognizer]()

class GestureRecognizer {
    init() {
        allGestureRecognizers.append(self)
    }

    final var shouldDiscardEvent: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier != "com.intii.AbnormalMouse"
    }

    final func cancelOtherGestures(where condition: (GestureRecognizer) -> Bool = { _ in true }) {
        allGestureRecognizers.forEach {
            guard $0 !== self else { return }
            guard condition($0) else { return }
            guard let cancellable = $0 as? Cancellable else { return }
            cancellable.cancel()
        }
    }
}
