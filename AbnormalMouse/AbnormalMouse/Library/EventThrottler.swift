import Combine
import Foundation

final class EventThrottler<T> {
    private var cancellables = [AnyCancellable]()
    private var accumulation: T
    private var previous: T?
    private var initial: T
    private var perform: (T) -> Void = { _ in }
    private var time: TimeInterval = 0
    private var windowSize: TimeInterval

    var rate: Int = 70 {
        didSet { windowSize = 1 / Double(rate) }
    }

    init(_ initial: T, perform: @escaping (T) -> Void) {
        self.initial = initial
        self.perform = perform
        accumulation = initial
        windowSize = 1 / Double(rate)
    }

    func post(accumulate: @escaping (inout T) -> Void) {
        accumulate(&accumulation)
        let current = Date().timeIntervalSinceReferenceDate
        if current - time > windowSize {
            time = current
            perform(accumulation)
            previous = accumulation
            accumulation = initial
        }
    }

    func end(accumulate: @escaping (inout T) -> Void) {
        accumulate(&accumulation)
        time = 0
        perform(accumulation)
        accumulation = initial
        previous = nil
    }

    func endWithLastValue() {
        if let p = previous {
            perform(p)
            previous = nil
        }
    }
}
