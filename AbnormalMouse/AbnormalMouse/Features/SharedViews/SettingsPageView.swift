import CGEventOverride
import SwiftUI

// MARK: - Section

struct SettingsSectionView<Title: View, Introduction: View, Content: View>: View {
    let title: Title?
    let introduction: Introduction?
    let content: Content
    let showSeparator: Bool

    init(
        showSeparator: Bool = false,
        @ViewBuilder title: () -> Title?,
        @ViewBuilder introduction: () -> Introduction?,
        @ViewBuilder content: () -> Content
    ) {
        self.showSeparator = showSeparator
        self.title = title()
        self.introduction = introduction()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 4) {
                title
                    .asFeatureTitle()
                introduction?
                    .asFeatureIntroduction()
            }
            .padding(
                .bottom,
                introduction == nil
                    ? title == nil ? 0 : 8
                    : 20
            )
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .multilineTextAlignment(.leading)
        .padding(.bottom, 20)
        .overlay(separator)
        .padding(.init(top: 20, leading: 20, bottom: 0, trailing: 20))
    }

    private var separator: some View {
        Group {
            if showSeparator {
                GeometryReader { proxy in
                    Path { p in
                        p.move(to: .init(x: 0, y: proxy.size.height))
                        p.addLine(to: .init(x: proxy.size.width, y: proxy.size.height))
                    }
                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                }
            }
        }
    }
}

extension SettingsSectionView where Introduction == EmptyView {
    init(
        showSeparator: Bool = false,
        @ViewBuilder title: () -> Title,
        @ViewBuilder content: () -> Content
    ) {
        self.showSeparator = showSeparator
        self.title = title()
        introduction = nil
        self.content = content()
    }
}

extension SettingsSectionView where Title == EmptyView, Introduction == EmptyView {
    init(
        showSeparator: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.showSeparator = showSeparator
        title = nil
        introduction = nil
        self.content = content()
    }
}

// MARK: - Preview

struct SettingsSectionView_Previews: PreviewProvider {
    @State static var sliderValue: Double = 3
    @State static var toggle: Bool = false
    @State static var keyCombination: KeyCombination? = KeyCombination([.key(1)])
    @State static var pickerSelection: Int = 0
    static var previews: some View {
        ScrollView {
            VStack(spacing: 0) {
                SettingsSectionView(
                    showSeparator: true,
                    title: { Text("Title") },
                    introduction: {
                        Text(
                            """
                            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin nec tortor risus. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Aenean metus purus, placerat cursus tempus dictum, bibendum sit amet dolor. Etiam venenatis lacinia sapien sodales rutrum. Cras cursus nisl nec porttitor tempus. Praesent ac lacus blandit, bibendum elit in, sodales velit. Aenean et gravida justo. Nulla eget interdum quam. Proin gravida massa sit amet ultricies sagittis. Quisque bibendum lorem massa, ac laoreet sem dapibus in. Praesent maximus tortor libero, at dignissim eros facilisis semper. Nulla porta, felis sed aliquet vestibulum, lacus tellus auctor enim, at pellentesque metus sapien ut justo.
                            """
                        )
                    },
                    content: {
                        SettingsKeyCombinationInput(
                            keyCombination: $keyCombination,
                            title: { Text("Key") }
                        )

                        SettingsCheckbox(
                            isOn: $toggle,
                            title: { Text("Checkbox") }
                        )

                        SettingsSlider(
                            value: $sliderValue,
                            in: 1...5,
                            step: 1,
                            valueDisplay: { Text("\(sliderValue)") },
                            title: { Text("Slider") }
                        )

                        SettingsTips {
                            Text("tips 1").tipsTitle("Usage")
                            Text("tips 2").tipsTitle("123")
                            EmptyView().tipsTitle("")
                        }
                    }
                )

                SettingsSectionView(
                    showSeparator: false,
                    title: { Text("Title") },
                    introduction: {
                        Text(
                            """
                            Lorem ipsum dolor sit amet
                            """
                        )
                    },
                    content: {
                        SettingsPicker(
                            title: Text("Picker"),
                            selection: $pickerSelection
                        ) {
                            ForEach(1..<4) {
                                Text(String($0))
                            }
                        }

                        SettingsCheckbox(
                            isOn: .init(
                                get: { true },
                                set: { _ in }
                            ),
                            title: { Text("Checkbox") }
                        )

                        SettingsSlider(
                            value: .init(get: { 3 }, set: { _ in }),
                            in: 1...10,
                            step: 1,
                            title: { Text("Slider") }
                        )
                    }
                )
            }
        }
        .frame(height: 600)
    }
}
