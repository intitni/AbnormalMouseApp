import AppKit
import Combine
import ComposableArchitecture
import Foundation

enum MoveToScrollDomain: Domain {
    struct State: Equatable {
        var activationKeyCombination: KeyCombination? = nil
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
    }

    struct Environment {
        var persisted: Persisted.MoveToScroll
    }

    static let reducer = Reducer { state, action, environment in
        switch action {
        case .appear:
            state = State(from: environment.persisted)
            return .none
        case .toggleInertiaEffect:
            state.isInertiaEffectEnabled.toggle()
            let result = state.isInertiaEffectEnabled
            return .fireAndForget {
                environment.persisted.isInertiaEffectEnabled = result
            }
        case let .setActivationKeyCombination(combination):
            state.activationKeyCombination = combination
            let (keys, mouse) = combination?.raw ?? ([], nil)
            return .fireAndForget {
                environment.persisted.keyCombination = combination
            }
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
                persisted: .init()
            )
        )
    }
}
