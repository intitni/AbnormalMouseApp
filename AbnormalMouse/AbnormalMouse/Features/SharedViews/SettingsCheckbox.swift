import SwiftUI

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

struct SettingsCheckbox_Previews: PreviewProvider {
    @State static var isOn = false

    static var previews: some View {
        SettingsCheckbox(
            isOn: $isOn,
            title: { Text("Checkbox") }
        )
        .padding(10)
    }
}
