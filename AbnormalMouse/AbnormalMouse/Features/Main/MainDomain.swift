import AppKit
import CGEventOverride
import Combine
import ComposableArchitecture
import Foundation

struct MainDomain: Domain {
    typealias Environment = SystemEnvironment<_Environment>

    struct _Environment {
        var persisted: Persisted
        var activatorConflictChecker: ActivatorConflictChecker
        var purchaseManager: PurchaseManagerType
        var updater: Updater
    }

    struct State: Equatable {
        var isAccessabilityAuthorized: Bool = false
        var isNeedAccessabilityViewPresented: Bool = false

        var moveToScrollSettings = MoveToScrollDomain.State()
        var zoomAndRotateSettings = ZoomAndRotateDomain.State()
        var dockSwipeSettings = DockSwipeDomain.State()
        var needAccessability = NeedAccessabilityDomain.State()
        var advanced = AdvancedDomain.State()
        var general = GeneralDomain.State()

        var isTrialEnded: Bool = false
        var activationStateDescription: String?

        var activationState: ActivationDomain.State? = nil
    }

    enum Action {
        case setAccessabilityViewPresented(Bool)

        case moveToScrollSettings(action: MoveToScrollDomain.Action)
        case zoomAndRotateSettings(action: ZoomAndRotateDomain.Action)
        case dockSwipeSettings(action: DockSwipeDomain.Action)
        case needAccessability(action: NeedAccessabilityDomain.Action)
        case advanced(action: AdvancedDomain.Action)
        case general(action: GeneralDomain.Action)

        case activate
        case purchase
        case setActivationView(isPresenting: Bool)
        case activation(ActivationDomain.Action)
    }

    enum CancellableKeys: Hashable {
        case observePurchaseState
    }

    static let reducer = Reducer.combine(
        Reducer { state, action, environment in
            switch action {
            case let .setAccessabilityViewPresented(isPresented):
                state.isNeedAccessabilityViewPresented = isPresented
                return .none
            case .activate:
                return .init(value: .setActivationView(isPresenting: true))
            case .purchase:
                return .fireAndForget {
                    environment.openURL(URL(string: _L10n.Shared.homepageURLString)!)
                }
            case let .setActivationView(isPresenting):
                if isPresenting { state.activationState = .init() }
                else { state.activationState = nil }
                return .none

            case .moveToScrollSettings:
                return .none
            case .zoomAndRotateSettings:
                return .none
            case .dockSwipeSettings:
                return .none
            case .needAccessability:
                return .none
            case .advanced:
                return .none
            case .general:
                return .none
            case let .activation(action):
                switch action {
                case .buyNow:
                    return .fireAndForget {
                        environment.openURL(URL(string: _L10n.Shared.homepageURLString)!)
                    }
                case .dismiss:
                    return .init(value: .setActivationView(isPresenting: false))
                default:
                    return .none
                }
            }
        },
        MoveToScrollDomain.reducer.pullback(
            state: \.moveToScrollSettings,
            action: /Action.moveToScrollSettings,
            environment: {
                $0.map {
                    .init(
                        persisted: $0.persisted.moveToScroll,
                        featureHasConflict: $0.activatorConflictChecker.featureHasConflict
                    )
                }
            }
        ),
        ZoomAndRotateDomain.reducer.pullback(
            state: \.zoomAndRotateSettings,
            action: /Action.zoomAndRotateSettings,
            environment: {
                $0.map {
                    .init(
                        persisted: $0.persisted.zoomAndRotate,
                        featureHasConflict: $0.activatorConflictChecker.featureHasConflict
                    )
                }
            }
        ),
        DockSwipeDomain.reducer.pullback(
            state: \.dockSwipeSettings,
            action: /Action.dockSwipeSettings,
            environment: {
                $0.map {
                    .init(
                        persisted: $0.persisted.dockSwipe,
                        featureHasConflict: $0.activatorConflictChecker.featureHasConflict
                    )
                }
            }
        ),
        NeedAccessabilityDomain.reducer.pullback(
            state: \.needAccessability,
            action: /Action.needAccessability,
            environment: {
                $0.map { _ in
                    .init()
                }
            }
        ),
        AdvancedDomain.reducer.pullback(
            state: \.advanced,
            action: /Action.advanced,
            environment: {
                $0.map {
                    .init(persisted: $0.persisted.advanced)
                }
            }
        ),
        GeneralDomain.reducer.pullback(
            state: \.general,
            action: /Action.general,
            environment: {
                $0.map {
                    .init(
                        persisted: $0.persisted.general,
                        purchaseManager: $0.purchaseManager,
                        updater: $0.updater
                    )
                }
            }
        ),
        ActivationDomain.reducer.optional().pullback(
            state: \.activationState,
            action: /Action.activation,
            environment: {
                $0.map {
                    .init(purchaseManager: $0.purchaseManager)
                }
            }
        )
    )
}

extension Store where Action == MainDomain.Action, State == MainDomain.State {
    static var testStore: Self {
        let persisted = Persisted(
            userDefaults: MemoryPropertyListStorage()
        )
        return .init(
            initialState: .init(
                isAccessabilityAuthorized: false,
                isNeedAccessabilityViewPresented: false,
                moveToScrollSettings: .init(),
                zoomAndRotateSettings: .init(),
                needAccessability: .init(),
                general: .init()
            ),
            reducer: MainDomain.reducer,
            environment: .live(environment: .init(
                persisted: persisted,
                activatorConflictChecker: .init(persisted: Readonly(persisted)),
                purchaseManager: FakePurchaseManager(),
                updater: FakeUpdater()
            ))
        )
    }
}

private enum _L10n {
    typealias PurchaseStatus = L10n.StatusBarMenu.PurchaseStatus
    typealias Shared = L10n.Shared
}
