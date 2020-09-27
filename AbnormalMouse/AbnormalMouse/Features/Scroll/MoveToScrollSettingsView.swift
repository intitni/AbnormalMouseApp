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
    private enum _L10n {
        typealias View = L10n.ScrollSettings.View
        typealias Tips = L10n.ScrollSettings.View.Tips
        typealias TipsTitle = L10n.Shared.TipsTitle
    }

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
                        Text(_L10n.Tips.scrollBar)
                            .tipsTitle(_L10n.TipsTitle.default)
                    }
                }
            }

            HalfPageScrollView(store: store)

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

        return WithViewStore(
            store.scope(
                state: \.moveToScrollActivator,
                action: MoveToScrollDomain.Action.moveToScroll
            )
        ) { viewStore in
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
    }

    private var scrollSpeedSlider: some View {
        WithViewStore(store.scope(state: \.scrollSpeedMultiplier)) { viewStore in
            SettingsSlider(
                value: viewStore.binding(
                    get: { $0 },
                    send: { .moveToScroll(.changeScrollSpeedMultiplierTo($0)) }
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
                    send: { .moveToScroll(.changeSwipeSpeedMultiplierTo($0)) }
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

// MARK: - Smart Zoom

private struct HalfPageScrollView: View {
    private struct _L10n {
        typealias View = L10n.ScrollSettings.HalfPageScrollView
        typealias TipsTitle = L10n.Shared.TipsTitle
    }

    let store: MoveToScrollDomain.Store

    var body: some View {
        SettingsSectionView(
            showSeparator: true,
            title: { Text(_L10n.View.title) },
            introduction: { Text(_L10n.View.introduction) },
            content: {
                reuseCombinationToggle
                activationCombinationSetter
            }
        )
    }

    private var reuseCombinationToggle: some View {
        WithViewStore(
            store.scope(
                state: \.halfPageScrollActivator.shouldUseMoveToScrollKeyCombination,
                action: MoveToScrollDomain.Action.halfPageScroll
            )
        ) { viewStore in
            SettingsCheckbox(isOn: viewStore.binding(
                get: { $0 },
                send: { _ in .toggleUseMoveToScrollKeyCombinationDoubleTap }
            )) {
                Text(_L10n.View.doubleTapToActivate)
            }

            if viewStore.state {
                SettingsTips {
                    Text(_L10n.View.Tips.usageA).tipsTitle(_L10n.TipsTitle.usage)
                    EmptyView() // workaround function builder bug
                }
            }
        }
    }

    private var activationCombinationSetter: some View {
        WithViewStore(
            store.scope(
                state: \.halfPageScrollActivator,
                action: MoveToScrollDomain.Action.halfPageScroll
            )
        ) { viewStore in
            if !viewStore.shouldUseMoveToScrollKeyCombination {
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

                SettingsTips {
                    Text(_L10n.View.Tips.usageB).tipsTitle(_L10n.TipsTitle.usage)
                    EmptyView() // workaround function builder bug
                }
            }
        }
    }
}

#if DEBUG

struct MoveToScrollSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        MoveToScrollSettingsView(store: .testStore)
            .frame(width: 500, height: 500, alignment: .center)
    }
}

#endif
