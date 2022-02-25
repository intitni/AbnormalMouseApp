import AppKit
import Combine
import ComposableArchitecture
import Foundation

enum MoveToScrollDomain: Domain {
    struct State: Equatable {
        struct MoveToScrollActivator: Equatable {
            var keyCombination: KeyCombination?
            var numberOfTapsRequired = 1
            var hasConflict = false
            var invalidReason: KeyCombinationInvalidReason?
        }

        var moveToScrollActivator = MoveToScrollActivator()

        struct HalfPageScrollActivator: Equatable {
            var shouldUseMoveToScrollKeyCombination = true
            var keyCombination: KeyCombination?
            var numberOfTapsRequired = 1
            var hasConflict = false
            var invalidReason: KeyCombinationInvalidReason?
        }

        var halfPageScrollActivator = HalfPageScrollActivator()

        var scrollSpeedMultiplier: Double = 4
        var swipeSpeedMultiplier: Double = 3
        var isInertiaEffectEnabled = false
    }

    enum Action: Equatable {
        case appear
        case toggleInertiaEffect

        case moveToScroll(MoveToScroll)
        enum MoveToScroll: Equatable {
            case setKeyCombination(KeyCombination?)
            case setNumberOfTapsRequired(Int)
            case clearKeyCombination
        }

        case changeScrollSpeedMultiplierTo(Double)
        case changeSwipeSpeedMultiplierTo(Double)

        case halfPageScroll(HalfPageScroll)
        enum HalfPageScroll: Equatable {
            case toggleUseMoveToScrollKeyCombinationDoubleTap
            case setKeyCombination(KeyCombination?)
            case setNumberOfTapsRequired(Int)
            case clearKeyCombination
        }

        case _internal(Internal)
        enum Internal {
            case checkValidity
            case checkConflict
        }
    }

    typealias Environment = SystemEnvironment<_Environment>
    struct _Environment {
        var persisted: Persisted.MoveToScroll
        var featureHasConflict: (ActivatorConflictChecker.Feature) -> Bool
        var checkKeyCombinationValidity: (KeyCombination?) -> KeyCombinationInvalidReason?
    }

    static let reducer = Reducer.combine(
        Reducer { state, action, environment in
            guard case let .moveToScroll(action) = action else { return .none }
            switch action {
            case let .setKeyCombination(combination):
                state.moveToScrollActivator.keyCombination = combination
                return .fireAndForget { environment.persisted.keyCombination = combination }
            case let .setNumberOfTapsRequired(count):
                let clamped = min(max(1, count), 3)
                state.moveToScrollActivator.numberOfTapsRequired = clamped
                return .fireAndForget {
                    environment.persisted.numberOfTapsRequired = clamped
                }
            case .clearKeyCombination:
                state.moveToScrollActivator.keyCombination = nil
                return .fireAndForget { environment.persisted.keyCombination = nil }
            }
        },
        Reducer { state, action, environment in
            guard case let .halfPageScroll(action) = action else { return .none }
            switch action {
            case .toggleUseMoveToScrollKeyCombinationDoubleTap:
                state.halfPageScrollActivator.shouldUseMoveToScrollKeyCombination.toggle()
                let result = state.halfPageScrollActivator.shouldUseMoveToScrollKeyCombination
                return .fireAndForget {
                    environment.persisted.halfPageScroll.useMoveToScrollDoubleTap = result
                }
            case let .setKeyCombination(combination):
                state.halfPageScrollActivator.keyCombination = combination
                return .fireAndForget {
                    environment.persisted.halfPageScroll.keyCombination = combination
                }
            case let .setNumberOfTapsRequired(count):
                let clamped = min(max(1, count), 3)
                state.halfPageScrollActivator.numberOfTapsRequired = clamped
                return .fireAndForget {
                    environment.persisted.halfPageScroll.numberOfTapsRequired = clamped
                }
            case .clearKeyCombination:
                state.halfPageScrollActivator.keyCombination = nil
                return .fireAndForget {
                    environment.persisted.halfPageScroll.keyCombination = nil
                }
            }
        },
        Reducer { state, action, environment in
            switch action {
            case .appear:
                state = State(from: environment.persisted)
                return .init(value: ._internal(.checkConflict))
            case .toggleInertiaEffect:
                state.isInertiaEffectEnabled.toggle()
                let result = state.isInertiaEffectEnabled
                return .fireAndForget { environment.persisted.isInertiaEffectEnabled = result }
            case let .moveToScroll(action):
                return .merge([
                    .init(value: ._internal(.checkConflict)),
                    .init(value: ._internal(.checkValidity)),
                ])
            case let .changeScrollSpeedMultiplierTo(multilier):
                state.scrollSpeedMultiplier = multilier
                return .fireAndForget { environment.persisted.scrollSpeedMultiplier = multilier }
            case let .changeSwipeSpeedMultiplierTo(multilier):
                state.swipeSpeedMultiplier = multilier
                return .fireAndForget { environment.persisted.swipeSpeedMultiplier = multilier }
            case .halfPageScroll:
                return .merge([
                    .init(value: ._internal(.checkConflict)),
                    .init(value: ._internal(.checkValidity)),
                ])
            case let ._internal(internalAction):
                switch internalAction {
                case .checkConflict:
                    let check = environment.featureHasConflict
                    state.moveToScrollActivator.hasConflict = check(.moveToScroll)
                    state.halfPageScrollActivator.hasConflict = check(.halfPageScroll)
                    return .none
                case .checkValidity:
                    let check = environment.checkKeyCombinationValidity
                    state.moveToScrollActivator.invalidReason = check(
                        state.moveToScrollActivator.keyCombination
                    )
                    state.halfPageScrollActivator.invalidReason = check(
                        state.halfPageScrollActivator.keyCombination
                    )
                    return .none
                }
            }
        }
    )
}

extension MoveToScrollDomain.State {
    init(from persisted: Persisted.MoveToScroll) {
        self.init(
            moveToScrollActivator: .init(
                keyCombination: persisted.keyCombination,
                numberOfTapsRequired: persisted.numberOfTapsRequired
            ),
            halfPageScrollActivator: .init(
                shouldUseMoveToScrollKeyCombination: persisted.halfPageScroll
                    .useMoveToScrollDoubleTap,
                keyCombination: persisted.halfPageScroll.keyCombination,
                numberOfTapsRequired: persisted.halfPageScroll.numberOfTapsRequired
            ),
            scrollSpeedMultiplier: persisted.scrollSpeedMultiplier,
            swipeSpeedMultiplier: persisted.swipeSpeedMultiplier,
            isInertiaEffectEnabled: persisted.isInertiaEffectEnabled
        )
    }
}

extension Store where Action == MoveToScrollDomain.Action, State == MoveToScrollDomain.State {
    static var testStore: Self {
        .init(
            initialState: .init(),
            reducer: MoveToScrollDomain.reducer,
            environment: .live(environment: .init(
                persisted: .init(),
                featureHasConflict: { _ in true },
                checkKeyCombinationValidity: { _ in nil }
            ))
        )
    }
}
