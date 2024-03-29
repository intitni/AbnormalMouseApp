import AppKit
import Combine
import ComposableArchitecture
import Foundation

enum DockSwipeDomain: Domain {
    struct State: Equatable {
        struct DockSwipeActivator: Equatable {
            var keyCombination: KeyCombination?
            var hasConflict = false
            var numberOfTapsRequired = 1
            var invalidReason: KeyCombinationInvalidReason?
        }

        var dockSwipeActivator = DockSwipeActivator()
    }

    enum Action: Equatable {
        case appear

        case dockSwipe(DockSwipe)
        enum DockSwipe: Equatable {
            case setKeyCombination(KeyCombination?)
            case clearKeyCombination
            case setNumberOfTapsRequired(Int)
        }

        case _internal(Internal)
        enum Internal: Equatable {
            case checkConflict
            case checkValidity
        }
    }

    typealias Environment = SystemEnvironment<_Environment>
    struct _Environment {
        var persisted: Persisted.DockSwipe
        var featureHasConflict: (ActivatorConflictChecker.Feature) -> Bool
        var checkKeyCombinationValidity: (KeyCombination?) -> KeyCombinationInvalidReason?
    }

    static let reducer = Reducer.combine(
        Reducer { state, action, environment in
            switch action {
            case let .dockSwipe(action):
                switch action {
                case let .setKeyCombination(combination):
                    state.dockSwipeActivator.keyCombination = combination
                    let (keys, mouse) = combination?.raw ?? ([], nil)
                    return .fireAndForget {
                        environment.persisted.keyCombination = combination
                    }
                case let .setNumberOfTapsRequired(count):
                    let clamped = min(max(1, count), 3)
                    state.dockSwipeActivator.numberOfTapsRequired = clamped
                    return .fireAndForget {
                        environment.persisted.numberOfTapsRequired = clamped
                    }
                case .clearKeyCombination:
                    state.dockSwipeActivator.keyCombination = nil
                    return .fireAndForget {
                        environment.persisted.keyCombination = nil
                    }
                }
            default: return .none
            }
        },
        Reducer { state, action, environment in
            switch action {
            case .appear:
                state = State(from: environment.persisted)
                return .merge([
                    .init(value: ._internal(.checkConflict)),
                    .init(value: ._internal(.checkValidity)),
                ])
            case .dockSwipe:
                return .merge([
                    .init(value: ._internal(.checkConflict)),
                    .init(value: ._internal(.checkValidity)),
                ])
            case let ._internal(internalAction):
                switch internalAction {
                case .checkConflict:
                    state.dockSwipeActivator.hasConflict = environment
                        .featureHasConflict(.dockSwipe)
                    return .none
                case .checkValidity:
                    let check = environment.checkKeyCombinationValidity
                    state.dockSwipeActivator.invalidReason = check(
                        state.dockSwipeActivator.keyCombination
                    )
                    return .none
                }
            }
        }
    )
}

extension DockSwipeDomain.State {
    init(from persisted: Persisted.DockSwipe) {
        self.init(
            dockSwipeActivator: .init(
                keyCombination: persisted.keyCombination,
                numberOfTapsRequired: persisted.numberOfTapsRequired
            )
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
                featureHasConflict: { _ in true },
                checkKeyCombinationValidity: { _ in nil }
            ))
        )
    }
}
