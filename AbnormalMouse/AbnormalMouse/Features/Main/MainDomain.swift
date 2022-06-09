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
        var keyCombinationValidityChecker: KeyCombinationValidityChecker
        var purchaseManager: PurchaseManagerType
        var updater: Updater
        var launchAtLoginManager: LaunchAtLoginManagerType
    }

    struct State: Equatable {
        var isAccessibilityAuthorized: Bool = false
        var isNeedAccessibilityViewPresented: Bool = false

        var moveToScrollSettings = MoveToScrollDomain.State()
        var zoomAndRotateSettings = ZoomAndRotateDomain.State()
        var dockSwipeSettings = DockSwipeDomain.State()
        var needAccessibility = NeedAccessibilityDomain.State()
        var advanced = AdvancedDomain.State()
        var general = GeneralDomain.State()

        var isTrialEnded: Bool = false
        var activationStateDescription: String?

        var activationState: ActivationDomain.State?
    }

    enum Action {
        case setAccessibilityViewPresented(Bool)

        case moveToScrollSettings(action: MoveToScrollDomain.Action)
        case zoomAndRotateSettings(action: ZoomAndRotateDomain.Action)
        case dockSwipeSettings(action: DockSwipeDomain.Action)
        case needAccessibility(action: NeedAccessibilityDomain.Action)
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
            case let .setAccessibilityViewPresented(isPresented):
                state.isNeedAccessibilityViewPresented = isPresented
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
            case .needAccessibility:
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
                        featureHasConflict: $0.activatorConflictChecker.featureHasConflict,
                        checkKeyCombinationValidity: $0.keyCombinationValidityChecker
                            .checkValidity(_:)
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
                        featureHasConflict: $0.activatorConflictChecker.featureHasConflict,
                        checkKeyCombinationValidity: $0.keyCombinationValidityChecker
                            .checkValidity(_:)
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
                        featureHasConflict: $0.activatorConflictChecker.featureHasConflict,
                        checkKeyCombinationValidity: $0.keyCombinationValidityChecker
                            .checkValidity(_:)
                    )
                }
            }
        ),
        NeedAccessibilityDomain.reducer.pullback(
            state: \.needAccessibility,
            action: /Action.needAccessibility,
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
                        updater: $0.updater,
                        launchAtLoginManager: $0.launchAtLoginManager
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
                isAccessibilityAuthorized: false,
                isNeedAccessibilityViewPresented: false,
                moveToScrollSettings: .init(),
                zoomAndRotateSettings: .init(),
                needAccessibility: .init(),
                general: .init(),
                activationStateDescription: "Hello"
            ),
            reducer: MainDomain.reducer,
            environment: .live(environment: .init(
                persisted: persisted,
                activatorConflictChecker: .init(persisted: Readonly(persisted)),
                keyCombinationValidityChecker: .init(persisted: Readonly(persisted)),
                purchaseManager: FakePurchaseManager(),
                updater: FakeUpdater(),
                launchAtLoginManager: FakeLaunchAtLoginManager()
            ))
        )
    }
}

private enum _L10n {
    typealias PurchaseStatus = L10n.StatusBarMenu.PurchaseStatus
    typealias Shared = L10n.Shared
}
