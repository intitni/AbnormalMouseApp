import AppKit
import Combine
import ComposableArchitecture
import Foundation

enum ZoomAndRotateDomain: Domain {
    struct State: Equatable {
        var zoomAndRotateActivationKeyCombination: KeyCombination? = nil
        var zoomAndRotateActivatorHasConflict = false
        var zoomGestureDirection: MoveMouseDirection = .none
        var rotateGestureDirection: MoveMouseDirection = .none
        var shouldSmartZoomUseZoomAndRotateKeyCombinationDoubleTap: Bool = true
        var smartZoomActivationKeyCombination: KeyCombination? = nil
        var smartZoomActivatorHasConflict = false
    }

    enum Action: Equatable {
        case appear

        case setZoomAndRotateActivationKeyCombination(KeyCombination?)
        case clearZoomAndRotateActivationKeyCombination
        case changeZoomGestureDirectionToOption(Int)
        case changeRotateGestureDirectionToOption(Int)

        case toggleSmartZoomUseZoomAndRotateKeyCombinationDoubleTap
        case setSmartZoomActivationKeyCombination(KeyCombination?)
        case clearSmartZoomActivationKeyCombination

        case _internal(Internal)
        enum Internal {
            case checkConflict
        }
    }

    typealias Environment = SystemEnvironment<_Environment>
    struct _Environment {
        var persisted: Persisted.ZoomAndRotate
        var moveToScrollPersisted: Persisted.MoveToScroll
        var featureHasConflict: (ActivatorConflictChecker.Feature) -> Bool
    }

    static let reducer = Reducer { state, action, environment in
        switch action {
        case .appear:
            state = State(
                from: environment.persisted,
                moveToScrollPersisted: environment.moveToScrollPersisted
            )
            return .init(value: ._internal(.checkConflict))
        case let .setZoomAndRotateActivationKeyCombination(combination):
            state.zoomAndRotateActivationKeyCombination = combination
            let (keys, mouse) = combination?.raw ?? ([], nil)
            return .merge(
                .fireAndForget {
                    environment.persisted.keyCombination = combination
                },
                .init(value: ._internal(.checkConflict))
            )
        case .clearZoomAndRotateActivationKeyCombination:
            state.zoomAndRotateActivationKeyCombination = nil
            return .merge(
                .fireAndForget {
                    environment.persisted.keyCombination = nil
                },
                .init(value: ._internal(.checkConflict))
            )
        case let .changeZoomGestureDirectionToOption(option):
            let direction = MoveMouseDirection(rawValue: option) ?? .none
            state.zoomGestureDirection = direction
            if state.rotateGestureDirection.isSameAxis(to: direction) {
                state.rotateGestureDirection = .none
            }
            let anotherDirection = state.rotateGestureDirection
            return .fireAndForget {
                environment.persisted.zoomGestureDirection = direction
                environment.persisted.rotateGestureDirection = anotherDirection
            }
        case let .changeRotateGestureDirectionToOption(option):
            let direction = MoveMouseDirection(rawValue: option) ?? .none
            state.rotateGestureDirection = direction
            if state.zoomGestureDirection.isSameAxis(to: direction) {
                state.zoomGestureDirection = .none
            }
            let anotherDirection = state.zoomGestureDirection
            return .fireAndForget {
                environment.persisted.zoomGestureDirection = anotherDirection
                environment.persisted.rotateGestureDirection = direction
            }
        case .toggleSmartZoomUseZoomAndRotateKeyCombinationDoubleTap:
            state.shouldSmartZoomUseZoomAndRotateKeyCombinationDoubleTap.toggle()
            let result = state.shouldSmartZoomUseZoomAndRotateKeyCombinationDoubleTap
            return .merge(
                .fireAndForget {
                    environment.persisted.smartZoom.useZoomAndRotateDoubleTap = result
                },
                .init(value: ._internal(.checkConflict))
            )
        case let .setSmartZoomActivationKeyCombination(combination):
            state.smartZoomActivationKeyCombination = combination
            let (keys, mouse) = combination?.raw ?? ([], nil)
            return .merge(
                .fireAndForget {
                    environment.persisted.smartZoom.keyCombination = combination
                },
                .init(value: ._internal(.checkConflict))
            )
        case .clearSmartZoomActivationKeyCombination:
            state.smartZoomActivationKeyCombination = nil
            return .merge(
                .fireAndForget {
                    environment.persisted.smartZoom.keyCombination = nil
                },
                .init(value: ._internal(.checkConflict))
            )
        case let ._internal(internalAction):
            switch internalAction {
            case .checkConflict:
                let hasConflict = environment.featureHasConflict
                state.zoomAndRotateActivatorHasConflict = hasConflict(.zoomAndRotate)
                state.smartZoomActivatorHasConflict = hasConflict(.smartZoom)
                return .none
            }
        }
    }
}

extension ZoomAndRotateDomain.State {
    init(
        from persisted: Persisted.ZoomAndRotate,
        moveToScrollPersisted _: Persisted.MoveToScroll
    ) {
        self.init(
            zoomAndRotateActivationKeyCombination: persisted.keyCombination,
            zoomGestureDirection: persisted.zoomGestureDirection,
            rotateGestureDirection: persisted.rotateGestureDirection,
            shouldSmartZoomUseZoomAndRotateKeyCombinationDoubleTap: persisted.smartZoom
                .useZoomAndRotateDoubleTap,
            smartZoomActivationKeyCombination: persisted.smartZoom.keyCombination
        )
    }
}

extension Store where Action == ZoomAndRotateDomain.Action, State == ZoomAndRotateDomain.State {
    static var testStore: Self {
        .init(
            initialState: .init(),
            reducer: ZoomAndRotateDomain.reducer,
            environment: .live(environment: .init(
                persisted: .init(),
                moveToScrollPersisted: .init(),
                featureHasConflict: { _ in true }
            ))
        )
    }
}
