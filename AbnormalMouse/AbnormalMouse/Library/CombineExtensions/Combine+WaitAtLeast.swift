import Combine
import CombineExt
import Foundation

extension Publishers {
    struct WaitAtLeast<Upstream, S>: Publisher where Upstream: Publisher, S: Scheduler {
        typealias Output = Upstream.Output
        typealias Failure = Upstream.Failure

        let upstream: Upstream
        let delay: S.SchedulerTimeType.Stride
        let scheduler: S

        init(
            seconds: S.SchedulerTimeType.Stride,
            upstream: Upstream,
            scheduler: S
        ) {
            self.upstream = upstream
            delay = seconds
            self.scheduler = scheduler
        }

        func receive<S>(subscriber: S)
            where S: Subscriber, Upstream.Failure == S.Failure, Upstream.Output == S.Input
        {
            Publishers.Zip(
                Result<Int, Never>.Publisher(0)
                    .delay(for: delay, scheduler: scheduler),
                upstream
                    .materialize()
            )
            .map(\.1)
            .dematerialize()
            .receive(subscriber: subscriber)
        }
    }
}

extension Publisher {
    func waitAtLeast<S: Scheduler>(
        delay: S.SchedulerTimeType.Stride,
        scheduler: S
    ) -> Publishers.WaitAtLeast<Self, S> {
        if EnvironmentVariable.neverWaitAtLeast {
            return Publishers.WaitAtLeast(
                seconds: .seconds(0),
                upstream: self,
                scheduler: scheduler
            )
        } else {
            return Publishers.WaitAtLeast(seconds: delay, upstream: self, scheduler: scheduler)
        }
    }

    func waitAtLeast(
        delay: DispatchQueue.SchedulerTimeType.Stride
    ) -> Publishers.WaitAtLeast<Self, DispatchQueue> {
        if EnvironmentVariable.neverWaitAtLeast {
            return Publishers.WaitAtLeast(
                seconds: .seconds(0),
                upstream: self,
                scheduler: DispatchQueue.main
            )
        } else {
            return Publishers.WaitAtLeast(
                seconds: delay,
                upstream: self,
                scheduler: DispatchQueue.main
            )
        }
    }
}
