import AppKit
import CGEventOverride
import Combine
import ComposableArchitecture
import Foundation

/// A spesific feature of the app.
protocol Domain {
    associatedtype State: Equatable
    associatedtype Action
    associatedtype Environment
    typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
    typealias Store = ComposableArchitecture.Store<State, Action>
    typealias SubReducer = ComposableArchitecture.Reducer

    static var reducer: Reducer { get }
}

@dynamicMemberLookup
struct SystemEnvironment<Environment> {
    var environment: Environment
    var date: () -> Date
    var openURL: (URL) -> Void
    var quitApp: () -> Void
    var mainQueue: () -> DispatchQueue

    static func live(environment: Environment) -> Self {
        Self(
            environment: environment,
            date: Date.init,
            openURL: { NSWorkspace.shared.open($0) },
            quitApp: { NSApp.terminate(nil) },
            mainQueue: { .main }
        )
    }

    subscript<Dependency>(
        dynamicMember keyPath: WritableKeyPath<Environment, Dependency>
    ) -> Dependency {
        get { environment[keyPath: keyPath] }
        set { environment[keyPath: keyPath] = newValue }
    }

    subscript<Dependency>(
        dynamicMember keyPath: KeyPath<Environment, Dependency>
    ) -> Dependency {
        environment[keyPath: keyPath]
    }

    func map<NewEnvironment>(
        _ transform: @escaping (Environment) -> NewEnvironment
    ) -> SystemEnvironment<NewEnvironment> {
        .init(
            environment: transform(environment),
            date: date,
            openURL: openURL,
            quitApp: quitApp,
            mainQueue: mainQueue
        )
    }
}

struct TheApp: Domain {
    typealias Environment = SystemEnvironment<_Environment>

    struct _Environment {
        var persisted: Persisted
        var purchaseManager: PurchaseManagerType
        var updater: Updater
        var activatorConflictChecker: ActivatorConflictChecker
        var launchAtLoginManager: LaunchAtLoginManagerType

        let overrideControllers: [OverrideController]
    }

    struct State: Equatable {
        var mainScreen = MainDomain.State()
    }

    enum Action {
        case observePurchaseState
        case verifyLicense
        case purchaseStateDidChange(PurchaseState)
        case setAccessibilityAuthorized(Bool)

        case main(MainDomain.Action)
    }

    enum CancellableKeys: Hashable {
        case observePurchaseState
    }

    static let reducer = Reducer.combine(
        Reducer { state, action, environment in
            switch action {
            case .observePurchaseState:
                return environment.purchaseManager.purchaseState
                    .receive(on: DispatchQueue.main)
                    .eraseToEffect()
                    .map(Action.purchaseStateDidChange)
                    .cancellable(id: CancellableKeys.observePurchaseState, cancelInFlight: true)
            case .verifyLicense:
                let purchaseManager = environment.purchaseManager
                return .fireAndForget {
                    purchaseManager.reverifyIfNeeded()
                }
            case let .purchaseStateDidChange(purchaseState):
                state.mainScreen.isTrialEnded = false
                state.mainScreen.activationStateDescription = nil
                switch purchaseState {
                case .initial:
                    break
                case .trialDidEnd:
                    state.mainScreen.isTrialEnded = true
                case let .trialMode(daysLeft):
                    state.mainScreen.activationStateDescription = _L10n.PurchaseStatus
                        .trial(daysLeft)
                case let .activated(email):
                    break
                case let .activatedInvalid(email: email):
                    state.mainScreen.activationStateDescription = _L10n.PurchaseStatus.invalid
                case let .activatedUnverifiedForALongTime(email: email):
                    state.mainScreen.activationStateDescription = _L10n.PurchaseStatus.cantVerify
                case let .activatedRefunded(email: email):
                    state.mainScreen.activationStateDescription = _L10n.PurchaseStatus.refunded
                case let .activatedMaybePirateUser(email: email):
                    state.mainScreen.activationStateDescription = _L10n.PurchaseStatus.invalid
                }
                return .none
            case let .setAccessibilityAuthorized(isAuthorized):
                state.mainScreen.isAccessibilityAuthorized = isAuthorized
                if isAuthorized { state.mainScreen.isNeedAccessibilityViewPresented = false }
                return .none
            case .main:
                return .none
            }
        },
        MainDomain.reducer.pullback(
            state: \.mainScreen,
            action: /Action.main,
            environment: {
                $0.map {
                    MainDomain._Environment(
                        persisted: $0.persisted,
                        activatorConflictChecker: $0.activatorConflictChecker,
                        purchaseManager: $0.purchaseManager,
                        updater: $0.updater,
                        launchAtLoginManager: $0.launchAtLoginManager
                    )
                }
            }
        )
    )
}

extension Store where Action == TheApp.Action, State == TheApp.State {
    static var testStore: Self {
        let persisted = Persisted(
            userDefaults: MemoryPropertyListStorage()
        )
        return .init(
            initialState: .init(),
            reducer: TheApp.reducer,
            environment: .live(environment: .init(
                persisted: persisted,
                purchaseManager: FakePurchaseManager(),
                updater: FakeUpdater(),
                activatorConflictChecker: .init(persisted: Readonly(persisted)),
                launchAtLoginManager: FakeLaunchAtLoginManager(),
                overrideControllers: []
            ))
        )
    }
}

private enum _L10n {
    typealias PurchaseStatus = L10n.StatusBarMenu.PurchaseStatus
    typealias Shared = L10n.Shared
}
