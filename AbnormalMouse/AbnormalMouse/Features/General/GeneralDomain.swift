import AppKit
import Combine
import ComposableArchitecture
import Foundation
import ServiceManagement
import Sparkle

enum GeneralDomain: Domain {
    struct State: Equatable {
        var version: String {
            func v(_ key: String) -> String {
                Bundle.main.infoDictionary?[key] as? String ?? "Unknown"
            }
            return "\(v("CFBundleShortVersionString"))(\(v("CFBundleVersion")))"
        }

        var startAtLogin: Bool = false
        var listenToKeyboardEvent: Bool = false
        var purchaseDescription: String = ""
        var automaticallyCheckForUpdate: Bool = false

        var purchaseState: Purchase = .init()
        struct Purchase: Equatable {
            var licenseState: LicenseState = .none
            var isTrialEnded: Bool { trialDaysRemaining == 0 }
            var isInvalid: Bool = false
            var trialDaysRemaining: Int = 0
            var licenseToEmail: String = ""
            var isDuringDeactivation: Bool = false
            var deactivationFailedReason: String = ""
        }

        var activationState: ActivationDomain.State? = nil
    }

    enum Action {
        case appear
        case observePurchaseState
        case purchaseStateDidChange(PurchaseState)
        case toggleStartAtLogin
        case activate
        case purchase
        case deactivate
        case verify
        case finishDeactivation
        case failedInDeactivation(PurchaseError)
        case toggleAutomaticallyCheckForUpdate
        case checkForUpdate
        case quit
        case openTwitter
        case emailMe
        case setActivationView(isPresenting: Bool)

        case activation(ActivationDomain.Action)
    }

    struct Environment {
        let persisted: Persisted.General
        let purchaseManager: PurchaseManagerType
        let updater: SUUpdater?
        let openURL: (URL) -> Void
        let quitApp: () -> Void
    }

    enum CancellableKeys: Hashable {
        case observePurchaseState
    }

    static let reducer = Reducer.combine(
        Reducer { state, action, environment in
            switch action {
            case .appear:
                state.automaticallyCheckForUpdate = environment.updater?
                    .automaticallyChecksForUpdates ?? false
                return .none
            case .toggleStartAtLogin:
                state.startAtLogin.toggle()
                let shouldStartAtLogin = state.startAtLogin
                return .fireAndForget {
                    environment.persisted.startAtLogin = shouldStartAtLogin
                    let launcherIdentifier = LaunchAtLoginConstants.launcherIdentifier
                    SMLoginItemSetEnabled(launcherIdentifier as CFString, shouldStartAtLogin)
                }
            case .observePurchaseState:
                return environment.purchaseManager.purchaseState
                    .receive(on: DispatchQueue.main)
                    .eraseToEffect()
                    .map(Action.purchaseStateDidChange)
                    .cancellable(id: CancellableKeys.observePurchaseState, cancelInFlight: true)
            case let .purchaseStateDidChange(purchaseState):
                switch purchaseState {
                case .initial: break
                case .trialDidEnd:
                    state.purchaseState.licenseState = .none
                    state.purchaseState.trialDaysRemaining = 0
                case let .trialMode(daysLeft):
                    state.purchaseState.licenseState = .none
                    state.purchaseState.trialDaysRemaining = daysLeft
                case let .activated(email):
                    state.purchaseState.licenseState = .valid
                    state.purchaseState.licenseToEmail = email
                case let .activatedInvalid(email):
                    state.purchaseState.licenseState = .invalid
                    state.purchaseState.licenseToEmail = email
                case let .activatedUnverifiedForALongTime(email):
                    state.purchaseState.licenseState = .invalid
                    state.purchaseState.licenseToEmail = email
                case let .activatedRefunded(email):
                    state.purchaseState.licenseState = .refunded
                    state.purchaseState.licenseToEmail = email
                case let .activatedMaybePirateUser(email):
                    state.purchaseState.licenseState = .fake
                    state.purchaseState.licenseToEmail = email
                }
                return .none
            case .activate:
                return .init(value: .setActivationView(isPresenting: true))
            case .purchase:
                return .fireAndForget {
                    environment.openURL(URL(string: L10n.Shared.homepageURLString)!)
                }
            case .deactivate:
                state.purchaseState.isDuringDeactivation = true
                state.purchaseState.deactivationFailedReason = ""
                return environment.purchaseManager.deactivate()
                    .waitAtLeast(delay: .milliseconds(1000))
                    .map { result in
                        switch result {
                        case .success: return .finishDeactivation
                        case let .failure(error): return .failedInDeactivation(error)
                        }
                    }
                    .eraseToEffect()
            case .verify:
                return .fireAsyncAndForget {
                    environment.purchaseManager.verifyLicense()
                        .sink { print($0) }
                }
            case .finishDeactivation:
                state.purchaseState.isDuringDeactivation = false
                state.purchaseState.deactivationFailedReason = ""
                return .none
            case let .failedInDeactivation(error):
                state.purchaseState.isDuringDeactivation = false
                switch error {
                case let .other(error):
                    switch error {
                    case let x as URLError:
                        state.purchaseState.deactivationFailedReason = L10n.General.ErrorMessage
                            .failedToDeactivate
                    default:
                        state.purchaseState.deactivationFailedReason = L10n.General.ErrorMessage
                            .networkError
                    }
                default: break
                }
                return .none
            case .toggleAutomaticallyCheckForUpdate:
                state.automaticallyCheckForUpdate.toggle()
                let shouldCheck = state.automaticallyCheckForUpdate
                return .fireAndForget {
                    environment.updater?.automaticallyChecksForUpdates = shouldCheck
                }
            case .checkForUpdate:
                return .fireAndForget {
                    environment.updater?.checkForUpdates(environment)
                }
            case .quit:
                return .fireAndForget {
                    environment.quitApp()
                }
            case .openTwitter:
                return .fireAndForget {
                    environment.openURL(URL(string: "https://twitter.com/intitni")!)
                }
            case .emailMe:
                return .fireAndForget {
                    environment.openURL(URL(string: "mailto:abnormalmouseapp@intii.com")!)
                }
            case let .setActivationView(isPresenting):
                if isPresenting { state.activationState = .init() }
                else { state.activationState = nil }
                return .none
            case let .activation(action):
                switch action {
                case .buyNow:
                    return .fireAndForget {
                        environment.openURL(URL(string: L10n.Shared.homepageURLString)!)
                    }
                case .dismiss:
                    return .init(value: .setActivationView(isPresenting: false))
                default:
                    return .none
                }
            }
        },
        ActivationDomain.reducer.optional().pullback(
            state: \.activationState,
            action: /Action.activation,
            environment: {
                ActivationDomain.Environment(purchaseManager: $0.purchaseManager)
            }
        )
    )
}

extension GeneralDomain.State {
    init(from persisted: Persisted.General, updater: SUUpdater) {
        startAtLogin = persisted.startAtLogin
        automaticallyCheckForUpdate = updater.automaticallyChecksForUpdates
    }
}

extension Store where State == GeneralDomain.State, Action == GeneralDomain.Action {
    static let testStore: GeneralDomain.Store = .init(
        initialState: .init(),
        reducer: GeneralDomain.reducer,
        environment: .init(
            persisted: .init(),
            purchaseManager: FakePurchaseManager(),
            updater: SUUpdater.shared(),
            openURL: { print($0) },
            quitApp: { print("Quit") }
        )
    )
}
