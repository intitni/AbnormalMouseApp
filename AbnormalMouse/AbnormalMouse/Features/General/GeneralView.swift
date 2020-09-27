import ComposableArchitecture
import SwiftUI

struct GeneralScreen: View {
    let store: GeneralDomain.Store

    var body: some View {
        GeneralView(store: store)
            .backgroundEmptyViewWithViewStore(store.scope(state: \.activationState)) {
                view, viewStore in
                view.sheet(isPresented: viewStore.binding(
                    get: { $0 != nil },
                    send: GeneralDomain.Action.setActivationView(isPresenting:)
                )) {
                    IfLetStore(
                        self.store.scope(
                            state: { $0.activationState },
                            action: { .activation($0) }
                        ),
                        then: ActivationScreen.init(store:)
                    )
                }
            }
            .lifeCycleWithViewStore(store, onAppear: { viewStore in
                viewStore.send(.appear)
            })
    }
}

private struct GeneralView: View {
    let store: GeneralDomain.Store

    var body: some View {
        ScrollView {
            self.settings
            PurchaseStateView(store: self.store)
            self.update
            self.about
            Spacer()
        }
    }

    private var settings: some View {
        SettingsSectionView(
            showSeparator: true,
            title: { Text(L10n.General.Title.general) },
            content: {
                WithViewStore(store) { viewStore in
                    VStack(alignment: .leading) {
                        SettingsCheckbox(isOn: viewStore.binding(
                            get: { $0.startAtLogin },
                            send: { _ in .toggleStartAtLogin }
                        )) {
                            Text(_L10n.autoStart)
                        }

                        Button(action: { viewStore.send(.quit) }) {
                            Text(_L10n.quit)
                        }
                    }
                }
            }
        )
        .overlay(
            Image(Asset.iconApp.name)
                .padding(.trailing, 12)
                .padding(.top, 12),
            alignment: .topTrailing
        )
    }

    private var update: some View {
        SettingsSectionView(showSeparator: true) {
            WithViewStore(store) { viewStore in
                VStack(alignment: .leading) {
                    HStack {
                        Text(_L10n.version(viewStore.version))
                        Button(action: { viewStore.send(.checkForUpdate) }) {
                            Text(_L10n.checkForUpdate)
                        }
                    }
                    SettingsCheckbox(
                        isOn: viewStore.binding(
                            get: { $0.automaticallyCheckForUpdate },
                            send: { _ in .toggleAutomaticallyCheckForUpdate }
                        )
                    ) {
                        Text(_L10n.automaticallyCheckForUpdate)
                    }
                }
            }
        }
    }

    private var about: some View {
        SettingsSectionView(
            showSeparator: true,
            title: { Text(_L10n.Title.about) },
            content: {
                WithViewStore(store) { viewStore in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(_L10n.developedBy)
                            Button(action: { viewStore.send(.openTwitter) }) {
                                Text("@intitni")
                            }
                            .buttonStyle(LinkButtonStyle())
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text(_L10n.contactMe)
                            Button(action: { viewStore.send(.emailMe) }) {
                                Text("abnormalmouseapp@intii.com")
                            }
                            .buttonStyle(LinkButtonStyle())
                        }
                    }
                }
            }
        )
    }
}

private struct PurchaseStateView: View {
    let store: GeneralDomain.Store

    var body: some View {
        SettingsSectionView(showSeparator: true) {
            WithViewStore(store.scope(state: { $0.purchaseState })) { viewStore in
                VStack(alignment: .leading) {
                    if viewStore.state.licenseState == .none {
                        self.caseNoLicense(viewStore)
                    } else {
                        self.caseHasLicense(viewStore)
                    }
                    if viewStore.state.licenseState != .none {
                        Text(_L10n.licenseTo(viewStore.state.licenseToEmail))
                    }
                }
                .onAppear {
                    viewStore.send(.observePurchaseState)
                }
            }
        }
    }

    private func caseNoLicense(_ viewStore: ViewStore<
        GeneralDomain.State.Purchase,
        GeneralDomain.Action
    >) -> some View {
        HStack(spacing: 8) {
            if viewStore.state.isTrialEnded {
                Text(_L10n.trialEnd)
            } else {
                Text(_L10n.trialDaysRemain(viewStore.state.trialDaysRemaining))
            }
            Button(action: { viewStore.send(.activate) }) {
                Text(_L10n.activate)
            }
            Button(action: { viewStore.send(.purchase) }) {
                Text(_L10n.purchase)
            }
        }
    }

    private func caseHasLicense(_ viewStore: ViewStore<
        GeneralDomain.State.Purchase,
        GeneralDomain.Action
    >) -> some View {
        HStack(spacing: 8) {
            if viewStore.state.licenseState == .valid {
                Text(_L10n.licenseValid)
            } else if viewStore.state.licenseState == .refunded {
                Text(_L10n.licenseRefunded)
            } else {
                Text(_L10n.licenseInvalid)
            }

            Button(action: { viewStore.send(.deactivate) }) {
                Text(viewStore.state.isDuringDeactivation ? _L10n.deactivating : _L10n.deactivate)
            }
            .disabled(viewStore.state.isDuringDeactivation)

            #if DEBUG
            Button(action: { viewStore.send(.verify) }) {
                Text("Verify License")
            }
            #endif

            Text(viewStore.state.deactivationFailedReason)
                .foregroundColor(Color.red)
                .multilineTextAlignment(.trailing)
                .padding(.bottom, 4)
        }
    }
}

struct GeneralView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralView(store: .testStore)
            .frame(height: 800)
    }
}

private typealias _L10n = L10n.General
