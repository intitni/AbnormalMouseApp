import CGEventOverride
import Combine
import Foundation

extension GestureRecognizers {
    final class MouseMovement: GestureRecognizer {
        private struct Key: Hashable {}

        var isActive: Bool = false {
            didSet {
                guard isActive != oldValue else { return }
                if isActive {
                    cancelOtherGestures { $0 is MouseMovement }
                } else {
                    shouldPostLastEvent = true
                }
            }
        }

        let publisher: AnyPublisher<(CGSize, CGEvent), Never>

        private let hook: CGEventHookType
        private let translation: PassthroughSubject<(CGSize, CGEvent), Never>
        private let key: AnyHashable
        private let throttler: EventThrottler<(CGSize, CGEvent?)>
        private var shouldPostLastEvent = false
        var rate: Int {
            get { throttler.rate }
            set { throttler.rate = newValue }
        }

        deinit {
            hook.removeManipulation(forKey: key)
        }

        init(hook: CGEventHookType, key: AnyHashable) {
            self.key = key
            self.hook = hook
            let translation = PassthroughSubject<(CGSize, CGEvent), Never>()
            self.translation = translation
            publisher = translation
                .receive(on: DispatchQueue.default)
                .eraseToAnyPublisher()
            throttler = .init((.zero, nil)) { p in
                guard let e = p.1 else { return }
                translation.send((p.0, e))
            }
            super.init()

            hook.add(
                .init(
                    eventsOfInterest: [.mouseMoved, .otherMouseDragged],
                    convert: { [weak self] _, _, event -> CGEventManipulation.Result in
                        DispatchQueue.default.sync {
                            guard let self = self else { return .unchange }
                            return self.handleMouse(event: event)
                        }
                    }
                ),
                forKey: key
            )
        }
    }
}

extension GestureRecognizers.MouseMovement: Cancellable {
    func cancel() {
        isActive = false
    }
}

extension GestureRecognizers.MouseMovement {
    private func handleMouse(event: CGEvent) -> CGEventManipulation.Result {
        guard isActive else {
            if shouldPostLastEvent {
                let v = event[double: .mouseEventDeltaY]
                let h = event[double: .mouseEventDeltaX]
                throttler.end(accumulate: { t in
                    t.0.width += CGFloat(h)
                    t.0.height += CGFloat(v)
                    t.1 = event
                })
                shouldPostLastEvent = false
            }
            return .unchange
        }

        let v = event[double: .mouseEventDeltaY]
        let h = event[double: .mouseEventDeltaX]
        throttler.post(accumulate: { t in
            t.0.width += CGFloat(h)
            t.0.height += CGFloat(v)
            t.1 = event
        })

        return .discarded
    }
}
