import CGEventOverride
import Combine
import Foundation

final class DockSwipeController: OverrideController {
    struct State {
        enum EventPosterState {
            case inactive
            case shouldBegin
            case begin
            case changed
            case shouldEnd
        }
        
        var eventPosterState = EventPosterState.inactive
        var mouseLocation = CGPoint.zero
    }

    enum Keys: Hashable {
        case key
        case mouse
        case hook
        case eventSequence
    }

    private let persisted: Readonly<Persisted.DockSwipe>
    private let hook: CGEventHookType
    private var state = State()
    private let eventPoster = EmulateEventPoster(type: Keys.eventSequence)
    private let tapHold: GestureRecognizers.TapHold
    private let mouseMovement: GestureRecognizers.MouseMovement
    private var cancellables = Set<AnyCancellable>()
    private var isActive: Bool {
        get { mouseMovement.isActive }
        set { mouseMovement.isActive = newValue }
    }

    deinit {
        hook.removeManipulation(forKey: Keys.mouse)
        hook.removeManipulation(forKey: Keys.key)
    }

    init(
        persisted: Readonly<Persisted.DockSwipe>,
        hook: CGEventHookType
    ) {
        self.persisted = persisted
        self.hook = hook

        tapHold = GestureRecognizers.TapHold(hook: hook, key: Keys.key)
        mouseMovement = GestureRecognizers.MouseMovement(hook: hook, key: Keys.mouse)

        updateSettings()

        mouseMovement.publisher
            .sink(receiveValue: { [weak self] p in
                self?.handleMouseMovement(translation: p.0)
            })
            .store(in: &cancellables)

        tapHold.publisher
            .removeDuplicates()
            .sink(receiveValue: { [weak self] isActive in
                self?.isActive = isActive
                if isActive {
                    let event = CGEvent(source: nil)
                    self?.state.mouseLocation = event?.location ?? .zero
                }
            })
            .store(in: &cancellables)
    }

    private func updateSettings() {}
}

extension DockSwipeController {
    private func handleMouseMovement(translation: CGSize) {
        let p = eventPoster
        let v = Int(translation.height)
        let h = Int(translation.width)
        
        func postEvents() {
            switch state.eventPosterState {
            case .inactive:
                break
            case .shouldBegin:
                break
            case .begin:
                tapHold.consume()
                p.postDockSwipe(v: v, h: h)
            case .changed:
                p.postDockSwipe(v: v, h: h)
            case .shouldEnd:
                break
            }
        }
        
        CGWarpMouseCursorPosition(state.mouseLocation)
        
        Tool.advanceState(&state.eventPosterState, isActive: isActive, h: h, v: v)
        defer { Tool.resetStateIfNeeded(&state.eventPosterState) }
        postEvents()
    }
}

extension DockSwipeController {
    enum Tool {
        static func advanceState(
            _ state: inout State.EventPosterState,
            isActive: Bool,
            h: Int,
            v: Int
        ) {
            func endIfNeeded() { if !isActive { state = .shouldEnd } }
            
            switch state {
            case .inactive:
                if abs(h) > 5 || abs(v) > 5 {
                    state = .shouldBegin
                }
            case .shouldBegin:
                state = .begin
                endIfNeeded()
            case .begin:
                state = .changed
                endIfNeeded()
            case .changed:
                endIfNeeded()
            case .shouldEnd:
                break
            }
        }
        
        static func resetStateIfNeeded(_ state: inout State.EventPosterState) {
            if state == .shouldEnd {
                state = .inactive
            }
        }
    }
}
