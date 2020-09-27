import ComposableArchitecture
import SwiftUI

struct DockSwipeSettingsScreen: View {
    let store: DockSwipeDomain.Store

    var body: some View {
        DockSwipeSettingsView(store: store)
            .lifeCycleWithViewStore(store, onAppear: { viewStore in
                viewStore.send(.appear)
            })
    }
}

private struct DockSwipeSettingsView: View {
    let store: DockSwipeDomain.Store

    var body: some View {
        ScrollView {
            DockSwipeView(store: store)
            Spacer()
        }
    }
}

private struct DockSwipeView: View {
    let store: DockSwipeDomain.Store

    var body: some View {
        SettingsSectionView(
            showSeparator: false,
            title: { Text(_L10n.View.title) },
            introduction: { Text(_L10n.View.introduction) },
            content: {
                WithViewStore(
                    store.scope(
                        state: \.dockSwipeActivator,
                        action: DockSwipeDomain.Action.dockSwipeActivator
                    )
                ) {
                    viewStore in
                    SettingsKeyCombinationInput(
                        keyCombination: viewStore.binding(
                            get: { $0.keyCombination },
                            send: { .setKeyCombination($0) }
                        ),
                        numberOfTapsRequired: viewStore.binding(
                            get: { $0.numberOfTapsRequired },
                            send: { .setNumberOfTapsRequired($0) }
                        ),
                        hasConflict: viewStore.hasConflict,
                        title: { Text(_L10n.View.activationKeyCombinationTitle) }
                    )
                }

                SettingsTips {
                    Text(_L10n.View.Tips.usage).tipsTitle(_L10n.TipsTitle.usage)
                    EmptyView()
                }
            }
        )
    }
}

private enum _L10n {
    typealias View = L10n.DockSwipeSettings.View
    typealias TipsTitle = L10n.Shared.TipsTitle
}

struct DockSwipeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DockSwipeSettingsView(store: .init(
            initialState: .init(),
            reducer: DockSwipeDomain.reducer,
            environment: .live(environment: .init(
                persisted: .init(),
                featureHasConflict: { _ in true }
            ))
        ))
    }
}
