import CGEventOverride
import Combine
import Foundation

final class ZoomAndRotateController: BaseOverrideController, OverrideController {
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
        var zoomSpeedMultiplier: Double = 1
        var rotateSpeedMultiplier: Double = 1

        var zoomThreshold: Double = 0
        var rotateThreshold: Double = 0
    }

    private let persisted: Readonly<Persisted.ZoomAndRotate>
    private let hook: CGEventHookType
    private let eventPoster = EmulateEventPoster(type: EventSequenceKey())
    private var state = State()
    private let tap: GestureRecognizers.Tap
    private let tapHold: GestureRecognizers.TapHold
    private let mouseMovement: GestureRecognizers.MouseMovement
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
        sharedPersisted: Readonly<Persisted.Advanced>,
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

        super.init(sharedPersisted: sharedPersisted)

        updateSettings()

        mouseMovement.publisher
            .sink { [weak self] p in
                guard let self = self, !self.isDisabled else { return }
                self.interceptMouse(translation: p.0)
            }
            .store(in: &cancellables)

        tapHold.publisher
            .removeDuplicates()
            .sink { [weak self] isActive in
                guard let self = self, !self.isDisabled else { return }
                self.isActive = isActive
                if isActive {
                    let event = CGEvent(source: nil)
                    self.state.mouseLocation = event?.location ?? .zero
                }
            }
            .store(in: &cancellables)

        tap.publisher
            .sink { [weak self] _ in
                guard let self = self, !self.isDisabled else { return }
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
        isActive = false
        state.zoomGestureDirection = persisted.zoomGestureDirection
        state.rotateGestureDirection = persisted.rotateGestureDirection
        state.zoomSpeedMultiplier = persisted.zoomSpeedMultiplier
        state.rotateSpeedMultiplier = persisted.rotateSpeedMultiplier
        tapHold.keyCombination = persisted.keyCombination?.validated
        tapHold.numberOfTapsRequired = persisted.numberOfTapsRequired
        if persisted.smartZoom.useZoomAndRotateDoubleTap {
            tap.numberOfTapsRequired = persisted.numberOfTapsRequired + 1
            tap.keyCombination = persisted.keyCombination?.validated
        } else {
            tap.numberOfTapsRequired = persisted.smartZoom.numberOfTapsRequired
            tap.keyCombination = persisted.smartZoom.keyCombination?.validated
        }
    }
}

// MARK: - Mouse

extension ZoomAndRotateController {
    private func interceptMouse(translation: CGSize) {
        let p = eventPoster
        let v = translation.height
        let h = translation.width
        func extractValue(direction: MoveMouseDirection) -> Double {
            switch direction {
            case .none: return 0
            case .left: return -h
            case .right: return h
            case .up: return -v
            case .down: return v
            }
        }
        let zoom = extractValue(direction: state.zoomGestureDirection)
        let rotate = extractValue(direction: state.rotateGestureDirection)

        Tool.advanceState(
            &state.gestureState,
            isActive: isActive,
            zoomThreshold: state.zoomThreshold,
            rotateThreshold: state.rotateThreshold
        )
        defer { Tool.resetStateIfNeeded(&state.gestureState) }

        switch state.gestureState {
        case .inactive:
            break
        case .mayBegin:
            state.zoomThreshold += abs(zoom) > abs(rotate) ? abs(zoom) : 0
            state.rotateThreshold += abs(rotate) > abs(zoom) ? abs(rotate) : 0
            CGWarpMouseCursorPosition(state.mouseLocation)
        case let .begin(type):
            tapHold.consume()
            switch type {
            case .zoom:
                p.postZoom(t: zoom * state.zoomSpeedMultiplier, phase: .began)
            case .rotate:
                p.postRotation(t: rotate * state.rotateSpeedMultiplier, phase: .began)
            }
            p.postTranslation(phase: .began)
            CGWarpMouseCursorPosition(state.mouseLocation)
        case let .hasBegun(type):
            switch type {
            case .zoom:
                p.postZoom(t: zoom * state.zoomSpeedMultiplier, phase: .changed)
            case .rotate:
                p.postRotation(t: rotate * state.rotateSpeedMultiplier, phase: .changed)
            }
            p.postTranslation(phase: .changed)
            CGWarpMouseCursorPosition(state.mouseLocation)
        case let .shouldEnd(type):
            switch type {
            case .zoom:
                p.postZoom(t: zoom * state.zoomSpeedMultiplier, phase: .ended)
            case .rotate:
                p.postRotation(t: rotate * state.rotateSpeedMultiplier, phase: .ended)
            case .none: break
            }
            p.postTranslation(phase: .ended)
            state.zoomThreshold = 0
            state.rotateThreshold = 0
        }
    }
}

// MARK: - Tool

extension ZoomAndRotateController {
    enum Tool {
        static func advanceState(
            _ state: inout State.EventPosterState,
            isActive: Bool,
            zoomThreshold: Double,
            rotateThreshold: Double
        ) {
            func endIfNeeded(_ type: State.EventPosterState.EventType?) {
                if !isActive { state = .shouldEnd(type) }
            }
            switch state {
            case .inactive:
                guard isActive else { return }
                state = .mayBegin
            case .mayBegin:
                let absZoom = abs(zoomThreshold)
                let absRotate = abs(rotateThreshold)
                if absZoom > 40 || absRotate > 40 {
                    if absZoom >= absRotate {
                        state = .begin(.zoom)
                    } else {
                        state = .begin(.rotate)
                    }
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
