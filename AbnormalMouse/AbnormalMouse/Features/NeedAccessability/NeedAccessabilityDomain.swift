import AppKit
import Combine
import ComposableArchitecture
import Foundation

enum NeedAccessabilityDomain: Domain {
    struct State: Equatable {}

    enum Action {
        case goToAccessbilityPreferencePane
    }

    struct Environment {
        let openURL: (URL) -> Void
    }

    static let reducer = Reducer { _, action, environment in
        switch action {
        case .goToAccessbilityPreferencePane:
            return .fireAndForget {
                let urlString =
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                environment.openURL(URL(string: urlString)!)
            }
        }
    }
}

extension Store where Action == NeedAccessabilityDomain.Action,
    State == NeedAccessabilityDomain.State {
    static var testStore: Self {
        Self(
            initialState: .init(),
            reducer: NeedAccessabilityDomain.reducer,
            environment: .init(openURL: { _ in })
        )
    }
}
