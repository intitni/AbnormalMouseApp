import AppKit
import CGEventOverride
import Combine
import ComposableArchitecture
import Foundation
import Sparkle

struct MainDomain: Domain {
    typealias Environment = SystemEnvironment<_Environment>

    struct _Environment {
        var persisted: Persisted
        var purchaseManager: PurchaseManagerType
        var updater: SUUpdater
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
                MoveToScrollDomain.Environment(
                    persisted: $0.persisted.moveToScroll
                )
            }
        ),
        ZoomAndRotateDomain.reducer.pullback(
            state: \.zoomAndRotateSettings,
            action: /Action.zoomAndRotateSettings,
            environment: {
                ZoomAndRotateDomain.Environment(
                    persisted: $0.persisted.zoomAndRotate,
                    moveToScrollPersisted: $0.persisted.moveToScroll,
                    openURL: $0.openURL
                )
            }
        ),
        DockSwipeDomain.reducer.pullback(
            state: \.dockSwipeSettings,
            action: /Action.dockSwipeSettings,
            environment: {
                DockSwipeDomain.Environment(persisted: $0.persisted.dockSwipe)
            }
        ),
        NeedAccessabilityDomain.reducer.pullback(
            state: \.needAccessability,
            action: /Action.needAccessability,
            environment: {
                NeedAccessabilityDomain.Environment(openURL: $0.openURL)
            }
        ),
        AdvancedDomain.reducer.pullback(
            state: \.advanced,
            action: /Action.advanced,
            environment: {
                .init(persisted: $0.persisted.advanced)
            }
        ),
        GeneralDomain.reducer.pullback(
            state: \.general,
            action: /Action.general,
            environment: {
                .init(
                    persisted: $0.persisted.general,
                    purchaseManager: $0.purchaseManager,
                    updater: $0.updater,
                    openURL: $0.openURL,
                    quitApp: $0.quitApp
                )
            }
        ),
        ActivationDomain.reducer.optional().pullback(
            state: \.activationState,
            action: /Action.activation,
            environment: {
                ActivationDomain.Environment(purchaseManager: $0.purchaseManager)
            }
        )
    )
}

extension Store where Action == MainDomain.Action, State == MainDomain.State {
    static var testStore: Self {
        .init(
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
                persisted: .init(
                    userDefaults: MemoryPropertyListStorage(),
                    keychainAccess: FakeKeychainAccess()
                ),
                purchaseManager: FakePurchaseManager(),
                updater: SUUpdater.shared()
            ))
        )
    }
}

private enum _L10n {
    typealias PurchaseStatus = L10n.StatusBarMenu.PurchaseStatus
    typealias Shared = L10n.Shared
}
