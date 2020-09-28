import SwiftUI

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

struct SettingsSlider_Previews: PreviewProvider {
    @State static var value: Double = 5

    static var previews: some View {
        SettingsSlider(
            value: $value,
            in: 1...10,
            step: 1,
            valueDisplay: { Text("\(value)") },
            title: { Text("Slider") }
        )
        .padding(10)
    }
}
