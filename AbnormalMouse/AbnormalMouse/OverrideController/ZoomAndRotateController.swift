import CGEventOverride
import Combine
import Foundation

final class ZoomAndRotateController: OverrideController {
    struct State {
        enum EventPosterState: Equatable {
            enum EventType: Equatable {
                case zoom
                case rotate
            }

            /// Gesture is not yet started.
            case inactive
            /// Gesture may starts.
            case mayBegin
            /// Gesture starts
            case begin(EventType)
            /// Gesture changes.
            case hasBegun(EventType)
            /// Gesture ends.
            case shouldEnd(EventType?)
        }

        var gestureState = EventPosterState.inactive
        var mouseLocation = CGPoint.zero

        var zoomGestureDirection: MoveMouseDirection = .none
        var rotateGestureDirection: MoveMouseDirection = .none
        
        var zoomThreshold = 0
        var rotateThreshold = 0
    }

    private let persisted: Readonly<Persisted.ZoomAndRotate>
    private let hook: CGEventHookType
    private let eventPoster = EmulateEventPoster(type: EventSequenceKey())
    private var state = State()
    private let tap: GestureRecognizers.Tap
    private let tapHold: GestureRecognizers.TapHold
    private let mouseMovement: GestureRecognizers.MouseMovement
    private var cancellables = Set<AnyCancellable>()
    private var isActive: Bool {
        get { mouseMovement.isActive }
        set { mouseMovement.isActive = newValue }
    }

    private struct DoubleTapKey: Hashable {}
    private struct HookMouseKey: Hashable {}
    private struct HookKeyKey: Hashable {}
    private struct EventSequenceKey: Hashable {}

    deinit {
        hook.removeManipulation(forKey: HookMouseKey())
        hook.removeManipulation(forKey: HookKeyKey())
    }

    init(
        persisted: Readonly<Persisted.ZoomAndRotate>,
        hook: CGEventHookType
    ) {
        self.persisted = persisted
        self.hook = hook
        tap = GestureRecognizers.Tap(
            hook: hook,
            key: DoubleTapKey(),
            tapGestureDelayInMilliSeconds: { 0 }
        )
        tapHold = GestureRecognizers.TapHold(hook: hook, key: HookKeyKey())
        mouseMovement = GestureRecognizers.MouseMovement(hook: hook, key: HookMouseKey())
        mouseMovement.rate = 60

        updateSettings()

        mouseMovement.publisher
            .sink { [weak self] p in
                self?.interceptMouse(translation: p.0)
            }
            .store(in: &cancellables)

        tapHold.publisher
            .removeDuplicates()
            .sink { [weak self] isActive in
                self?.isActive = isActive
                if isActive {
                    let event = CGEvent(source: nil)
                    self?.state.mouseLocation = event?.location ?? .zero
                }
            }
            .store(in: &cancellables)

        tap.publisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.eventPoster.postSmartZoom()
                self.tapHold.cancel()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateSettings() }
            .store(in: &cancellables)
    }

    private func updateSettings() {
        state.zoomGestureDirection = persisted.zoomGestureDirection
        state.rotateGestureDirection = persisted.rotateGestureDirection
        tapHold.keyCombination = persisted.keyCombination
        if persisted.smartZoom.useZoomAndRotateDoubleTap {
            tap.numberOfTapsRequired = 2
            tap.keyCombination = persisted.keyCombination
        } else {
            tap.numberOfTapsRequired = 1
            tap.keyCombination = persisted.smartZoom.keyCombination
        }
    }
}

// MARK: - Mouse

extension ZoomAndRotateController {
    private func interceptMouse(translation: CGSize) {
        let p = eventPoster
        let v = Int(translation.height)
        let h = Int(translation.width)
        func extractValue(direction: MoveMouseDirection) -> Int {
            switch direction {
            case .none: return 0
            case .left: return -h
            case .right: return h
            case .up: return -v
            case .down: return v
            }
        }
        let zoom = extractValue(direction: state.zoomGestureDirection) * 3
        let rotate = extractValue(direction: state.rotateGestureDirection)
        
        Tool.advanceState(
            &state.gestureState,
            isActive: isActive,
            zoomThreshold: state.zoomThreshold,
            rotateThreshold: state.rotateThreshold
        )
        defer { Tool.resetStateIfNeeded(&state.gestureState) }

        let zoomDirection: ZoomDirection = zoom == 0
            ? .none
            : (zoom > 0 ? .expand : .contract)
        let rotateDirection: RotateDirection = rotate == 0
            ? .none
            : (rotate < 0 ? .clockwise : .counterClockwise)

        switch state.gestureState {
        case .inactive:
            break
        case .mayBegin:
            state.zoomThreshold += abs(zoom)
            state.rotateThreshold += abs(rotate)
            break
        case let .begin(type):
            tapHold.consume()
            switch type {
            case .zoom:
                p.postZoom(direction: zoomDirection, t: zoom, phase: .began)
            case .rotate:
                p.postRotation(direction: rotateDirection, phase: .began)
            }
            p.postTranslation(phase: .began)
        case let .hasBegun(type):
            switch type {
            case .zoom:
                p.postZoom(direction: zoomDirection, t: zoom, phase: .changed)
            case .rotate:
                p.postRotation(direction: rotateDirection, phase: .changed)
            }
            p.postTranslation(phase: .changed)
        case let .shouldEnd(type):
            switch type {
            case .zoom:
                p.postZoom(direction: .none, t: zoom, phase: .ended)
            case .rotate:
                p.postRotation(direction: .none, phase: .ended)
            default: break
            }
            p.postTranslation(phase: .ended)
            state.zoomThreshold = 0
            state.rotateThreshold = 0
        }

        if isActive {
            CGWarpMouseCursorPosition(state.mouseLocation)
        }
    }
}

// MARK: - Tool

extension ZoomAndRotateController {
    enum Tool {
        static func advanceState(
            _ state: inout State.EventPosterState,
            isActive: Bool,
            zoomThreshold: Int,
            rotateThreshold: Int
        ) {
            func endIfNeeded(_ type: State.EventPosterState.EventType?) {
                if !isActive { state = .shouldEnd(type) }
            }
            switch state {
            case .inactive:
                guard isActive else { return }
                state = .mayBegin
            case .mayBegin:
                if abs(zoomThreshold) > 40 {
                    state = .begin(.zoom)
                } else if abs(rotateThreshold) > 40 {
                    state = .begin(.rotate)
                }
                endIfNeeded(nil)
            case let .begin(type):
                state = .hasBegun(type)
                endIfNeeded(type)
            case let .hasBegun(type):
                endIfNeeded(type)
            case .shouldEnd:
                break
            }
        }

        static func resetStateIfNeeded(_ state: inout State.EventPosterState) {
            if case .shouldEnd = state { state = .inactive }
        }
    }
}
