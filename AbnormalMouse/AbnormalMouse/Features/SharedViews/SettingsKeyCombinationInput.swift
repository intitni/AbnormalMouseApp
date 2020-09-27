import CGEventOverride
import SwiftUI

struct SettingsKeyCombinationInput<Title: View>: View {
    let title: Title
    let hasConflict: Bool
    @State var isEditing: Bool = false
    @State var isHovering: Bool = false
    @Binding var keyCombination: KeyCombination?
    @Binding var numberOfTapsRequired: Int

    init(
        keyCombination: Binding<KeyCombination?>,
        numberOfTapsRequired: Binding<Int> = Binding.constant(1),
        hasConflict: Bool = false,
        @ViewBuilder title: () -> Title
    ) {
        _keyCombination = keyCombination
        _numberOfTapsRequired = numberOfTapsRequired
        self.hasConflict = hasConflict
        self.title = title()
    }

    func toggleBinding(modifier: KeyDown) -> Binding<Bool> {
        .init(
            get: {
                keyCombination?.modifiers.contains(modifier) ?? false
            },
            set: { insert in
                guard let keyCombination = keyCombination else { return }
                var modifiers = Set(keyCombination.modifiers)
                if insert {
                    modifiers.insert(modifier)
                } else {
                    modifiers.remove(modifier)
                }
                self.keyCombination = .init(
                    modifiers: Array(modifiers),
                    activator: keyCombination.activator
                )
            }
        )
    }

    var body: some View {
        HStack(alignment: .center) {
            title
                .asWidgetTitle()

            HStack(spacing: 1) {
                Toggle(
                    isOn: toggleBinding(modifier: .key(KeyboardCode.shift.rawValue)),
                    label: { Text("⇧") }
                )
                .toggleStyle(ModifierToggleStyle())
                .padding(.leading, 1)

                Toggle(
                    isOn: toggleBinding(modifier: .key(KeyboardCode.control.rawValue)),
                    label: { Text("⌃") }
                )
                .toggleStyle(ModifierToggleStyle())

                Toggle(
                    isOn: toggleBinding(modifier: .key(KeyboardCode.option.rawValue)),
                    label: { Text("⌥") }
                )
                .toggleStyle(ModifierToggleStyle())

                Toggle(
                    isOn: toggleBinding(modifier: .key(KeyboardCode.command.rawValue)),
                    label: { Text("⌘") }
                )
                .toggleStyle(ModifierToggleStyle())

                editKeyCombinationButton {
                    if isEditing {
                        Text(L10n.Shared.View.enterKeyCombination)
                            .foregroundColor(Color(NSColor.placeholderTextColor))
                    } else if keyCombination != nil {
                        Text(keyCombination!.activator.name)
                            .foregroundColor(Color(NSColor.textColor))
                    } else {
                        Text(L10n.Shared.View.keyCombinationNotSetup)
                            .foregroundColor(Color(NSColor.placeholderTextColor))
                    }
                }

                Button(
                    action: {
                        let next = numberOfTapsRequired + 1
                        if next > 3 {
                            numberOfTapsRequired = 1
                        } else {
                            numberOfTapsRequired = next
                        }
                    },
                    label: {
                        Text("\(numberOfTapsRequired)×")
                    }
                ).buttonStyle(ModifierButtonStyle())
            }
            .cornerRadius(4)
            .clipped()
            .frame(height: 22)
            .roundedCornerBackground(
                cornerRadius: 4,
                fillColor: Color(.separatorColor),
                strokeColor: Color(.gridColor),
                strokeWidth: 1
            )

            if hasConflict {
                Text("conflict").foregroundColor(Color.red)
            }
        }
    }

    private func editKeyCombinationButton<Label: View>(
        @ViewBuilder label: () -> Label
    ) -> some View {
        label()
            .frame(width: 100, height: 21)
            .background(Color(.controlBackgroundColor))
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

// MARK: - Styles

private struct ModifierToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 30, height: 21, alignment: .center)
            .foregroundColor(
                configuration.isOn
                    ? Color(.controlAccentColor)
                    : Color(.selectedControlTextColor)
            )
            .background(
                configuration.isOn
                    ? Color(.controlBackgroundColor)
                    : Color(.controlBackgroundColor)
            )
            .overlay(
                GeometryReader { proxy in
                    configuration.isOn
                        ? AnyView(
                            Path(CGRect(
                                x: 0,
                                y: proxy.size.height - 2,
                                width: proxy.size.width,
                                height: 2
                            ))
                                .fill(Color(.controlAccentColor))
                        )
                        : AnyView(EmptyView())
                }
                .disabled(true)
            )
            .animation(.linear)
            .onTapGesture { configuration.isOn.toggle() }
    }
}

private struct ModifierButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 30, height: 21, alignment: .center)
            .foregroundColor(Color(.selectedControlTextColor))
            .background(Color(.controlBackgroundColor))
    }
}

// MARK: - Preview

struct SettingsKeyCombinationInput_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsKeyCombinationInput(
                keyCombination: .constant(KeyCombination([.key(1)])),
                hasConflict: true,
                title: { Text("Key") }
            )
            .padding(10)
            .background(Color(.windowBackgroundColor))

            SettingsKeyCombinationInput(
                keyCombination: .constant(KeyCombination([
                    .key(2),
                    .key(KeyboardCode.command.rawValue),
                ])),
                title: { Text("Key") }
            )
            .padding(10)
            .background(Color(.windowBackgroundColor))

            SettingsKeyCombinationInput(
                keyCombination: .constant(KeyCombination([
                    .key(2),
                    .key(KeyboardCode.command.rawValue),
                ])),
                title: { Text("Key") }
            )
            .padding(10)
            .background(Color(.windowBackgroundColor))
            .environment(\.colorScheme, .dark)
        }
    }
}
