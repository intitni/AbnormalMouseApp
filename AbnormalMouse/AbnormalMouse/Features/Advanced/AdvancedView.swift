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
            settings
            if #available(macOS 11.0, *) {
                excludedApps
            }
            Spacer()
        }
    }

    private var settings: some View {
        SettingsSectionView(
            showSeparator: false,
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

    @available(macOS 11.0, *)
    private var excludedApps: some View {
        SettingsSectionView(showSeparator: false, content: {
            WithViewStore(store) { viewStore in
                Text(_L10n.View.excludeListTitle).asWidgetTitle()
                VStack(alignment: .leading, spacing: 0) {
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(viewStore.excludedApps) { app in
                                Button(action: {
                                    viewStore.send(.selectExcludedApp(app))
                                }) {
                                    HStack {
                                        Text("\(app.appName) (\(app.bundleIdentifier))")
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                }
                                .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                                .roundedCornerBackground(
                                    cornerRadius: 4,
                                    fillColor: viewStore.state.selectedExcludedApp == app
                                        ? Color(NSColor.selectedControlColor)
                                        : .clear,
                                    strokeColor: .clear,
                                    strokeWidth: 0,
                                    shadow: nil
                                )
                                .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
                                .frame(maxWidth: .infinity)
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    .background(Color.clear)
                    .frame(maxWidth: 320, minHeight: 120, maxHeight: 120)

                    HStack {
                        Menu("+") {
                            ForEach(viewStore.availableApplications) { app in
                                Button(action: {
                                    viewStore.send(.addExcludedApp(app))
                                }) {
                                    Text("\(app.appName) (\(app.bundleIdentifier))")
                                }
                            }
                        }
                        .frame(width: 40)

                        Button(action: {
                            viewStore.send(.removeSelectedExcludedApp)
                        }) {
                            Image(nsImage: NSImage(named: NSImage.touchBarDeleteTemplateName)!)
                        }.buttonStyle(.plain)
                    }
                    .padding(EdgeInsets(top: 0, leading: 6, bottom: 6, trailing: 6))
                }
                .roundedCornerBackground(
                    cornerRadius: 2,
                    fillColor: Color(NSColor.controlBackgroundColor),
                    strokeColor: Color(NSColor.separatorColor),
                    strokeWidth: 1,
                    shadow: nil
                )
            }
        })
    }
}

private enum _L10n {
    typealias View = L10n.Advanced.View
}

struct AdvancedView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedView(store: .init(
            initialState: .init(
                listenToKeyboardEvent: true,
                excludedApps: [
                    .init(appName: "A", bundleIdentifier: "A"),
                    .init(appName: "B", bundleIdentifier: "B"),
                ],
                availableApplications: [
                    .init(appName: "A", bundleIdentifier: "A"),
                    .init(appName: "B", bundleIdentifier: "B"),
                ]
            ),
            reducer: AdvancedDomain.reducer,
            environment: .live(environment: .init(persisted: .init()))
        ))
    }
}
