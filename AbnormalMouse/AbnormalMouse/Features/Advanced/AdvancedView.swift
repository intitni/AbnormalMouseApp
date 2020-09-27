import ComposableArchitecture
import SwiftUI

struct AdvancedScreen: View {
    let store: AdvancedDomain.Store

    var body: some View {
        AdvancedView(store: store)
            .lifeCycleWithViewStore(store, onAppear: { viewStore in
                viewStore.send(.appear)
            })
    }
}

private struct AdvancedView: View {
    let store: AdvancedDomain.Store

    var body: some View {
        ScrollView {
            self.settings
            Spacer()
        }
    }

    private var settings: some View {
        SettingsSectionView(
            showSeparator: true,
            title: { Text(_L10n.View.title) },
            content: {
                WithViewStore(store) { viewStore in
                    VStack(alignment: .leading) {
                        SettingsCheckbox(isOn: viewStore.binding(
                            get: { $0.listenToKeyboardEvent },
                            send: { _ in .toggleListenToKeyboardEvents }
                        )) {
                            Text(_L10n.View.listenToKeyboardEvent)
                        }

                        Text(_L10n.View.listenToKeyboardEventIntroduction).asFeatureIntroduction()
                    }
                }
            }
        )
    }
}

private enum _L10n {
    typealias View = L10n.Advanced.View
}
