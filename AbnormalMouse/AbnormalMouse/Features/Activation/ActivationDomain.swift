import AppKit
import Combine
import ComposableArchitecture
import Foundation

enum ActivationDomain: Domain {
    struct State: Equatable {
        var licenseKey = ""
        var email = ""
        
        var activationState: ActivationState = .entering
        enum ActivationState: Equatable {
            case entering
            case activating
            case failed(reason: String)
        }
        
        var isActivateButtonEnabled: Bool {
            if case .activating = activationState { return false }
            return !licenseKey.isEmpty && !email.isEmpty
        }
    }
    
    enum Action {
        case updateLicenseKey(String)
        case updateEmail(String)
        case buyNow
        case activate
        case failInActivation(reason: String)
        case dismiss
    }
    
    struct Environment {
        let purchaseManager: PurchaseManagerType
    }
    
    static let reducer = Reducer { state, action, environment in
        switch action {
        case .updateLicenseKey(let key):
            state.licenseKey = key
            return .none
        case .updateEmail(let email):
            state.email = email
            return .none
        case .buyNow: // handled by parent
            return .none
        case .activate:
            switch state.activationState {
            case .entering, .failed:
                state.activationState = .activating
                return environment.purchaseManager.activateLicense(
                    key: state.licenseKey,
                    email: state.email
                )
                .receive(on: DispatchQueue.main)
                .map { result in
                    switch result {
                    case .success: return .dismiss
                    case .failure(let error):
                        switch error {
                        case .other:
                            return .failInActivation(reason: _L10n.FailureReason.networkError)
                        case .failedToVerifyLicenseKeyLocally:
                            return .failInActivation(reason: _L10n.FailureReason.invalid)
                        case .licenseKeyIsInvalid:
                            return .failInActivation(reason: _L10n.FailureReason.invalid)
                        case .licenseKeyIsRefunded:
                            return .failInActivation(reason: _L10n.FailureReason.refunded)
                        case .licenseKeyHasReachedActivationLimit:
                            return .failInActivation(reason: _L10n.FailureReason.reachedLimit)
                        }
                    }
                }
                .waitAtLeast(delay: .milliseconds(1000))
                .eraseToEffect()
            case .activating: return .none
            }
        case .failInActivation(let reason):
            state.activationState = .failed(reason: reason)
            return .none
        case .dismiss: // handled by parent
            return .none
        }
    }
}

extension Store where State == ActivationDomain.State, Action == ActivationDomain.Action {
    static func testStore(_ transform: (inout State) -> Void) -> ActivationDomain.Store {
        var state = State()
        transform(&state)
        return .init(
            initialState: state,
            reducer: ActivationDomain.reducer,
            environment: .init(
                purchaseManager: FakePurchaseManager()
            )
        )
    }
}

private typealias _L10n = L10n.Activation
