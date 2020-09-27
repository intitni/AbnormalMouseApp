import AppKit
import Combine
import ComposableArchitecture
import Foundation

enum ZoomAndRotateDomain: Domain {
    struct State: Equatable {
        var zoomAndRotateActivationKeyCombination: KeyCombination? = nil
        var zoomGestureDirection: MoveMouseDirection = .none
        var rotateGestureDirection: MoveMouseDirection = .none
        var shouldSmartZoomUseZoomAndRotateKeyCombinationDoubleTap: Bool = true
        var smartZoomActivationKeyCombination: KeyCombination? = nil
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
    }

    struct Environment {
        var persisted: Persisted.ZoomAndRotate
        var moveToScrollPersisted: Persisted.MoveToScroll
        var openURL: (URL) -> Void
    }

    static let reducer = Reducer { state, action, environment in
        switch action {
        case .appear:
            state = State(
                from: environment.persisted,
                moveToScrollPersisted: environment.moveToScrollPersisted
            )
            return .none
        case let .setZoomAndRotateActivationKeyCombination(combination):
            state.zoomAndRotateActivationKeyCombination = combination
            let (keys, mouse) = combination?.raw ?? ([], nil)
            return .fireAndForget {
                environment.persisted.keyCombination = combination
            }
        case .clearZoomAndRotateActivationKeyCombination:
            state.zoomAndRotateActivationKeyCombination = nil
            return .fireAndForget {
                environment.persisted.keyCombination = nil
            }
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
            return .fireAndForget {
                environment.persisted.smartZoom.useZoomAndRotateDoubleTap = result
            }
        case let .setSmartZoomActivationKeyCombination(combination):
            state.smartZoomActivationKeyCombination = combination
            let (keys, mouse) = combination?.raw ?? ([], nil)
            return .fireAndForget {
                environment.persisted.smartZoom.keyCombination = combination
            }
        case .clearSmartZoomActivationKeyCombination:
            state.smartZoomActivationKeyCombination = nil
            return .fireAndForget {
                environment.persisted.smartZoom.keyCombination = nil
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
            environment: .init(
                persisted: .init(),
                moveToScrollPersisted: .init(),
                openURL: { _ in }
            )
        )
    }
}
