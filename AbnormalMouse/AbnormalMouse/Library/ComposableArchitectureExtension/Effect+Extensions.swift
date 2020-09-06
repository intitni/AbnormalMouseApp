import Combine
import ComposableArchitecture

private var someCancellables = Set<AnyCancellable>()

extension Effect {
    static func fireAsyncAndForget(_ work: @escaping () -> AnyCancellable) -> Effect {
        Deferred { () -> Empty<Output, Failure> in
            work().store(in: &someCancellables)
            return Empty(completeImmediately: true)
        }
        .eraseToEffect()
    }
}
