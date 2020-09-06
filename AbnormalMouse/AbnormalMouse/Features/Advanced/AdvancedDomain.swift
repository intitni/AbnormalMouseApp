import AppKit
import Combine
import ComposableArchitecture
import Foundation
import ServiceManagement
import Sparkle

enum AdvancedDomain: Domain {
    struct State: Equatable {
        var listenToKeyboardEvent: Bool = false
    }

    enum Action {
        case appear
        case toggleListenToKeyboardEvents
    }

    struct Environment {
        let persisted: Persisted.Advanced
    }

    enum CancellableKeys: Hashable {
        case observePurchaseState
    }

    static let reducer = Reducer { state, action, environment in
        switch action {
        case .appear:
            state = .init(from: environment.persisted)
            return .none
        case .toggleListenToKeyboardEvents:
            state.listenToKeyboardEvent.toggle()
            let result = state.listenToKeyboardEvent
            return .fireAndForget {
                environment.persisted.listenToKeyboardEvent = result
            }
        }
    }
}

extension AdvancedDomain.State {
    init(from persisted: Persisted.Advanced) {
        listenToKeyboardEvent = persisted.listenToKeyboardEvent
    }
}

extension Store where State == AdvancedDomain.State, Action == AdvancedDomain.Action {
    static let testStore: AdvancedDomain.Store = .init(
        initialState: .init(),
        reducer: AdvancedDomain.reducer,
        environment: .init(
            persisted: .init()
        )
    )
}
