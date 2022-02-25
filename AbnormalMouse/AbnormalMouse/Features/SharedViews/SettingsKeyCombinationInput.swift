import CGEventOverride
import SwiftUI

struct SettingsKeyCombinationInput<Title: View>: View {
    let title: Title
    let hasConflict: Bool
    let invalidReason: KeyCombinationInvalidReason?
    @State var isEditing: Bool = false
    @State var isHovering: Bool = false
    @Binding var keyCombination: KeyCombination?
    @Binding var numberOfTapsRequired: Int

    init(
        keyCombination: Binding<KeyCombination?>,
        numberOfTapsRequired: Binding<Int> = Binding.constant(1),
        hasConflict: Bool = false,
        invalidReason: KeyCombinationInvalidReason? = .none,
        @ViewBuilder title: () -> Title
    ) {
        _keyCombination = keyCombination
        _numberOfTapsRequired = numberOfTapsRequired
        self.hasConflict = hasConflict
        self.invalidReason = invalidReason
        self.title = title()
    }

    var body: some View {
        HStack(alignment: .center) {
            title
                .asWidgetTitle()

            HStack(spacing: 1) {
                modifierToggle(.shift)

                modifierToggle(.control)

                modifierToggle(.option)

                modifierToggle(.command)

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

                numberOfTapsButton()
            }
            .cornerRadius(4)
            .clipped()
            .frame(height: 22)
            .roundedCornerBackground(
                cornerRadius: 4,
                fillColor: Color(.separatorColor)
            )
            .overlay(
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(.separatorColor))
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            )
            HoverableWarning(hasConflict: hasConflict, invalidReason: invalidReason)
        }
    }
}

// MARK: - Subviews

extension SettingsKeyCombinationInput {
    private func modifierToggle(_ code: KeyboardCode) -> some View {
        func toggleBinding() -> Binding<Bool> {
            let keyDown = KeyDown.key(code.rawValue)
            return .init(
                get: {
                    keyCombination?.modifiers.contains(keyDown) ?? false
                },
                set: { insert in
                    guard let keyCombination = keyCombination else { return }
                    var modifiers = Set(keyCombination.modifiers)
                    if insert {
                        modifiers.insert(keyDown)
                    } else {
                        modifiers.remove(keyDown)
                    }
                    self.keyCombination = .init(
                        modifiers: Array(modifiers),
                        activator: keyCombination.activator
                    )
                }
            )
        }

        return Toggle(
            isOn: toggleBinding(),
            label: { Text(code.name) }
        )
        .toggleStyle(ModifierToggleStyle())
        .frame(maxWidth: 30, maxHeight: .infinity, alignment: .center)
    }

    private func editKeyCombinationButton<Label: View>(
        @ViewBuilder label: () -> Label
    ) -> some View {
        var clearButton: some View {
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
                .circleBackground(
                    fillColor: isHovering
                        ? Color(NSColor.secondaryLabelColor)
                        : .clear
                )
            }
            .buttonStyle(PlainButtonStyle())
            .animation(Animation.linear(duration: 0.1))
            .padding(.trailing, 3)
            .padding(.top, 1)
        }

        return label()
            .frame(minWidth: 100, idealWidth: 100, maxHeight: .infinity, alignment: .center)
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

    private func numberOfTapsButton() -> some View {
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
                Text("×\(numberOfTapsRequired)")
            }
        )
        .buttonStyle(ModifierButtonStyle())
        .frame(maxWidth: 30, maxHeight: .infinity, alignment: .center)
    }
}

struct HoverableWarning: View {
    @State var isHovering: Bool = false
    let text: String
    init(hasConflict: Bool, invalidReason: KeyCombinationInvalidReason?) {
        text = {
            if let reason = invalidReason {
                switch reason {
                case .leftRightMouseButtonNeedModifier:
                    return L10n.Shared.View.keyCombinationLeftRightMouseButtonNeedModifier
                case .needsKeyboardEventListener:
                    return L10n.Shared.View.keyCombinationNeedsKeyboardEventListener
                }
            } else if hasConflict {
                return L10n.Shared.View.activatorConflict
            }
            return ""
        }()
    }

    var body: some View {
        if !text.isEmpty {
            Text("⚠️")
                .onHover { isHovering = $0 }
                .popover(isPresented: $isHovering) {
                    Text(text)
                        .font(.headline)
                        .padding()
                }
        }
    }
}

// MARK: - Styles

private struct ModifierToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
                    Path(CGRect(
                        x: 0,
                        y: proxy.size.height - 2,
                        width: proxy.size.width,
                        height: 2
                    ))
                        .fill(Color(.controlAccentColor))
                        .opacity(
                            configuration.isOn
                                ? 1
                                : 0
                        )
                        .animation(Animation.linear(duration: 0.1))
                }
            )
            .onTapGesture { configuration.isOn.toggle() }
    }
}

private struct ModifierButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .foregroundColor(Color(.selectedControlTextColor))
            .background(Color(.controlBackgroundColor))
            .font(Font.system(size: 12).monospacedDigit())
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
