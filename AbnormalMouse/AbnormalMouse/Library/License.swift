import AppKit
import Combine
import CombineExt
import ComposableArchitecture
import Foundation

protocol PurchaseManagerType {
    var purchaseState: CurrentValueRelay<PurchaseState> { get }
    func startTrialIfNeeded()
    func reverifyIfNeeded()
    func activateLicense(key: String, email: String) -> Effect<Result<Void, PurchaseError>, Never>
    func verifyLicense() -> Effect<Result<Void, PurchaseError>, Never>
    func deactivate() -> Effect<Result<Void, PurchaseError>, Never>
    func updatePurchaseState()
}

enum LicenseState: Int, Codable {
    /// There is no license
    case none
    /// License is considered valid
    case valid
    /// License is considered fake
    case fake
    /// License is refunded
    case refunded
    /// License is invalid
    case invalid
}

#if canImport(License)

import License

typealias PurchaseState = License.PurchaseState
typealias PurchaseError = License.PurchaseError

final class RealPurchaseManager: PurchaseManagerType {
    let purchaseState = CurrentValueRelay<PurchaseState>(.initial)
    private let p = FastSpringPurchaseManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        p.purchaseState.subscribe(purchaseState).store(in: &cancellables)
    }
    
    func startTrialIfNeeded() {
        p.startTrialIfNeeded()
    }
    
    func reverifyIfNeeded() {
        p.reverifyIfNeeded()
    }
    
    func activateLicense(key: String, email: String) -> Effect<Result<Void, PurchaseError>, Never> {
        p.activateLicense(key: key, email: email).catchToEffect()
    }
    
    func verifyLicense() -> Effect<Result<Void, PurchaseError>, Never> {
        p.verifyLicense().catchToEffect()
    }
    
    func deactivate() -> Effect<Result<Void, PurchaseError>, Never> {
        p.deactivate().catchToEffect()
    }
    
    func updatePurchaseState() {
        p.updatePurchaseState()
    }
}

#else

typealias RealPurchaseManager = FakePurchaseManager

enum PurchaseError: Swift.Error {
    case other(Swift.Error)
    case failedToVerifyLicenseKeyLocally
    case licenseKeyIsInvalid
    case licenseKeyIsRefunded
    case licenseKeyHasReachedActivationLimit
}

enum PurchaseState: Equatable {
    case initial
    case trialDidEnd
    case trialMode(daysLeft: Int)
    case activated(email: String)
    case activatedInvalid(email: String)
    case activatedUnverifiedForALongTime(email: String)
    case activatedRefunded(email: String)
    case activatedMaybePirateUser(email: String)
}

#endif

struct FakePurchaseManager: PurchaseManagerType {
    func reverifyIfNeeded() {}

    var purchaseState: CurrentValueRelay<PurchaseState> = .init(.activated(email: "github"))

    func updatePurchaseState() {}
    
    func startTrialIfNeeded() {}

    func activateLicense(key: String, email: String) -> Effect<Result<Void, PurchaseError>, Never> {
        return Effect(value: .success(()))
    }

    func verifyLicense() -> Effect<Result<Void, PurchaseError>, Never> {
        return Effect(value: .success(()))
    }

    func deactivate() -> Effect<Result<Void, PurchaseError>, Never> {
        return Effect(value: .success(()))
    }
}
