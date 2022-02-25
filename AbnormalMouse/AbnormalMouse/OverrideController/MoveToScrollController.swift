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
            /// Can start to send scroll events.
            case scrollCanChange
            /// Can start to send gesture events.
            case gestureHasBegun
            /// Both gesture and scoll should end.
            case everythingShouldEnd
        }

        var eventPosterState: EventPosterState = .inactive
        var mouseLocation = CGPoint.zero
        var scrollSpeedMultiplier: CGFloat = 0
        var swipeSpeedMultiplier: CGFloat = 0
        var isInertiaEffectEnabled = false
        var didPostMayBegin = false
    }

    private let persisted: Readonly<Persisted.MoveToScroll>
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
        persisted: Readonly<Persisted.MoveToScroll>,
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
        isActive = false
        state.scrollSpeedMultiplier = CGFloat(persisted.scrollSpeedMultiplier)
        state.isInertiaEffectEnabled = persisted.isInertiaEffectEnabled
        state.swipeSpeedMultiplier = CGFloat(persisted.swipeSpeedMultiplier)
        tapHold.keyCombination = persisted.keyCombination?.validated
        tapHold.numberOfTapsRequired = persisted.numberOfTapsRequired

        if persisted.halfPageScroll.useMoveToScrollDoubleTap {
            tap.numberOfTapsRequired = persisted.numberOfTapsRequired + 1
            tap.keyCombination = persisted.keyCombination?.validated
        } else {
            tap.numberOfTapsRequired = persisted.halfPageScroll.numberOfTapsRequired
            tap.keyCombination = persisted.halfPageScroll.keyCombination?.validated
        }
    }
}

extension MoveToScrollController {
    private func interceptMouse(translation: CGSize) {
        let p = eventPoster
        let v = min(Int(translation.height * state.scrollSpeedMultiplier), 200)
        let h = min(Int(translation.width * state.scrollSpeedMultiplier), 200)
        let sh = h

        func postEvents() {
            switch state.eventPosterState {
            case .inactive:
                break
            case .scrollShouldBegin:
                tapHold.consume()
                if !state.didPostMayBegin {
                    p.postScroll(phase: .mayBegin)
                    p.postNullGesture()
                    state.didPostMayBegin = true
                }
                CGWarpMouseCursorPosition(state.mouseLocation)
            case .scrollHasBegun:
                p.postEventPerFrame([])
                p.postScrollGesture(phase: .began)
                p.postScroll(v: v, h: h, phase: .began)
                p.postNullGesture()
                CGWarpMouseCursorPosition(state.mouseLocation)
            case .scrollCanChange:
                p.postScroll(v: v, h: h, phase: .changed)
                p.postNullGesture()
                CGWarpMouseCursorPosition(state.mouseLocation)
            case .gestureHasBegun:
                p.postScroll(v: v, h: h, phase: .changed)
                p.postScrollGesture(v: v, h: h, sh: sh, phase: .changed)
                p.postNullGesture()
                CGWarpMouseCursorPosition(state.mouseLocation)

            /// To change the implementaion of this state, one should test that
            ///
            /// 1. Safari scroll, overscroll, inertia effect works properly.
            /// 2. Xcode scroll, overscroll, inertia effect works properly.
            /// 3. Reeder.app scroll, overscroll, inertia effect works properly.
            /// 4. Reeder.app horizontal pan works properly.
            /// 5. Swish.app works properly
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
                p.postScroll(v: v, h: h, phase: .changed)
                p.postScroll(phase: .cancelled)
                p.postScrollGesture(v: v, h: h, sh: sh, phase: .ended)
                p.postNullGesture()
                if state.isInertiaEffectEnabled {
                    p.postInertiaEffect(v: Double(v), h: Double(h))
                } else {
                    // Inertia effect will make Reeder end it's gesture recognizers, when
                    // inertia effect is off, we have to end it manually.
                    p.postScroll(phase: .ended)
                    p.postNullGesture()
                }
            }
        }

        Tool.advanceState(&state, isActive: isActive, h: h, v: v)
        defer { Tool.resetStateIfNeeded(&state) }
        postEvents()
    }
}

extension MoveToScrollController {
    enum Tool {
        static func advanceState(
            _ state: inout State,
            isActive: Bool,
            h: Int,
            v: Int
        ) {
            func endIfNeeded() { if !isActive { state.eventPosterState = .everythingShouldEnd } }
            switch state.eventPosterState {
            case .inactive:
                if isActive { state.eventPosterState = .scrollShouldBegin }
            case .scrollShouldBegin:
                defer { endIfNeeded() }
                guard abs(h) > 5 || abs(v) > 5 else { break }
                state.eventPosterState = .scrollHasBegun
            case .scrollHasBegun:
                state.eventPosterState = .scrollCanChange
                endIfNeeded()
            case .scrollCanChange:
                state.eventPosterState = .gestureHasBegun
                endIfNeeded()
            case .gestureHasBegun:
                endIfNeeded()
            case .everythingShouldEnd:
                state.eventPosterState = .inactive
            }
        }

        static func resetStateIfNeeded(_ state: inout State) {
            if state.eventPosterState == .everythingShouldEnd {
                state.eventPosterState = .inactive
                state.didPostMayBegin = false
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
       let bounds = window["kCGWindowBounds"]
    {
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
