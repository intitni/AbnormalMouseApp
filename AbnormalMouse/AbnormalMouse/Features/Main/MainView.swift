import ComposableArchitecture
import SwiftUI

struct MainScreen: View {
    let store: MainDomain.Store

    var body: some View {
        MainView(store: store)
    }
}

private struct MainView: View {
    let store: MainDomain.Store

    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationView {
                self.navigationSideBar
                self.initialScreen
            }
            .overlayWhen( // Trial end alert.
                viewStore.state.isTrialEnded,
                view: self.trialEndAlert(viewStore: viewStore),
                alignment: .topTrailing
            )
            .overlayWhen( // Activation state.
                viewStore.state.activationStateDescription != nil,
                view: self.activationState(viewStore: viewStore),
                alignment: .topTrailing
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .backgroundEmptyViewWithViewStore(store) { view, viewStore in
            view
                .sheet( // Accessability alert.
                    isPresented: viewStore.binding(
                        get: { $0.isNeedAccessabilityViewPresented },
                        send: { .setAccessabilityViewPresented($0) }
                    )
                ) {
                    NeedAccessabilityScreen(
                        store: self.store.scope(
                            state: { $0.needAccessability },
                            action: { .needAccessability(action: $0) }
                        )
                    )
                    .transition(.slide)
                }
        }
        .backgroundEmptyViewWithViewStore(store) { view, viewStore in
            view
                .sheet( // Activation panel.
                    isPresented: viewStore.binding(
                        get: { $0.activationState != nil },
                        send: MainDomain.Action.setActivationView(isPresenting:)
                    )
                ) {
                    IfLetStore(
                        self.store.scope(
                            state: { $0.activationState },
                            action: { .activation($0) }
                        ),
                        then: ActivationScreen.init(store:)
                    )
                    .transition(.slide)
                }
        }
    }

    private var navigationSideBar: some View {
        List {
            NavigationLink(
                destination: self.moveToScrollSettingsScreen,
                label: {
                    NavigationTabTitle(
                        image: Image(Asset.iconMoveToScroll.name),
                        title: _L10n.View.TabTitle.moveToScroll
                    )
                }
            )
            NavigationLink(
                destination: self.zoomAndRotateScreen,
                label: {
                    NavigationTabTitle(
                        image: Image(Asset.iconZoomAndRotate.name),
                        title: _L10n.View.TabTitle.zoomAndRotate
                    )
                }
            )
            NavigationLink(
                destination: self.dockSwipeScreen,
                label: {
                    NavigationTabTitle(
                        image: Image(Asset.iconDockSwipe.name),
                        title: _L10n.View.TabTitle.dockSwipe
                    )
                }
            )
            NavigationLink(
                destination: self.advancedScreen,
                label: {
                    NavigationTabTitle(
                        image: Image(Asset.iconAdvanced.name),
                        title: _L10n.View.TabTitle.advanced
                    )
                }
            )
            NavigationLink(
                destination: self.generalScreen,
                label: {
                    NavigationTabTitle(
                        image: Image(Asset.iconGeneral.name),
                        title: _L10n.View.TabTitle.general
                    )
                }
            )
            Spacer()
        }
        .listStyle(SidebarListStyle())
        .frame(width: 200)
    }

    private var initialScreen: some View { moveToScrollSettingsScreen }

    private var moveToScrollSettingsScreen: some View {
        withEnableStatus(
            MoveToScrollSettingsScreen(
                store: store.scope(
                    state: { $0.moveToScrollSettings },
                    action: { .moveToScrollSettings(action: $0) }
                )
            )
        )
    }

    private var zoomAndRotateScreen: some View {
        withEnableStatus(
            ZoomAndRotateSettingsScreen(
                store: self.store.scope(
                    state: { $0.zoomAndRotateSettings },
                    action: { .zoomAndRotateSettings(action: $0) }
                )
            )
        )
    }

    private var dockSwipeScreen: some View {
        withEnableStatus(
            DockSwipeSettingsScreen(
                store: self.store.scope(
                    state: { $0.dockSwipeSettings },
                    action: { .dockSwipeSettings(action: $0) }
                )
            )
        )
    }

    private var advancedScreen: some View {
        withEnableStatus(
            AdvancedScreen(
                store: self.store.scope(
                    state: { $0.advanced },
                    action: { .advanced(action: $0) }
                )
            )
        )
    }

    private var generalScreen: some View {
        withEnableStatus(
            GeneralScreen(
                store: self.store.scope(
                    state: { $0.general },
                    action: { .general(action: $0) }
                )
            )
        )
    }

    private func withEnableStatus<V: View>(_ view: V) -> some View {
        WithViewStore(store.scope(state: \.isAccessabilityAuthorized)) { viewStore in
            ZStack(alignment: .bottom) {
                view
                if !viewStore.state {
                    HStack {
                        Image(nsImage: NSImage(named: NSImage.statusUnavailableName)!)
                        Text(_L10n.View.Status.notEnabled)
                            .bold()
                        Spacer()
                        Button(action: { viewStore.send(.setAccessabilityViewPresented(true)) }) {
                            Text(_L10n.View.Status.enableButtonTitle)
                        }
                    }
                    .frame(height: 50, alignment: .leading)
                    .padding([.leading, .trailing], 10)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                    .shadow(color: Color(NSColor.shadowColor).opacity(0.1), radius: 6, x: 0, y: 1)
                    .padding([.leading, .trailing, .bottom], 8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 400)
        }
    }

    private func trialEndAlert(
        viewStore: ViewStore<MainDomain.State, MainDomain.Action>
    ) -> some View {
        VStack(spacing: 8) {
            Text(_L10n.View.ExpireAlert.title)
                .asFeatureTitle()
            Text(_L10n.View.ExpireAlert.content)
                .multilineTextAlignment(.center)
            Spacer().frame(height: 8)
            HStack {
                Button(action: { viewStore.send(.activate) }) {
                    Text(_L10n.View.ExpireAlert.activate)
                }
                Button(action: { viewStore.send(.purchase) }) {
                    Text(_L10n.View.ExpireAlert.buyNow)
                }
            }
        }
        .frame(maxWidth: 400)
        .padding([.all], 16)
        .roundedCornerBackground(
            cornerRadius: 4,
            fillColor: Color(NSColor.controlBackgroundColor),
            shadow: .init()
        )
        .padding([.all], 8)
    }

    private func activationState(
        viewStore: ViewStore<MainDomain.State, MainDomain.Action>
    ) -> some View {
        Text(viewStore.state.activationStateDescription ?? "")
            .padding([.top, .bottom], 8)
            .padding([.leading, .trailing], 16)
            .roundedCornerBackground(
                cornerRadius: 4,
                fillColor: Color(NSColor.controlBackgroundColor),
                shadow: .init()
            )
            .padding([.all], 8)
    }
}

private struct NavigationTabTitle: View {
    let image: Image
    let title: String

    init(image: Image, title: String) {
        self.image = image
        self.title = title
    }

    var body: some View {
        HStack(spacing: 4) {
            image
            Text(title)
                .lineLimit(2)
                .font(.system(size: 12, weight: .bold, design: .default))
                .multilineTextAlignment(.leading)
        }
        .padding([.top, .bottom], 12)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(store: .testStore)
            .environment(\.colorScheme, .light)
    }
}

struct MainView_Previews_Dark: PreviewProvider {
    static var previews: some View {
        MainView(store: .testStore)
            .environment(\.colorScheme, .dark)
    }
}

private enum _L10n {
    typealias View = L10n.MainView
}
