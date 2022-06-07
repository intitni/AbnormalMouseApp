import AppKit
import Combine
import ComposableArchitecture
import Foundation
import ServiceManagement

enum AdvancedDomain: Domain {
    typealias ExcludedApplication = Persisted.Advanced.ExcludedApplication

    struct State: Equatable {
        var listenToKeyboardEvent: Bool = false
        var excludedApps: [ExcludedApplication] = []
        var availableApplications: [ExcludedApplication] = []
        var selectedExcludedApp: ExcludedApplication?
    }

    enum Action {
        case appear
        case toggleListenToKeyboardEvents
        case addExcludedApp(ExcludedApplication)
        case selectExcludedApp(ExcludedApplication)
        case removeSelectedExcludedApp
    }

    typealias Environment = SystemEnvironment<_Environment>
    struct _Environment {
        let persisted: Persisted.Advanced
    }

    enum CancellableKeys: Hashable {
        case observePurchaseState
    }

    static let reducer = Reducer { state, action, environment in
        switch action {
        case .appear:
            state = .init(from: environment.persisted)
            return .none
        case .toggleListenToKeyboardEvents:
            state.listenToKeyboardEvent.toggle()
            let result = state.listenToKeyboardEvent
            return .fireAndForget {
                environment.persisted.listenToKeyboardEvent = result
            }
        case let .addExcludedApp(app):
            if state.excludedApps.contains(app) { return .none }
            state.excludedApps.append(app)
            let list = state.excludedApps
            return .fireAndForget {
                environment.persisted.gloablExcludedApplications = list
            }
        case .removeSelectedExcludedApp:
            guard let selected = state.selectedExcludedApp else { return .none }
            state.excludedApps.removeAll { selected.bundleIdentifier == $0.bundleIdentifier }
            let list = state.excludedApps
            state.selectedExcludedApp = nil
            return .fireAndForget {
                environment.persisted.gloablExcludedApplications = list
            }
        case let .selectExcludedApp(app):
            state.selectedExcludedApp = app
            return .none
        }
    }
}

extension AdvancedDomain.State {
    init(from persisted: Persisted.Advanced) {
        listenToKeyboardEvent = persisted.listenToKeyboardEvent
        excludedApps = persisted.gloablExcludedApplications
        availableApplications = NSWorkspace.shared.runningApplications.compactMap {
            guard let name = $0.localizedName,
                  let identifier = $0.bundleIdentifier else { return nil }
            return .init(appName: name, bundleIdentifier: identifier)
        }
    }
}

extension Store where State == AdvancedDomain.State, Action == AdvancedDomain.Action {
    static let testStore: AdvancedDomain.Store = .init(
        initialState: .init(),
        reducer: AdvancedDomain.reducer,
        environment: .live(environment: .init(
            persisted: .init()
        ))
    )
}
