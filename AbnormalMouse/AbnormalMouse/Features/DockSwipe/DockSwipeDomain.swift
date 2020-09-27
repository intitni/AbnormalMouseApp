import AppKit
import Combine
import ComposableArchitecture
import Foundation

enum DockSwipeDomain: Domain {
    struct State: Equatable {
        var dockSwipeActivationKeyCombination: KeyCombination? = nil
        var activatorHasConflict = false
    }

    enum Action: Equatable {
        case appear
        case setDockSwipeActivationKeyCombination(KeyCombination?)
        case clearDockSwipeActivationKeyCombination

        case _internal(Internal)
        enum Internal {
            case checkConflict
        }
    }

    typealias Environment = SystemEnvironment<_Environment>
    struct _Environment {
        var persisted: Persisted.DockSwipe
        var featureHasConflict: (ActivatorConflictChecker.Feature) -> Bool
    }

    static let reducer = Reducer { state, action, environment in
        switch action {
        case .appear:
            state = State(from: environment.persisted)
            return .none
        case let .setDockSwipeActivationKeyCombination(combination):
            state.dockSwipeActivationKeyCombination = combination
            let (keys, mouse) = combination?.raw ?? ([], nil)
            return .fireAndForget {
                environment.persisted.keyCombination = combination
            }
        case .clearDockSwipeActivationKeyCombination:
            state.dockSwipeActivationKeyCombination = nil
            return .fireAndForget {
                environment.persisted.keyCombination = nil
            }
        case let ._internal(internalAction):
            switch internalAction {
            case .checkConflict:
                state.activatorHasConflict = environment.featureHasConflict(.dockSwipe)
                return .none
            }
        }
    }
}

extension DockSwipeDomain.State {
    init(from persisted: Persisted.DockSwipe) {
        self.init(
            dockSwipeActivationKeyCombination: persisted.keyCombination
        )
    }
}

extension Store where Action == DockSwipeDomain.Action, State == DockSwipeDomain.State {
    static var testStore: Self {
        .init(
            initialState: .init(),
            reducer: DockSwipeDomain.reducer,
            environment: .live(environment: .init(
                persisted: .init(),
                featureHasConflict: { _ in true }
            ))
        )
    }
}
