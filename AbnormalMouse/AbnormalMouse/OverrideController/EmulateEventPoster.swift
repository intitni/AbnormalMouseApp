import AppKit
import CGEventOverride
import Foundation
import IOKit

struct EmulateEventPoster {
    let type: AnyHashable

    /// Post a sequence of events per frame.
    /// - Parameter events: All events.
    func postEventPerFrame(_ events: [() -> Void]) {
        EventSequenceController.shared?.scheduleTasks(events, forKey: type)
    }

    /// Post smooth scroll event.
    ///
    /// - Parameters:
    ///   - v: Vertical translation in pixel.
    ///   - h: Horizontal translation in pixel.
    func postSmoothScroll(v: Double = 0, h: Double = 0) {
        func easingFunction(_ x: Double) -> Double {
            x < 0.5
                ? 4 * x * x * x
                : 1 - pow(-2 * x + 2, 3) / 2
        }

        let count = refreshRate / 2
        var scheduledTask = [() -> Void]()
        var previousV: Int = 0
        var previousH: Int = 0
        for i in stride(from: 0, to: count, by: 1) {
            let x = i / count
            let scale = easingFunction(x)
            func scaled(_ k: Double) -> Int { Int(Double(k) * scale) }
            let scaledV = scaled(v)
            let scaledH = scaled(h)
            let sV = scaledV - previousV
            let sH = scaledH - previousH
            previousV = scaledV
            previousH = scaledH
            scheduledTask.append {
                if i == 0 {
                    self.postScroll(v: -sV, h: -sH, isPartOfPan: false)
                } else {
                    self.postScroll(v: -sV, h: -sH, isPartOfPan: false)
                }
            }
        }
        postEventPerFrame(scheduledTask)
    }

    /// Post inertia effect after scrolling.
    ///
    /// Please make sure to double check this function whenever you apply a change on it. Different
    /// apps seems to have different understanding to what a momentum scroll event is.
    ///
    /// - Parameters:
    ///   - v: Vertical translation in pixel.
    ///   - h: Horizontal translation in pixel.
    func postInertiaEffect(v: Double = 0, h: Double = 0) {
        func easingFunction(_ x: Double) -> Double { x * x }

        let count = min(200, max(abs(v), abs(h))) / refreshSpeedScale / 2
        if count <= 0 {
            var scheduledTask = [() -> Void]()
            scheduledTask.append {
                self.postScrollMomentum(phase: .begin)
            }
            scheduledTask.append {
                self.postScrollMomentum(phase: .end)
            }
            postEventPerFrame(scheduledTask)
            return
        }

        var scheduledTask = [() -> Void]()
        for i in stride(from: 0, to: count, by: 1) {
            let x = 1 - i / count
            let scale = easingFunction(x)
            func scaled(_ k: Double) -> Double { Double(k) * scale }
            scheduledTask.append {
                if i == 0 {
                    self.postScrollMomentum(v: scaled(v), h: scaled(h), phase: .begin)
                } else {
                    self.postScrollMomentum(v: scaled(v), h: scaled(h), phase: .continuous)
                }
            }
        }
        scheduledTask.append {
            self.postScrollMomentum(phase: .end)
        }
        postEventPerFrame(scheduledTask)
    }

    /// Post scroll event.
    ///
    /// - Parameters:
    ///   - v: Vertical translation in pixel.
    ///   - h: Horizontal translation in pixel.
    ///   - isPartOfPan: If it's a part of pan gesture.
    ///   - phase: Scroll event phase.
    ///
    /// - Important: when a scroll phase is provided, it is considered tied to a scroll gesture
    ///     event, some apps may ignore it and use values from scroll gestures instead.
    ///     Not sure what `isPartOfPan` does in it.
    func postScroll(
        v: Int = 0,
        h: Int = 0,
        isPartOfPan: Bool = true,
        phase: CGScrollPhase = CGScrollPhase(rawValue: 0)!
    ) {
        let e = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(v),
            wheel2: Int32(h),
            wheel3: 0
        )!
        e[.scrollWheelEventIsContinuous] = 1
        e[.scrollWheelEventScrollPhase] = Int64(phase.rawValue)
        e[101] = 4 // magic
        e[.scrollIsPartOfPan] = isPartOfPan ? 1 : 0
        e.post(tap: .cghidEventTap)
    }

    /// Post inertia effect after scrolling.
    ///
    /// Please make sure to double check this function whenever you apply a change on it. Different
    /// apps seems to have different understanding to what a momentum scroll event is. Please check
    /// the following apps after change:
    /// - Launchpad (horizontal pan)
    /// - Safari
    /// - Reeder
    /// - Xcode
    ///
    /// - Parameters:
    ///   - v: Vertical translation in pixel.
    ///   - h: Horizontal translation in pixel.
    ///   - phase: Momentum event phase.
    func postScrollMomentum(
        v: Double = 0,
        h: Double = 0,
        phase: CGMomentumScrollPhase = CGMomentumScrollPhase.none
    ) {
        let e = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: 0, // 0 to make sure apps like Launchpad to not recognize it as scroll events.
            wheel2: 0,
            wheel3: 0
        )!
        // instead, we set point deltas manually.
        e[.scrollWheelEventPointDeltaAxis1] = Int64(v)
        e[.scrollWheelEventPointDeltaAxis2] = Int64(h)
        e[.scrollWheelEventIsContinuous] = 1
        e[.scrollWheelEventMomentumPhase] = Int64(phase.rawValue)
        e[.scrollIsPartOfPan] = 1
        e.post(tap: .cghidEventTap)
    }

    /// Post a null gesture event.
    func postNullGesture() {
        let e = CGEvent(source: nil)!
        e.type = CGEventType.gesture
        e.post(tap: .cghidEventTap)
    }

    /// Post scroll gesture event.
    ///
    /// - Parameters:
    ///   - v: Vertical translation in pixel.
    ///   - h: Horizontal translation in pixel.
    ///   - sh: Horizontal pan translation in pixel. For example controls swipe back in Safari and
    ///         horizontal page turn in App Store.
    ///   - phase: Gesture phase.
    func postScrollGesture(
        v: Int = 0,
        h: Int = 0,
        sh: Int = 0,
        phase: CGGesturePhase
    ) {
        let e = CGEvent(source: nil)!
        e.type = CGEventType.gesture
        e[.gestureType] = GestureType.scroll.rawValue
        e[.gestureValueX] = Int64(h)
        e[.gestureSwipeValueX] = Int64(sh)
        e[.gestureScrollValueY] = Int64(v)
        e[.gesturePhase] = Int64(phase.rawValue)
        e[135] = 1 // magic
        let mystery: Int64 = {
            if h == 0 { return 0 }
            let maxH: Int64 = 200
            let absH = min(max(0, abs(Int64(sh))), maxH)
            if h < 0 {
                let min: Int64 = 3_220_000_000 // magic
                let d: Int64 = 40_000_000
                return min + d * absH / maxH
            } else {
                let min: Int64 = 1_070_000_000 // magic
                let d: Int64 = 40_000_000
                return min + d * absH / maxH
            }
        }()
        e[.gestureSwipeDirection] = mystery
        e[.gestureZoomDirection] = mystery
        e.post(tap: .cghidEventTap)
    }

    /// Post gesture start event.
    func postGestureStart() {
        let e = CGEvent(source: nil)!
        e.type = CGEventType.gesture
        e[.gestureType] = GestureType.gestureStarted.rawValue
        e.post(tap: .cghidEventTap)
    }

    /// Post gesture end event.
    func postGestureEnd() {
        let e = CGEvent(source: nil)!
        e.type = CGEventType.gesture
        e[.gestureType] = GestureType.gestureEnded.rawValue
        e.post(tap: .cghidEventTap)
    }

    /// Post a gesture between gestureStarted and gestureEnded events.
    func postGesture(_ gesture: () -> Void) {
        postGestureStart()
        defer { postGestureEnd() }
        gesture()
    }

    /// Post a smart zoom gesture.
    func postSmartZoom() {
        postGesture {
            let e = CGEvent(source: nil)!
            e.type = CGEventType.gesture
            e[.gestureType] = GestureType.zoomToggle.rawValue
            e.post(tap: .cghidEventTap)
        }
    }

    /// Post a zoom gesture event.
    /// - Parameters:
    ///   - direction: in which direction the zoom happens
    ///   - t: how much is the zoom
    ///   - phase: gesture phase
    func postZoom(direction: ZoomDirection, t: Int, phase: CGGesturePhase) {
        let e = CGEvent(source: nil)!
        e.type = CGEventType.gesture
        e[.gestureType] = GestureType.zoom.rawValue

        let scale: Double = min(max(0.1, Double(abs(t)) / 40), 1)

        let value: Int64 = {
            let sign: Int64 = 0b1000_0000_0000_0000_0000_0000_0000_0000
            func buildValuePart() -> Int64 {
                Int64(50_000_000 * scale) + 980_000_000
            }

            switch direction {
            case .none: return sign
            case .expand: return buildValuePart()
            case .contract: return sign + buildValuePart()
            }
        }()
        e[.gestureSwipeDirection] = value
        e[.gestureZoomDirection] = value
        e[.gesturePhase] = Int64(phase.rawValue)
        e.post(tap: .cghidEventTap)
    }

    /// Post a rotation gesture event.
    /// - Parameters:
    ///   - direction: which direction to rotate
    ///   - phase: gesture phase
    func postRotation(direction: RotateDirection, t: Int, phase: CGGesturePhase) {
        let e = CGEvent(source: nil)!
        e.type = CGEventType.gesture
        e[.gestureType] = GestureType.rotation.rawValue

        let scale: Double = min(max(0.1, Double(abs(t)) / 40), 1)
        let value: Int64 = {
            switch direction {
            case .clockwise:
                return Int64(scale * 14)
            case .counterClockwise:
                return -Int64(scale * 14)
            case .none:
                return 0
            }
        }()

        e[.gestureSwipeValueX] = value
        e[.gesturePhase] = Int64(phase.rawValue)
        e.post(tap: .cghidEventTap)
    }

    /// Post a translation gesture event.
    /// - Parameters:
    ///   - phase: gesture phase
    func postTranslation(phase: CGGesturePhase) {
        let e = CGEvent(source: nil)!
        e.type = CGEventType.gesture
        e[.gestureType] = GestureType.translation.rawValue
        e[.gesturePhase] = Int64(phase.rawValue)
        e[134] = 1_065_353_216 // magic
        e.post(tap: .cghidEventTap)
    }

    /// Post a 4-finger swipe gesture event.
    /// - Parameters:
    ///   - direction: swipe direction and swipe progress
    ///   - phase: gesture phase
    ///
    /// - Important: value 135 defines the progress of this gesture. unlike other swipe gestures,
    ///              the 'progress' value needs to be accumulated along with the whole gesture.
    func postDockSwipe(
        direction: DockSwipeDirection,
        phase: CGGesturePhase
    ) {
        let e = CGEvent(source: nil)!
        e.type = CGEventType.dockGesture
        e[.gestureType] = GestureType.dockSwipe.rawValue
        e[.gesturePhase] = Int64(phase.rawValue)
        e[134] = Int64(phase.rawValue)
        e[136] = 1 // Magic
        e[138] = 3 // Magic

        func buildValue(_ accumulation: Double) -> Int64 {
            let sign: Int64 = 0b1000_0000_0000_0000_0000_0000_0000_0000
            if accumulation == 0 { return sign }
            func easingFunction(_ x: Double) -> Double {
                x > 1 ? 1 + (x - 1) * 0.05 : sqrt(1 - pow(x - 1, 2))
            }
            let v = Int64(980_000_000 + 80_000_000 * easingFunction(abs(accumulation)))
            return accumulation > 0 ? sign + v : v
        }

        switch direction {
        case let .horizontal(accumulation):
            guard accumulation != 0 else { return }
            e[.scrollWheelEventMomentumPhase] = 0 // Magic
            e[135] = buildValue(accumulation)
            e[165] = 1 // Magic
        case let .vertical(accumulation):
            guard accumulation != 0 else { return }
            e[.scrollWheelEventMomentumPhase] = 2 // Magic
            e[135] = buildValue(accumulation)
            e[165] = 2 // Magic
        }

        e.post(tap: .cghidEventTap)
    }
}

/// Dock swipe direction and progress
enum DockSwipeDirection {
    /// Vertical swipe with progress
    case vertical(upAccumulation: Double)
    /// Horizontal swipe with progress
    case horizontal(rightAccumulation: Double)
}
