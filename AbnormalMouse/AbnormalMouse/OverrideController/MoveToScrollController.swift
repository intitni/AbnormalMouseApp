import AppKit
import CGEventOverride
import Combine
import Foundation

/// Provides conversion from mouse movement to 2-finger trackpad scroll.
/// This converter provides not only 4-way scrolling, but also supports over-scroll and 2-finger
/// swipe gesture.
final class MoveToScrollController: OverrideController {
    struct State {
        enum EventPosterState {
            /// The scroll and gesture are not yet running.
            case inactive
            /// Scroll should begin, but gesture is idle.
            case scrollShouldBegin
            /// Scroll has begun, but gesture is idle.
            case scrollHasBegun
            /// Gesture is about to begin, it will reset the current scroll events.
            case gestureShouldBegin
            /// Gesture is restarting scroll events.
            case gestureRestartingScroll
            /// Gesture has begun, scroll has been restarted.
            case gestureHasBegun
            /// Both gesture and scoll should end.
            case everythingShouldEnd
        }

        var eventPosterState: EventPosterState = .inactive
        var mouseLocation = CGPoint.zero
        var scrollSpeedMultiplier: CGFloat = 0
        var swipeSpeedMultiplier: CGFloat = 0
        var isInertiaEffectEnabled = false
    }

    private let persisted: Readonly<Persisted.MoveToScroll>
    private let hook: CGEventHookType
    private let eventPoster = EmulateEventPoster(type: EventSequenceKey())
    private var state = State()
    private let doubleTap: GestureRecognizers.Tap
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
        persisted: Readonly<Persisted.MoveToScroll>,
        hook: CGEventHookType
    ) {
        self.persisted = persisted
        self.hook = hook
        doubleTap = GestureRecognizers.Tap(
            hook: hook,
            key: DoubleTapKey(),
            tapGestureDelayInMilliSeconds: { 0 }
        )
        doubleTap.numberOfTapsRequired = 2
        tapHold = GestureRecognizers.TapHold(hook: hook, key: HookKeyKey())
        mouseMovement = GestureRecognizers.MouseMovement(hook: hook, key: HookMouseKey())

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

        doubleTap.publisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard let app = NSWorkspace.shared.frontmostApplication else { return }
                self.tapHold.cancel()
                let heightOfWindow = getWindowBounds(ofPid: app.processIdentifier).size.height
                self.eventPoster.postSmoothScroll(v: Double(heightOfWindow / 2))
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateSettings() }
            .store(in: &cancellables)
    }

    private func updateSettings() {
        state.scrollSpeedMultiplier = CGFloat(persisted.scrollSpeedMultiplier)
        state.isInertiaEffectEnabled = persisted.isInertiaEffectEnabled
        state.swipeSpeedMultiplier = CGFloat(persisted.swipeSpeedMultiplier)
        doubleTap.keyCombination = persisted.keyCombination
        tapHold.keyCombination = persisted.keyCombination
    }
}

extension MoveToScrollController {
    private func interceptMouse(translation: CGSize) {
        let p = eventPoster
        let v = min(Int(translation.height * state.scrollSpeedMultiplier), 200)
        let h = min(Int(translation.width * state.scrollSpeedMultiplier), 200)
        let sh = h

        /// 2020-7-29 a few things have change to tweak experience, but it may conflict to some
        /// decisions I made in the past. So I am keeping the structure here temporarily.
        ///
        /// 1. scroll gesture event now begins at the very begining.
        /// 2. no more scroll event cancellation and restart at stage `.gestureShouldBegin`
        ///    and `.gestureRestartingScroll`.
        /// 3. scroll and gesture now begins at stage `.scrollHasBegun`, and this stage is guarded
        ///    to enter only after mouse movement is detected. see `Tool.advanceState`.
        ///
        /// These changes should make swipe gestures more natural, and allow it to work in
        /// App Store.app. But swipe gestures can no longer happens at any time during scrolling.
        /// However, swipe gesture can now happen anytime after activator is pressed, which is what
        /// we were trying to achieve.
        func postEvents() {
            switch state.eventPosterState {
            case .inactive:
                break
            case .scrollShouldBegin:
                tapHold.consume()
                p.postScroll(v: v, h: h, phase: .mayBegin)
            case .scrollHasBegun:
                p.postEventPerFrame([])
                p.postScrollGesture(phase: .began)
                p.postScroll(v: v, h: h, phase: .began)
            case .gestureShouldBegin:
                p.postScroll(v: v, h: h, phase: .changed)
            case .gestureRestartingScroll:
                p.postScrollGesture(v: v, h: h, sh: sh, phase: .changed)
            case .gestureHasBegun:
                p.postScroll(v: v, h: h, phase: .changed)
                p.postScrollGesture(v: v, h: h, sh: sh, phase: .changed)

            /// To change the implementaion of this state, one should test that
            ///
            /// 1. Safari scroll, overscroll, inertia effect works properly.
            /// 2. Xcode scroll, overscroll, inertia effect works properly.
            /// 3. Reeder.app scroll, overscroll, inertia effect works properly.
            /// 4. Reeder.app horizontal pan works properly.
            /// 5. Swish.app works properly
            /// 5. Swish.app works properly.
            /// 6. LaunchPad horizontal pan works properly.
            ///
            /// Currently a scroll-event-strategy is used because it's the only way to make
            /// Reeder.app happy.
            ///
            /// - important: A momentum-event-based inertia effect was used. please make sure to
            ///              double check this block of code to make sure it still works, if
            ///              `postInertiaEffect` is changed!!! __2020-7-21__
            case .everythingShouldEnd:
                // Cancel because Reeder.app will not have inertia effect
                p.postScroll(phase: .cancelled)
                p.postScrollGesture(v: v, h: h, sh: sh, phase: .ended)
                p.postNullGesture()
                if state.isInertiaEffectEnabled {
                    p.postInertiaEffect(v: Double(v), h: Double(h))
                } else {
                    // Inertia effect will make Reeder end it's gesture recognizers, when
                    // inertia effect is off, we have to end it manually.
                    p.postScroll(phase: .ended)
                }
            }
        }

        Tool.advanceState(&state.eventPosterState, isActive: isActive, h: h, v: v)
        defer { Tool.resetStateIfNeeded(&state.eventPosterState) }
        postEvents()
        
        CGWarpMouseCursorPosition(state.mouseLocation)
    }
}

extension MoveToScrollController {
    enum Tool {
        static func advanceState(
            _ state: inout State.EventPosterState,
            isActive: Bool,
            h: Int,
            v: Int
        ) {
            func endIfNeeded() { if !isActive { state = .everythingShouldEnd } }
            switch state {
            case .inactive:
                if isActive { state = .scrollShouldBegin }
            case .scrollShouldBegin:
                if abs(h) > 5 { state = .scrollHasBegun }
                else if abs(v) > 5 { state = .scrollHasBegun }
                endIfNeeded()
            case .scrollHasBegun:
                state = .gestureShouldBegin
                endIfNeeded()
            case .gestureShouldBegin:
                state = .gestureRestartingScroll
                endIfNeeded()
            case .gestureRestartingScroll:
                state = .gestureHasBegun
                endIfNeeded()
            case .gestureHasBegun:
                endIfNeeded()
            case .everythingShouldEnd:
                state = .inactive
            }
        }

        static func resetStateIfNeeded(_ state: inout State.EventPosterState) {
            if state == .everythingShouldEnd {
                state = .inactive
            }
        }
    }
}

func getWindowBounds(ofPid pid: pid_t) -> CGRect {
    let options = CGWindowListOption(
        arrayLiteral: CGWindowListOption.excludeDesktopElements,
        CGWindowListOption.optionOnScreenOnly
    )
    let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
    guard let infoList = windowListInfo as NSArray? as? [[String: AnyObject]] else { return .zero }
    if let window = infoList.first(where: { ($0["kCGWindowOwnerPID"] as? pid_t) == pid }),
        let bounds = window["kCGWindowBounds"] {
        func extract(_ v: Any??) -> CGFloat {
            guard let number = v as? NSNumber else { return 0 }
            return CGFloat(number.doubleValue)
        }
        let x = extract(bounds["X"])
        let y = extract(bounds["Y"])
        let height = extract(bounds["Height"])
        let width = extract(bounds["Width"])
        return .init(x: x, y: y, width: width, height: height)
    }
    return .zero
}
