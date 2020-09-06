import AppKit
import CGEventExtension
import CGEventOverride
import Foundation
import IOKit

struct EmulateEventPoster {
    let type: AnyHashable
    let queue = DispatchQueue(
        label: "EmulateEventPoster",
        attributes: .concurrent,
        target: .global(qos: .userInteractive)
    )

    private func p(_ event: CGEvent) {
        queue.async { event.post(tap: .cghidEventTap) }
    }

    func postEventPerFrame(_ events: [() -> Void]) {
        EventSequenceController.shared?.scheduleTasks(events, forKey: type)
    }

    func postOnNextLoop(_ block: @escaping (EmulateEventPoster) -> Void) {
        DispatchQueue.main.async {
            block(self)
        }
    }

    func postSmoothScroll(v: Double = 0, h: Double = 0) {
        func easingFunction(_ x: Double) -> Double {
            x < 0.5
                ? 4 * x * x * x
                : 1 - pow(-2 * x + 2, 3) / 2
        }

        queue.sync(flags: .barrier) {
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
                        self.postScroll(v: -sV, h: -sH, isPartOfPan: false, phase: .began)
                    } else {
                        self.postScroll(v: -sV, h: -sH, isPartOfPan: false, phase: .changed)
                    }
                }
            }
            scheduledTask.append {
                self.postScroll(isPartOfPan: false, phase: .ended)
            }
            self.postEventPerFrame(scheduledTask)
        }
    }

    func postInertiaEffect(v: Double = 0, h: Double = 0) {
        func easingFunction(_ x: Double) -> Double { sin((x * .pi) / 2) }

        queue.sync(flags: .barrier) {
            let count = min(200, max(abs(v), abs(h))) / refreshSpeedScale / 2
            if count <= 0 { return }

            var scheduledTask = [() -> Void]()
            for i in stride(from: 0, to: count, by: 1) {
                let x = 1 - i / count
                let scale = easingFunction(x)
                func scaled(_ k: Double) -> Double { Double(k) * scale }
                scheduledTask.append {
                    self.postScroll(v: Int(scaled(v)), h: Int(scaled(h)), isPartOfPan: false)
                }
            }
            scheduledTask.append {
                self.postScroll(isPartOfPan: false)
            }
            self.postEventPerFrame(scheduledTask)
        }
    }

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
        p(e)
    }

    func postScrollMomentum(
        v: Double = 0,
        h: Double = 0,
        phase: CGMomentumScrollPhase = CGMomentumScrollPhase.none
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
        e[.scrollWheelEventMomentumPhase] = Int64(phase.rawValue)
        e[101] = 4 // magic
        e[.scrollIsPartOfPan] = 1
        p(e)
    }

    func postNullGesture() {
        let e = CGEvent(source: nil)!
        e.type = CGEventType.gesture
        p(e)
    }

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
        e[.gestureSwipeMotion] = mystery
        e[.gestureZoomDirection] = mystery
        p(e)
    }

    func postGestureStart() {
        let e = CGEvent(source: nil)!
        e.type = CGEventType.gesture
        e[.gestureType] = GestureType.gestureStarted.rawValue
        p(e)
    }

    func postGestureEnd() {
        let e = CGEvent(source: nil)!
        e.type = CGEventType.gesture
        e[.gestureType] = GestureType.gestureEnded.rawValue
        p(e)
    }

    func postGesture(_ gesture: () -> Void) {
        postGestureStart()
        defer { postGestureEnd() }
        gesture()
    }

    func postSmartZoom() {
        postGesture {
            let e = CGEvent(source: nil)!
            e.type = CGEventType.gesture
            e[.gestureType] = GestureType.zoomToggle.rawValue
            p(e)
        }
    }

    func postZoom(direction: ZoomDirection, phase: CGGesturePhase) {
        let e = CGEvent(source: nil)!
        e.type = CGEventType.gesture
        e[.gestureType] = GestureType.zoom.rawValue
        e[.gestureSwipeDirection] = direction.rawValue
        e[.gestureZoomDirection] = direction.rawValue
        e[.gesturePhase] = Int64(phase.rawValue)
        p(e)
    }

    func postRotation(direction: RotateDirection, phase: CGGesturePhase) {
        let e = CGEvent(source: nil)!
        e.type = CGEventType.gesture
        e[.gestureType] = GestureType.rotation.rawValue
        e[.gestureSwipeValueX] = direction.rawValue
        e[.gesturePhase] = Int64(phase.rawValue)
        p(e)
    }

    func postTranslation(phase: CGGesturePhase) {
        let e = CGEvent(source: nil)!
        e.type = CGEventType.gesture
        e[.gestureType] = GestureType.translation.rawValue
        e[.gesturePhase] = Int64(phase.rawValue)
        e[134] = 1_065_353_216 // magic
        p(e)
    }
}
