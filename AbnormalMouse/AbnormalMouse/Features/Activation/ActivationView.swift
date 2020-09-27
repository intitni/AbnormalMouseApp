import ComposableArchitecture
import SwiftUI

struct ActivationScreen: View {
    let store: ActivationDomain.Store

    var body: some View {
        ActivationView(store: store)
    }
}

private struct ActivationView: View {
    let store: ActivationDomain.Store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(_L10n.instruction)
                .asWidgetTitle()

            Spacer().frame(height: 8)

            WithViewStore(store.scope(state: \.licenseKey)) { viewStore in
                self.inputBox(
                    text: viewStore.binding(
                        get: { $0 },
                        send: { .updateLicenseKey($0) }
                    ),
                    title: { Text(_L10n.licenseKeyTitle) }
                )
            }

            Spacer().frame(height: 8)

            WithViewStore(store.scope(state: \.email)) { viewStore in
                self.inputBox(
                    text: viewStore.binding(
                        get: { $0 },
                        send: { .updateEmail($0) }
                    ),
                    title: { Text(_L10n.emailTitle) }
                )
            }

            warningMessage.frame(height: 40)
            buttons
        }
        .padding(16)
        .frame(width: 500)
    }

    func inputBox<Title>(
        text: Binding<String>,
        title: () -> Title
    ) -> some View where Title: View {
        VStack(alignment: .leading, spacing: 4) {
            title()
            TextField("", text: text)
        }
    }

    var warningMessage: some View {
        Spacer()
            .frame(maxWidth: .infinity)
            .overlay(
                WithViewStore(store.scope(state: \.activationState)) { viewStore in
                    Text({
                        if case let .failed(reason) = viewStore.state { return reason }
                        return ""
                    }() as String)
                        .foregroundColor(Color.red)
                        .multilineTextAlignment(.trailing)
                        .padding(.bottom, 4)
                },
                alignment: .bottomTrailing
            )
    }

    var buttons: some View {
        WithViewStore(store) { viewStore in
            HStack {
                Button(action: { viewStore.send(.dismiss) }) {
                    Text(_L10n.Button.cancel)
                }
                Spacer()
                HStack {
                    Button(action: { viewStore.send(.buyNow) }) {
                        Text(_L10n.Button.buyNow)
                            .frame(minWidth: 70)
                    }

                    Button(action: { viewStore.send(.activate) }) {
                        Text({
                            if case .activating = viewStore.state.activationState {
                                return _L10n.Button.activating
                            }
                            return _L10n.Button.activate
                        }() as String)
                            .frame(minWidth: 70)
                    }
                    .disabled(!viewStore.state.isActivateButtonEnabled)
                }
            }
        }
    }
}

struct ActivationView_Previews: PreviewProvider {
    static var previews: some View {
        ActivationView(store: .testStore { state in
            state.activationState = .failed(reason: "Failed for some reasons.")
        })
    }
}

private typealias _L10n = L10n.Activation
