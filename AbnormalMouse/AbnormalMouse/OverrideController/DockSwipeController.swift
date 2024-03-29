import AppKit
import CGEventOverride
import Combine

final class DockSwipeController: BaseOverrideController, OverrideController {
    struct State {
        enum EventPosterState {
            case inactive
            case mayBegin
            case begin(Direction)
            case changed(Direction)
            case shouldEnd(Direction?)

            enum Direction {
                case horizontal
                case vertical
            }
        }

        var eventPosterState = EventPosterState.inactive
        var mouseLocation = CGPoint.zero
        var horizontalAccumulation: Double = 0
        var verticalAccumulation: Double = 0
        let gestureFrame = CGSize(width: 2000, height: 1500)
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
        sharedPersisted: Readonly<Persisted.Advanced>,
        hook: CGEventHookType
    ) {
        self.persisted = persisted
        self.hook = hook

        tapHold = GestureRecognizers.TapHold(hook: hook, key: Keys.key)
        mouseMovement = GestureRecognizers.MouseMovement(hook: hook, key: Keys.mouse)

        super.init(sharedPersisted: sharedPersisted)

        updateSettings()

        mouseMovement.publisher
            .sink(receiveValue: { [weak self] p in
                guard let self = self, !self.isDisabled else { return }
                self.handleMouseMovement(translation: p.0)
            })
            .store(in: &cancellables)

        tapHold.publisher
            .removeDuplicates()
            .sink(receiveValue: { [weak self] isActive in
                guard let self = self, !self.isDisabled else { return }
                self.isActive = isActive
                if isActive {
                    let event = CGEvent(source: nil)
                    self.state.mouseLocation = event?.location ?? .zero
                }
            })
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateSettings() }
            .store(in: &cancellables)
    }

    private func updateSettings() {
        isActive = false
        tapHold.keyCombination = persisted.keyCombination?.validated
        tapHold.numberOfTapsRequired = persisted.numberOfTapsRequired
    }
}

extension DockSwipeController {
    private func handleMouseMovement(translation: CGSize) {
        let p = eventPoster
        let v = translation.height
        let h = translation.width
        state.verticalAccumulation += Double(v)
        state.horizontalAccumulation += Double(h)

        var ra: Double {
            let ph = state.horizontalAccumulation / Double(state.gestureFrame.width)
            return ph
        }

        var ua: Double {
            let pv = state.verticalAccumulation / Double(state.gestureFrame.height)
            return -pv
        }

        func postEvents() {
            switch state.eventPosterState {
            case .inactive:
                break

            case .mayBegin:
                p.postNullGesture()

            case let .begin(direction):
                tapHold.consume()
                switch direction {
                case .horizontal:
                    p.postDockSwipe(direction: .horizontal(rightAccumulation: ra), phase: .began)
                case .vertical:
                    p.postDockSwipe(direction: .vertical(upAccumulation: ua), phase: .began)
                }

            case let .changed(direction):
                switch direction {
                case .horizontal:
                    p.postDockSwipe(direction: .horizontal(rightAccumulation: ra), phase: .changed)
                case .vertical:
                    p.postDockSwipe(direction: .vertical(upAccumulation: ua), phase: .changed)
                }

            case let .shouldEnd(direction):
                switch direction {
                case .horizontal:
                    p.postDockSwipe(direction: .horizontal(rightAccumulation: ra), phase: .ended)
                case .vertical:
                    p.postDockSwipe(direction: .vertical(upAccumulation: ua), phase: .ended)
                case .none: break
                }

                state.horizontalAccumulation = 0
                state.verticalAccumulation = 0
            }
        }

        Tool.advanceState(
            &state.eventPosterState,
            isActive: isActive,
            horizontalAccumulation: state.horizontalAccumulation,
            verticalAccumulation: state.verticalAccumulation
        )
        defer { Tool.resetStateIfNeeded(&state.eventPosterState) }
        postEvents()

        CGWarpMouseCursorPosition(state.mouseLocation)
    }
}

extension DockSwipeController {
    enum Tool {
        static func advanceState(
            _ state: inout State.EventPosterState,
            isActive: Bool,
            horizontalAccumulation: Double,
            verticalAccumulation: Double
        ) {
            func endIfNeeded(_ direction: State.EventPosterState.Direction?) {
                if !isActive { state = .shouldEnd(direction) }
            }

            switch state {
            case .inactive:
                guard isActive else { return }
                state = .mayBegin
            case .mayBegin:
                let absh = abs(horizontalAccumulation)
                let absv = abs(verticalAccumulation)
                if absh > 10 || absv > 10 {
                    if absh >= absv {
                        state = .begin(.horizontal)
                    } else {
                        state = .begin(.vertical)
                    }
                }
                endIfNeeded(nil)
            case let .begin(direction):
                state = .changed(direction)
                endIfNeeded(direction)
            case let .changed(direction):
                endIfNeeded(direction)
            case .shouldEnd:
                break
            }
        }

        static func resetStateIfNeeded(_ state: inout State.EventPosterState) {
            if case .shouldEnd = state {
                state = .inactive
            }
        }
    }
}
