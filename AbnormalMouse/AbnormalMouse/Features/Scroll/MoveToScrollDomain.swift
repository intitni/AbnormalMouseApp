import AppKit
import Combine
import ComposableArchitecture
import Foundation

enum MoveToScrollDomain: Domain {
    struct State: Equatable {
        var activationKeyCombination: KeyCombination? = nil
        var isKeyCombinationConflict: Bool = false
        var scrollSpeedMultiplier: Double = 4
        var swipeSpeedMultiplier: Double = 3
        var isInertiaEffectEnabled = false
    }

    enum Action: Equatable {
        case appear
        case toggleInertiaEffect
        case setActivationKeyCombination(KeyCombination?)
        case clearActivationKeyCombination
        case changeScrollSpeedMultiplierTo(Double)
        case changeSwipeSpeedMultiplierTo(Double)

        case _internal(Internal)
        enum Internal {
            case checkConflict
        }
    }

    struct Environment {
        var persisted: Persisted.MoveToScroll
        var featureHasConflict: (ActivatorConflictChecker.Feature) -> Bool
    }

    static let reducer = Reducer { state, action, environment in
        switch action {
        case .appear:
            state = State(from: environment.persisted)
            return .init(value: ._internal(.checkConflict))
        case .toggleInertiaEffect:
            state.isInertiaEffectEnabled.toggle()
            let result = state.isInertiaEffectEnabled
            return .merge(
                .fireAndForget { environment.persisted.isInertiaEffectEnabled = result },
                .init(value: ._internal(.checkConflict))
            )
        case let .setActivationKeyCombination(combination):
            state.activationKeyCombination = combination
            let (keys, mouse) = combination?.raw ?? ([], nil)

            return .fireAndForget { environment.persisted.keyCombination = combination }
        case .clearActivationKeyCombination:
            state.activationKeyCombination = nil
            return .fireAndForget {
                environment.persisted.keyCombination = nil
            }
        case let .changeScrollSpeedMultiplierTo(multilier):
            state.scrollSpeedMultiplier = multilier
            return .fireAndForget {
                environment.persisted.scrollSpeedMultiplier = multilier
            }
        case let .changeSwipeSpeedMultiplierTo(multilier):
            state.swipeSpeedMultiplier = multilier
            return .fireAndForget {
                environment.persisted.swipeSpeedMultiplier = multilier
            }
        case let ._internal(internalAction):
            switch internalAction {
            case .checkConflict:
                state.isKeyCombinationConflict = environment.featureHasConflict(.scrollAndSwipe)
                return .none
            }
        }
    }
}

extension MoveToScrollDomain.State {
    init(from persisted: Persisted.MoveToScroll) {
        self.init(
            activationKeyCombination: persisted.keyCombination,
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
            environment: .init(
                persisted: .init(),
                featureHasConflict: { _ in true }
            )
        )
    }
}
