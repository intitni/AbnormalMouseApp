import CGEventOverride
import Combine
import Foundation

final class TapGestureRecognizer {
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

    deinit {
        hook.removeManipulation(forKey: key)
    }

    init(hook: CGEventHookType, key: AnyHashable) {
        self.key = key
        self.hook = hook
        subject = .init()
        publisher = subject
            .receive(on: DispatchQueue.main)
            .share(replay: 1)
            .eraseToAnyPublisher()

        hook.add(
            .init(
                eventsOfInterest: [.keyUp, .keyDown, .otherMouseUp, .otherMouseDown],
                convert: { [weak self] _, type, event -> CGEventManipulation.Result in
                    guard let self = self else { return .unchange }
                    switch type {
                    case .keyUp, .keyDown:
                        return self.handleKeys(type: type, event: event)
                    case .otherMouseUp, .otherMouseDown:
                        return self.handleMouseButton(type: type, event: event)
                    default:
                        return .unchange
                    }
                }
            ),
            forKey: key
        )
    }
}

extension TapGestureRecognizer {
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

        fix()
        
        switch type {
        case .keyDown:
            guard !state.isDown else { return .discarded }
            down(code: code)
            state.isDown = true
            return .discarded
        case .keyUp:
            up(code: code)
            state.isDown = false
            return .discarded
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

        fix()
        
        switch type {
        case .otherMouseDown:
            down(code: code)
            return .discarded
        case .otherMouseUp:
            up(code: code)
            return .discarded
        default: return .unchange
        }
    }
    
    private var duration: TimeInterval { Double(numberOfTapsRequired) * 0.3 }
    
    private func fix() {
        if Date().timeIntervalSince1970 - state.lastButtonUpTimestamp >= duration {
            state.tapCount = 0
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
            if state.tapCount == numberOfTapsRequired {
                subject.send(())
                state.lastButtonUpTimestamp = 0
                state.tapCount = 0
            } else if state.tapCount > numberOfTapsRequired {
                state.lastButtonUpTimestamp = 0
                state.tapCount = 0
            } else {
                state.tapCount += 1
            }
        } else {
            state.lastButtonUpTimestamp = 0
            state.tapCount = 0
        }
    }
}
