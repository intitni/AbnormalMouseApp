import CGEventOverride
import Combine
import Foundation

extension GestureRecognizers {
    final class Tap: GestureRecognizer {
        private struct Key: Hashable {}

        let publisher: AnyPublisher<Void, Never>
        var keyCombination: KeyCombination? { didSet { state = State() } }
        var numberOfTapsRequired = 1 { didSet { state = State() } }

        struct State {
            /// Last timestamp when key combination is triggered with event keyUp or mouseUp.
            /// Double tap gesture should use it to determine if it should trigger.
            var lastButtonUpTimestamp = 0 as TimeInterval
            var tapCount = 0
            var isDown = false
            var holdingDownKeys = Set<Int64>()
            var holdingDownMouseButtons = Set<Int64>()
        }

        private let hook: CGEventHookType
        private let subject: PassthroughSubject<Void, Never>
        private(set) var state = State()
        private let key: AnyHashable
        private var delayedEvent: DispatchWorkItem?
        private let tapGestureDelayInMilliSeconds: () -> Int

        deinit {
            hook.removeManipulation(forKey: key)
        }

        init(
            hook: CGEventHookType,
            key: AnyHashable,
            tapGestureDelayInMilliSeconds: @escaping () -> Int
        ) {
            self.key = key
            self.hook = hook
            self.tapGestureDelayInMilliSeconds = tapGestureDelayInMilliSeconds
            subject = .init()
            publisher = subject
                .receive(on: DispatchQueue.default)
                .share(replay: 1)
                .eraseToAnyPublisher()
            super.init()

            hook.add(
                .init(
                    eventsOfInterest: [.keyUp, .keyDown, .otherMouseUp, .otherMouseDown],
                    convert: { [weak self] _, type, event -> CGEventManipulation.Result in
                        guard let self = self else { return .unchange }
                        return DispatchQueue.default.sync {
                            switch type {
                            case .keyUp,
                                 .keyDown:
                                return self.handleKeys(type: type, event: event)
                            case .otherMouseUp,
                                 .otherMouseDown:
                                return self.handleMouseButton(type: type, event: event)
                            default:
                                return .unchange
                            }
                        }
                    }
                ),
                forKey: key
            )
        }
    }
}

extension GestureRecognizers.Tap: Cancellable {
    func cancel() {
        state = State()
    }
}

extension GestureRecognizers.Tap {
    private func handleKeys(
        type: CGEventType,
        event: CGEvent
    ) -> CGEventManipulation.Result {
        guard let combination = keyCombination else { return .unchange }
        let code = event[.keyboardEventKeycode]
        let activator = combination.activator
        guard case let .key(target) = activator,
              code == target,
              combination.matchesFlags(event.flags)
        else { return .unchange }

        resetStateIfNeeded()

        switch type {
        case .keyDown:
            guard !state.isDown else { return shouldDiscardEvent ? .discarded : .unchange }
            down(code: code)
            state.isDown = true
            return shouldDiscardEvent ? .discarded : .unchange
        case .keyUp:
            up(code: code)
            state.isDown = false
            return shouldDiscardEvent ? .discarded : .unchange
        default: return .unchange
        }
    }

    private func handleMouseButton(
        type: CGEventType,
        event: CGEvent
    ) -> CGEventManipulation.Result {
        guard let combination = keyCombination else { return .unchange }
        let code = event[.mouseEventButtonNumber]
        let activator = combination.activator
        guard case let .mouse(target) = activator, target == code else { return .unchange }

        resetStateIfNeeded()

        switch type {
        case .otherMouseDown:
            guard combination.matchesFlags(event.flags) else { return .unchange }
            down(code: code)
            return shouldDiscardEvent ? .discarded : .unchange
        case .otherMouseUp:
            up(code: code)
            return shouldDiscardEvent ? .discarded : .unchange
        default: return .unchange
        }
    }

    private var duration: TimeInterval { Double(numberOfTapsRequired) * 0.2 + 0.1 }

    private func resetStateIfNeeded() {
        if Date().timeIntervalSince1970 - state.lastButtonUpTimestamp >= duration {
            state = State()
        }
    }

    private func down(code: Int64) {
        state.holdingDownMouseButtons.insert(code)
        if state.tapCount == 0 {
            state.lastButtonUpTimestamp = Date().timeIntervalSince1970
        }
    }

    private func up(code: Int64) {
        state.holdingDownMouseButtons.remove(code)
        if Date().timeIntervalSince1970 - state.lastButtonUpTimestamp < duration {
            if state.tapCount == numberOfTapsRequired - 1 {
                delayedEvent = .init(block: { [weak self] in
                    guard let self = self else { return }
                    self.subject.send(())
                    self.state = State()
                })
                DispatchQueue.default.asyncAfter(
                    deadline: .now() + .milliseconds(tapGestureDelayInMilliSeconds()),
                    execute: delayedEvent!
                )
            } else if state.tapCount > numberOfTapsRequired - 1 {
                delayedEvent?.cancel()
            }
            state.tapCount += 1
        } else {
            state = State()
        }
    }
}
