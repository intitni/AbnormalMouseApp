import CGEventOverride
import Combine
import Foundation

extension GestureRecognizers {
    final class TapHold: GestureRecognizer {
        private struct Key: Hashable {}

        var keyCombination: KeyCombination? { didSet { state = State() } }
        var numberOfTapsRequired: Int = 1 { didSet { state = State() } }
        private(set) lazy var publisher: AnyPublisher<Bool, Never> = $isHolding
            .receive(on: DispatchQueue.default)
            .share(replay: 1)
            .eraseToAnyPublisher()

        struct State {
            var lastButtonDownTimestamp = 0 as TimeInterval
            var tapCount = 0
            var holdingDownKeys = Set<Int64>()
            var holdingDownMouseButtons = Set<Int64>()
        }

        private let hook: CGEventHookType
        /// Track to prevent keyDown events to repeat
        private var isDown = false
        @Published private var isHolding: Bool = false

        private(set) var state = State()
        private let key: AnyHashable

        deinit {
            hook.removeManipulation(forKey: key)
        }

        init(hook: CGEventHookType, key: AnyHashable) {
            self.key = key
            self.hook = hook
            super.init()

            hook.add(
                .init(
                    eventsOfInterest: [.keyUp, .keyDown, .otherMouseUp, .otherMouseDown,
                                       .leftMouseUp, .leftMouseDown, .rightMouseUp,
                                       .rightMouseDown],
                    convert: { [weak self] _, type, event -> CGEventManipulation.Result in
                        guard let self = self else { return .unchange }
                        return DispatchQueue.default.sync {
                            switch type {
                            case .keyUp,
                                 .keyDown:
                                return self.handleKeys(type: type, event: event)
                            case .otherMouseUp,
                                 .otherMouseDown,
                                 .leftMouseUp,
                                 .leftMouseDown,
                                 .rightMouseUp,
                                 .rightMouseDown:
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

        func consume() {
            state = State()
        }
    }
}

extension GestureRecognizers.TapHold: Cancellable {
    func cancel() {
        guard isHolding else { return }
        state = State()
        isHolding = false
    }
}

extension GestureRecognizers.TapHold {
    private var duration: TimeInterval { Double(numberOfTapsRequired - 1) * 0.3 }

    private func handleKeys(
        type: CGEventType,
        event: CGEvent
    ) -> CGEventManipulation.Result {
        guard let combination = keyCombination else { return .unchange }
        let code = event[.keyboardEventKeycode]
        let activator = combination.activator
        guard case let .key(target) = activator, code == target else { return .unchange }

        resetStateIfNeeded()

        switch type {
        case .keyDown:
            guard combination.matchesFlags(event.flags) else { return .unchange }
            guard !isDown else { return shouldDiscardEvent ? .discarded : .unchange }
            down(code: code)
            isDown = true
            return shouldDiscardEvent ? .discarded : .unchange
        case .keyUp:
            guard isDown else { return .unchange }
            up(code: code)
            isDown = false
            return shouldDiscardEvent ? .discarded : .unchange
        default: return .unchange
        }
    }

    private func handleMouseButton(
        type: CGEventType,
        event: CGEvent
    ) -> CGEventManipulation.Result {
        guard let combination = keyCombination else { return .unchange }
        let activator = combination.activator
        let code = event[.mouseEventButtonNumber]
        guard case let .mouse(target) = activator, code == target else { return .unchange }

        resetStateIfNeeded()

        switch type {
        case .otherMouseDown, .leftMouseDown, .rightMouseDown:
            guard combination.matchesFlags(event.flags) else { return .unchange }
            guard !isDown else { return shouldDiscardEvent ? .discarded : .unchange }
            down(code: code)
            isDown = true
            return shouldDiscardEvent ? .discarded : .unchange
        case .otherMouseUp, .leftMouseUp, .rightMouseUp:
            guard isDown else { return .unchange }
            up(code: code)
            isDown = false
            return shouldDiscardEvent ? .discarded : .unchange
        default:
            return .unchange
        }
    }

    private func resetStateIfNeeded() {
        if Date().timeIntervalSince1970 - state.lastButtonDownTimestamp >= duration + 0.2 {
            state.tapCount = 0
        }
    }

    private func down(code: Int64) {
        state.holdingDownMouseButtons.insert(code)
        if state.tapCount == 0 {
            state.lastButtonDownTimestamp = Date().timeIntervalSince1970
        }
        state.tapCount += 1
        if state.tapCount == numberOfTapsRequired {
            cancelOtherGestures { $0 is GestureRecognizers.TapHold }
            isHolding = true
        } else {
            isHolding = false
        }
    }

    private func up(code: Int64) {
        state.holdingDownMouseButtons.remove(code)
        isHolding = false

        let now = Date().timeIntervalSince1970
        if now - state.lastButtonDownTimestamp >= max(duration, 0.3) {
            state.tapCount = 0
        }
    }
}
