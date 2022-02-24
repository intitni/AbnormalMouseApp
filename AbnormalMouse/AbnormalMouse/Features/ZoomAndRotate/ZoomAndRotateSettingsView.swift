import ComposableArchitecture
import SwiftUI

struct ZoomAndRotateSettingsScreen: View {
    let store: ZoomAndRotateDomain.Store

    var body: some View {
        ZoomAndRotateSettingsView(store: store)
            .lifeCycleWithViewStore(store, onAppear: { viewStore in
                viewStore.send(.appear)
            })
    }
}

private struct ZoomAndRotateSettingsView: View {
    let store: ZoomAndRotateDomain.Store

    var body: some View {
        ScrollView {
            ZoomAndRotateView(store: store)
            SmartZoomView(store: store)
            Spacer()
        }
    }
}

// MARK: - Zoom and Rotate

private struct ZoomAndRotateView: View {
    private enum _L10n {
        typealias View = L10n.ZoomAndRotateSettings.ZoomAndRotateView
        typealias TipsTitle = L10n.Shared.TipsTitle
    }

    let store: ZoomAndRotateDomain.Store

    var body: some View {
        SettingsSectionView(
            showSeparator: true,
            title: { Text(_L10n.View.title) },
            introduction: { Text(_L10n.View.introduction) },
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    activationCombinationSetter
                    zoomDirectionPicker
                    rotateDirectionPicker
                }

                SettingsTips {
                    Text(_L10n.View.Tips.usage).tipsTitle(_L10n.TipsTitle.usage)
                    EmptyView() // workaround function builder bug
                }
            }
        )
    }

    private var activationCombinationSetter: some View {
        WithViewStore(
            store.scope(
                state: \.zoomAndRotateActivator,
                action: ZoomAndRotateDomain.Action.zoomAndRotate
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
                invalidReason: viewStore.invalidReason,
                title: { Text(_L10n.View.activationKeyCombinationTitle) }
            )
        }
    }

    private var zoomDirectionPicker: some View {
        WithViewStore(store.scope(state: \.zoomGestureDirection)) { viewStore in
            SettingsPicker(
                title: Text(_L10n.View.zoomDirectionTitle),
                selection: viewStore.binding(
                    get: { $0.rawValue },
                    send: { .changeZoomGestureDirectionToOption($0) }
                )
            ) {
                ForEach(MoveMouseDirection.allCases, id: \.rawValue) { option in
                    Text({
                        switch option {
                        case .none: return _L10n.View.zoomDirectionNone
                        case .left: return _L10n.View.zoomDirectionLeft
                        case .right: return _L10n.View.zoomDirectionRight
                        case .up: return _L10n.View.zoomDirectionUp
                        case .down: return _L10n.View.zoomDirectionDown
                        }
                    }() as String)
                }
            }
        }
    }

    private var rotateDirectionPicker: some View {
        WithViewStore(store.scope(state: \.rotateGestureDirection)) { viewStore in
            SettingsPicker(
                title: Text(_L10n.View.rotateDirectionTitle),
                selection: viewStore.binding(
                    get: { $0.rawValue },
                    send: { .changeRotateGestureDirectionToOption($0) }
                )
            ) {
                ForEach(MoveMouseDirection.allCases, id: \.rawValue) { option in
                    Text({
                        switch option {
                        case .none: return _L10n.View.rotateDirectionNone
                        case .left: return _L10n.View.rotateDirectionLeft
                        case .right: return _L10n.View.rotateDirectionRight
                        case .up: return _L10n.View.rotateDirectionUp
                        case .down: return _L10n.View.rotateDirectionDown
                        }
                    }() as String)
                }
            }
        }
    }
}

// MARK: - Smart Zoom

private struct SmartZoomView: View {
    private enum _L10n {
        typealias View = L10n.ZoomAndRotateSettings.SmartZoomView
        typealias TipsTitle = L10n.Shared.TipsTitle
    }

    let store: ZoomAndRotateDomain.Store

    var body: some View {
        SettingsSectionView(
            showSeparator: false,
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
                state: \.smartZoomActivator.shouldUseZoomAndRotateKeyCombinationDoubleTap,
                action: ZoomAndRotateDomain.Action.smartZoom
            )
        ) { viewStore in
            SettingsCheckbox(isOn: viewStore.binding(
                get: { $0 },
                send: { _ in .toggleUseZoomAndRotateKeyCombinationDoubleTap }
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
                state: \.smartZoomActivator,
                action: ZoomAndRotateDomain.Action.smartZoom
            )
        ) { viewStore in
            if !viewStore.shouldUseZoomAndRotateKeyCombinationDoubleTap {
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
                    invalidReason: viewStore.invalidReason,
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

// MARK: - Previews

struct ZoomAndRotateSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ZoomAndRotateSettingsView(store: .testStore)
            .frame(width: 500, height: 500, alignment: .center)
    }
}

// MARK: - Attributed Text View

struct AttributedLabel: NSViewRepresentable {
    let attributedString: NSAttributedString

    class Coordinator {
        let textContainer = NSTextContainer()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context _: Context) -> NSTextView {
        let it = NSTextView()
        it.isEditable = false
        it.backgroundColor = .clear
        it.font = .systemFont(ofSize: 14)
        it.textColor = .gray
        it.textContainerInset = .zero
        return it
    }

    func updateNSView(_ nsView: NSTextView, context _: Context) {
        nsView.textStorage?.setAttributedString(attributedString)
    }
}

extension NSAttributedString {
    convenience init(string: String, linkTo url: URL) {
        self.init(string: string, attributes: [
            .link: url,
            .foregroundColor: NSColor.linkColor,
        ])
    }
}
