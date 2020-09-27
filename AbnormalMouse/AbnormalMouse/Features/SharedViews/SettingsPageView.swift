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

// MARK: - Checkbox

struct SettingsCheckbox<Title: View>: View {
    let title: Title
    @Binding var isOn: Bool

    private struct SettingsToggleStyle: ToggleStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack(alignment: .center) {
                configuration.label.font(.widgetTitle)
                    .onTapGesture(perform: { configuration.isOn.toggle() })
                Toggle(isOn: configuration.$isOn, label: { EmptyView() })
                    .toggleStyle(CheckboxToggleStyle())
            }
        }
    }

    init(
        isOn: Binding<Bool>,
        @ViewBuilder title: () -> Title
    ) {
        _isOn = isOn
        self.title = title()
    }

    var body: some View {
        Toggle(isOn: $isOn, label: { title })
            .toggleStyle(SettingsToggleStyle())
    }
}

// MARK: - Picker

struct SettingsPicker<Title: View, SelectionValue: Hashable, Content: View>: View {
    let title: Title
    let selection: Binding<SelectionValue>
    let content: () -> Content

    var body: some View {
        HStack(alignment: .center) {
            title.asWidgetTitle()
            Picker(selection: selection, label: EmptyView(), content: content)
                .frame(maxWidth: 200)
        }
    }
}

// MARK: - Slider

struct SettingsSlider<Title: View, ValueDisplay: View, Value: BinaryFloatingPoint> {
    @Binding var value: Value
    let range: ClosedRange<Value>
    let step: Value.Stride
    let title: Title
    let valueDisplay: ValueDisplay
}

extension SettingsSlider: View where Value.Stride: BinaryFloatingPoint {
    init(
        value: Binding<Value>,
        in range: ClosedRange<Value>,
        step: Value.Stride,
        @ViewBuilder valueDisplay: () -> ValueDisplay,
        @ViewBuilder title: () -> Title
    ) {
        _value = value
        self.range = range
        self.step = step
        self.title = title()
        self.valueDisplay = valueDisplay()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            title
                .asWidgetTitle()
            slider
            valueDisplay
                .foregroundColor(Color(NSColor.placeholderTextColor))
                .font(Font.introduction.monospacedDigit())
        }
    }

    private var slider: some View {
        Slider(value: $value, in: range, step: step)
            .frame(height: 20)
            .frame(maxWidth: 120)
    }
}

extension SettingsSlider where Value.Stride: BinaryFloatingPoint, ValueDisplay == EmptyView {
    init(
        value: Binding<Value>,
        in range: ClosedRange<Value>,
        step: Value.Stride,
        @ViewBuilder title: () -> Title
    ) {
        _value = value
        self.range = range
        self.step = step
        self.title = title()
        valueDisplay = EmptyView()
    }
}

// MARK: - Tips

struct SettingsTips<Content: View>: View {
    let content: Content

    init(@TipsViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { content }
            .padding(.top, 12)
    }
}

struct SettingsTipsDecorator<Content: View>: View {
    let content: Content
    @State var title: String = ""
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(Color.white)
                    .padding([.leading, .trailing], 4)
                    .padding(.top, 2)
                    .padding(.bottom, 3)
                    .roundedCornerBackground(cornerRadius: 4, fillColor: Color.accentColor)
                    .shadow(radius: 1)
                    .overlay(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.clear,
                        ]),
                        startPoint: .init(x: 0.5, y: 0),
                        endPoint: .init(x: 0.5, y: 0.1)
                    ).blur(radius: 4).cornerRadius(4))
                    .overlay(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.1),
                            Color.clear,
                        ]),
                        startPoint: .init(x: 0.5, y: 1),
                        endPoint: .init(x: 0.5, y: 0.9)
                    ).blur(radius: 4).cornerRadius(4))
            }

            content
                .asFeatureIntroduction()
        }
//        .onPreferenceChange(SettingsTipsTitleKey.self) { title in
//            self.title = title
//        } // There is a bug preventing the upper block to call! Workaround below.
        .overlayPreferenceValue(SettingsTipsTitleKey.self) { title in
            EmptyView().onAppear {
                self.title = title
            }
        }
    }
}

struct SettingsTipsTitleKey: PreferenceKey {
    static var defaultValue: String = ""
    static func reduce(value: inout String, nextValue: () -> String) {
        value = nextValue()
    }
}

extension View {
    func tipsTitle(_ title: String) -> some View {
        preference(key: SettingsTipsTitleKey.self, value: title)
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
