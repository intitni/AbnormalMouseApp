import ComposableArchitecture
import SwiftUI

struct MoveToScrollSettingsScreen: View {
    let store: MoveToScrollDomain.Store

    var body: some View {
        MoveToScrollSettingsView(store: store)
            .lifeCycleWithViewStore(store, onAppear: { viewStore in
                viewStore.send(.appear)
            })
    }
}

private struct MoveToScrollSettingsView: View {
    let store: MoveToScrollDomain.Store

    var body: some View {
        ScrollView {
            SettingsSectionView(
                showSeparator: true,
                title: { Text(_L10n.View.title) },
                introduction: { Text(_L10n.View.introduction) }
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    activationCombinationSetter
                    scrollSpeedSlider
                    Text(_L10n.View.scrollSpeedSliderIntroduction)
                        .asFeatureIntroduction()

                    SettingsTips {
                        Text(_L10n.Tips.usage).tipsTitle(_L10n.TipsTitle.usage)
                        Text(_L10n.Tips.activatorChoice)
                            .tipsTitle(_L10n.TipsTitle.default)
                        Text(_L10n.Tips.pageDown)
                            .tipsTitle(_L10n.TipsTitle.default)
                        Text(_L10n.Tips.scrollBar)
                            .tipsTitle(_L10n.TipsTitle.default)
                    }
                }
            }

            SettingsSectionView(showSeparator: false) {
                inertiaEffectCheckbox
            }

            Spacer()
        }
    }

    private var activationCombinationSetter: some View {
        struct S: Equatable {
            let activationKeyCombination: KeyCombination?
            let isOverridenByModeSwitcher: Bool
            init(_ a: KeyCombination?, _ i: Bool) {
                activationKeyCombination = a
                isOverridenByModeSwitcher = i
            }
        }

        return WithViewStore(store.scope(state: \.activationKeyCombination)) { viewStore in
            SettingsKeyCombinationInput(
                keyCombination: viewStore.binding(
                    get: { $0 },
                    send: { .setActivationKeyCombination($0) }
                ),
                title: { Text(_L10n.View.activationKeyCombinationTitle) }
            )
        }
    }

    private var scrollSpeedSlider: some View {
        WithViewStore(store.scope(state: \.scrollSpeedMultiplier)) { viewStore in
            SettingsSlider(
                value: viewStore.binding(
                    get: { $0 },
                    send: { .changeScrollSpeedMultiplierTo($0) }
                ),
                in: 0.5...3.5,
                step: 0.5,
                valueDisplay: { Text(String(Double(viewStore.state))) }
            ) {
                Text(_L10n.View.scrollSpeedSliderTitle)
            }
        }
    }

    private var swipeSpeedSlider: some View {
        WithViewStore(store.scope(state: \.swipeSpeedMultiplier)) { viewStore in
            SettingsSlider(
                value: viewStore.binding(
                    get: { $0 },
                    send: { .changeSwipeSpeedMultiplierTo($0) }
                ),
                in: 0...2,
                step: 0.25,
                valueDisplay: { Text(String(Double(viewStore.state))) }
            ) {
                Text(_L10n.View.swipeSpeedSliderTitle)
            }
        }
    }

    private var inertiaEffectCheckbox: some View {
        VStack(alignment: .leading, spacing: 10) {
            WithViewStore(store.scope(state: \.isInertiaEffectEnabled)) { viewStore in
                SettingsCheckbox(isOn: viewStore.binding(
                    get: { $0 },
                    send: { _ in .toggleInertiaEffect }
                )) {
                    Text(_L10n.View.inertiaEffectCheckboxTitle)
                }
            }
            Text(_L10n.View.inertiaEffectIntroduction).asFeatureIntroduction()
        }
    }
}

private enum _L10n {
    typealias View = L10n.ScrollSettings.View
    typealias Tips = L10n.ScrollSettings.View.Tips
    typealias TipsTitle = L10n.Shared.TipsTitle
}

#if DEBUG

struct MoveToScrollSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        MoveToScrollSettingsView(store: .testStore)
            .frame(width: 500, height: 500, alignment: .center)
    }
}

#endif
