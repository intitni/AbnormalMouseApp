import Combine
import Foundation

final class EventThrottler<T> {
    private let queue = DispatchQueue(label: "Throttler", target: .global(qos: .userInitiated))
    private var cancellables = [AnyCancellable]()
    private var accumulation: T
    private var initial: T
    private var perform: (T) -> Void = { _ in }
    private var time: TimeInterval = 0
    private var windowSize: TimeInterval

    var rate: Int = 70 {
        didSet {
            windowSize = 1 / Double(rate)
        }
    }

    init(_ initial: T, perform: @escaping (T) -> Void) {
        self.initial = initial
        self.perform = perform
        accumulation = initial
        windowSize = 1 / Double(rate)
    }

    func post(accumulate: @escaping (inout T) -> Void) {
        queue.async {
            accumulate(&self.accumulation)
            let current = Date().timeIntervalSinceReferenceDate
            if current - self.time > self.windowSize {
                self.time = current
                self.perform(self.accumulation)
                self.accumulation = self.initial
            }
        }
    }

    func end(accumulate: @escaping (inout T) -> Void) {
        queue.async {
            accumulate(&self.accumulation)
            self.time = 0
            self.perform(self.accumulation)
            self.accumulation = self.initial
        }
    }
}
