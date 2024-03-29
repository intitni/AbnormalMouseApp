import AppKit
import Combine
import ComposableArchitecture
import Foundation

enum ZoomAndRotateDomain: Domain {
    struct State: Equatable {
        struct ZoomAndRotateActivator: Equatable {
            var keyCombination: KeyCombination?
            var hasConflict = false
            var numberOfTapsRequired = 1
            var invalidReason: KeyCombinationInvalidReason?
        }

        var zoomAndRotateActivator = ZoomAndRotateActivator()
        var zoomGestureDirection = MoveMouseDirection.none
        var rotateGestureDirection = MoveMouseDirection.none
        var zoomSpeedMultiplier: Double = 0
        var rotateSpeedMultiplier: Double = 0

        struct SmartZoomActivator: Equatable {
            var shouldUseZoomAndRotateKeyCombinationDoubleTap = true
            var keyCombination: KeyCombination?
            var numberOfTapsRequired = 1
            var hasConflict = false
            var invalidReason: KeyCombinationInvalidReason?
        }

        var smartZoomActivator = SmartZoomActivator()
    }

    enum Action: Equatable {
        case appear

        case zoomAndRotate(ZoomAndRotate)
        enum ZoomAndRotate: Equatable {
            case setKeyCombination(KeyCombination?)
            case setNumberOfTapsRequired(Int)
            case clearKeyCombination
        }

        case changeZoomGestureDirectionToOption(Int)
        case changeRotateGestureDirectionToOption(Int)
        case setZoomSpeedMultiplier(Double)
        case setRotateSpeedMultiplier(Double)

        case smartZoom(SmartZoom)
        enum SmartZoom: Equatable {
            case toggleUseZoomAndRotateKeyCombinationDoubleTap
            case setKeyCombination(KeyCombination?)
            case setNumberOfTapsRequired(Int)
            case clearKeyCombination
        }

        case _internal(Internal)
        enum Internal {
            case checkConflict
            case checkValidity
        }
    }

    typealias Environment = SystemEnvironment<_Environment>
    struct _Environment {
        var persisted: Persisted.ZoomAndRotate
        var featureHasConflict: (ActivatorConflictChecker.Feature) -> Bool
        var checkKeyCombinationValidity: (KeyCombination?) -> KeyCombinationInvalidReason?
    }

    static let reducer = Reducer.combine(
        Reducer { state, action, environment in
            guard case let .zoomAndRotate(action) = action else { return .none }
            switch action {
            case let .setKeyCombination(combination):
                state.zoomAndRotateActivator.keyCombination = combination
                let (keys, mouse) = combination?.raw ?? ([], nil)
                return .fireAndForget {
                    environment.persisted.keyCombination = combination
                }
            case let .setNumberOfTapsRequired(count):
                let clamped = min(max(1, count), 3)
                state.zoomAndRotateActivator.numberOfTapsRequired = clamped
                return .fireAndForget {
                    environment.persisted.numberOfTapsRequired = clamped
                }
            case .clearKeyCombination:
                state.zoomAndRotateActivator.keyCombination = nil
                return .fireAndForget {
                    environment.persisted.keyCombination = nil
                }
            }
        },
        Reducer { state, action, environment in
            guard case let .smartZoom(action) = action else { return .none }
            switch action {
            case .toggleUseZoomAndRotateKeyCombinationDoubleTap:
                state.smartZoomActivator.shouldUseZoomAndRotateKeyCombinationDoubleTap.toggle()
                let result = state.smartZoomActivator
                    .shouldUseZoomAndRotateKeyCombinationDoubleTap
                return .fireAndForget {
                    environment.persisted.smartZoom.useZoomAndRotateDoubleTap = result
                }
            case let .setKeyCombination(combination):
                state.smartZoomActivator.keyCombination = combination
                let (keys, mouse) = combination?.raw ?? ([], nil)
                return .fireAndForget {
                    environment.persisted.smartZoom.keyCombination = combination
                }
            case let .setNumberOfTapsRequired(count):
                let clamped = min(max(1, count), 3)
                state.smartZoomActivator.numberOfTapsRequired = clamped
                return .fireAndForget {
                    environment.persisted.smartZoom.numberOfTapsRequired = clamped
                }
            case .clearKeyCombination:
                state.smartZoomActivator.keyCombination = nil
                return .fireAndForget {
                    environment.persisted.smartZoom.keyCombination = nil
                }
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
            case .zoomAndRotate:
                return .merge([
                    .init(value: ._internal(.checkConflict)),
                    .init(value: ._internal(.checkValidity)),
                ])
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
            case let .setZoomSpeedMultiplier(multiplier):
                state.zoomSpeedMultiplier = multiplier
                return .fireAndForget {
                    environment.persisted.zoomSpeedMultiplier = multiplier
                }
            case let .setRotateSpeedMultiplier(multiplier):
                state.rotateSpeedMultiplier = multiplier
                return .fireAndForget {
                    environment.persisted.rotateSpeedMultiplier = multiplier
                }
            case let .smartZoom(action):
                return .merge([
                    .init(value: ._internal(.checkConflict)),
                    .init(value: ._internal(.checkValidity)),
                ])
            case let ._internal(internalAction):
                switch internalAction {
                case .checkConflict:
                    let hasConflict = environment.featureHasConflict
                    state.zoomAndRotateActivator.hasConflict = hasConflict(.zoomAndRotate)
                    state.smartZoomActivator.hasConflict = hasConflict(.smartZoom)
                    return .none
                case .checkValidity:
                    let check = environment.checkKeyCombinationValidity
                    state.zoomAndRotateActivator.invalidReason = check(
                        state.zoomAndRotateActivator.keyCombination
                    )
                    state.smartZoomActivator.invalidReason = check(
                        state.smartZoomActivator.keyCombination
                    )
                    return .none
                }
            }
        }
    )
}

extension ZoomAndRotateDomain.State {
    init(from persisted: Persisted.ZoomAndRotate) {
        self.init(
            zoomAndRotateActivator: .init(
                keyCombination: persisted.keyCombination,
                numberOfTapsRequired: persisted.numberOfTapsRequired
            ),
            zoomGestureDirection: persisted.zoomGestureDirection,
            rotateGestureDirection: persisted.rotateGestureDirection,
            zoomSpeedMultiplier: persisted.zoomSpeedMultiplier,
            rotateSpeedMultiplier: persisted.rotateSpeedMultiplier,
            smartZoomActivator: .init(
                shouldUseZoomAndRotateKeyCombinationDoubleTap: persisted.smartZoom
                    .useZoomAndRotateDoubleTap,
                keyCombination: persisted.smartZoom.keyCombination,
                numberOfTapsRequired: persisted.smartZoom.numberOfTapsRequired
            )
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
                featureHasConflict: { _ in true },
                checkKeyCombinationValidity: { _ in nil }
            ))
        )
    }
}
