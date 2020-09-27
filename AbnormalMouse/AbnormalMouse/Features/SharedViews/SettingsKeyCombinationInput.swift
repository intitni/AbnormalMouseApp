import CGEventOverride
import SwiftUI

struct SettingsKeyCombinationInput<Title: View>: View {
    let title: Title
    @State var isEditing: Bool = false
    @State var isHovering: Bool = false
    @Binding var keyCombination: KeyCombination?
    @Binding var numberOfTap: Int

    init(
        keyCombination: Binding<KeyCombination?>,
        @ViewBuilder title: () -> Title
    ) {
        _keyCombination = keyCombination
        _numberOfTap = Binding.constant(1)
        self.title = title()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            title
                .asWidgetTitle()

            Spacer().frame(width: 4)

            button {
                if isEditing {
                    Text(L10n.Shared.View.enterKeyCombination)
                        .foregroundColor(Color(NSColor.placeholderTextColor))
                } else if keyCombination != nil {
                    Text(keyCombination!.name)
                        .foregroundColor(Color(NSColor.textColor))
                } else {
                    Text(L10n.Shared.View.keyCombinationNotSetup)
                        .foregroundColor(Color(NSColor.placeholderTextColor))
                }
            }

            Toggle(isOn: .constant(true), label: {
                Text("⇧")
            }).toggleStyle(ModifierToggleStyle())

            Toggle(isOn: .constant(true), label: {
                Text("⌃")
            }).toggleStyle(ModifierToggleStyle())

            Toggle(isOn: .constant(true), label: {
                Text("⌥")
            }).toggleStyle(ModifierToggleStyle())

            Toggle(isOn: .constant(true), label: {
                Text("⌘")
            }).toggleStyle(ModifierToggleStyle())
        }
    }

    private func button<Label: View>(
        @ViewBuilder label: () -> Label
    ) -> some View {
        label()
            .frame(width: 100, height: 22)
            .roundedCornerBackground(
                cornerRadius: 4,
                fillColor: Color(NSColor.controlBackgroundColor),
                strokeColor: Color(NSColor.gridColor),
                strokeWidth: 1
            )
            .overlay(
                KeyEventHandling(
                    isEditing: $isEditing,
                    onKeyReceive: {
                        if $0.contains(.key(KeyboardCode.delete.rawValue)) {
                            self.keyCombination = nil
                        } else {
                            self.keyCombination = KeyCombination($0)
                        }
                    }
                )
            )
            .onHover { self.isHovering = $0 }
            .overlay(clearButton, alignment: .trailing)
    }

    private var clearButton: some View {
        Button(action: {
            self.keyCombination = nil
            self.isEditing = false
        }) {
            Path {
                $0.move(to: .init(x: 4, y: 4))
                $0.addLine(to: .init(x: 10, y: 10))
                $0.move(to: .init(x: 4, y: 10))
                $0.addLine(to: .init(x: 10, y: 4))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, lineCap: .round))
            .foregroundColor(Color(NSColor.controlBackgroundColor))
            .frame(width: 14, height: 14)
            .circleBackground(fillColor: isHovering ? Color(NSColor.secondaryLabelColor) : .clear)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(Animation.linear(duration: 0.1))
        .padding(.trailing, 3)
        .padding(.top, 1)
    }
}

struct SettingsKeyCombinationInput_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsKeyCombinationInput(
                keyCombination: .constant(KeyCombination([.key(1)])),
                title: { Text("Key") }
            ).padding(10)

            SettingsKeyCombinationInput(
                keyCombination: .constant(KeyCombination([.key(2),
                                                          .key(KeyboardCode.command.rawValue)])),
                title: { Text("Key") }
            ).padding(10)
        }
    }
}

private struct ModifierToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
