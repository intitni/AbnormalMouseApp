import AppKit
import Combine
import ComposableArchitecture
import Foundation

enum DockSwipeDomain: Domain {
    struct State: Equatable {
        var dockSwipeActivationKeyCombination: KeyCombination? = nil
    }

    enum Action: Equatable {
        case appear
        case setDockSwipeActivationKeyCombination(KeyCombination?)
        case clearDockSwipeActivationKeyCombination
    }

    struct Environment {
        var persisted: Persisted.DockSwipe
    }

    static let reducer = Reducer { state, action, environment in
        switch action {
        case .appear:
            state = State(from: environment.persisted)
            return .none
        case .setDockSwipeActivationKeyCombination(let combination):
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
            environment: .init(
                persisted: .init()
            )
        )
    }
}
