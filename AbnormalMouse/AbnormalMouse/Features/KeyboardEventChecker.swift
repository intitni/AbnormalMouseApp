import AppKit
import CGEventOverride
import SwiftUI

struct KeyEventHandling: NSViewRepresentable {
    @Binding var isEditing: Bool
    let onKeyReceive: (Set<KeyDown>) -> Void

    class KeyView: NSView {
        var onKeyReceive: (Set<KeyDown>) -> Void = { _ in }
        var isEditing: Binding<Bool> = .init(get: { false }, set: { _ in })

        override var acceptsFirstResponder: Bool { true }

        override func resignFirstResponder() -> Bool {
            isEditing.wrappedValue = false
            return super.resignFirstResponder()
        }

        override func keyDown(with event: NSEvent) {
            super.keyDown(with: event)
            handleEvent(event)
        }

        override func mouseDown(with event: NSEvent) {
            super.mouseDown(with: event)
            if !isEditing.wrappedValue {
                isEditing.wrappedValue = true
            }
        }

        override func otherMouseDown(with event: NSEvent) {
            super.otherMouseDown(with: event)
            handleEvent(event)
        }

        private func handleEvent(_ event: NSEvent) {
            guard isEditing.wrappedValue else { return }

            var modifierCodes = [KeyboardCode]()
            if event.modifierFlags.contains(.command) { modifierCodes.append(.command) }
            if event.modifierFlags.contains(.option) { modifierCodes.append(.option) }
            if event.modifierFlags.contains(.control) { modifierCodes.append(.control) }
            if event.modifierFlags.contains(.shift) { modifierCodes.append(.shift) }
            let modifierKeyDowns = modifierCodes.map { KeyDown.key($0.rawValue) }

            if event.type == .keyDown, let keyCode = KeyboardCode(rawValue: Int(event.keyCode)) {
                if keyCode == .delete || keyCode == .forwardDelete {
                    onKeyReceive([])
                    return
                }

                if keyCode == .escape {
                    isEditing.wrappedValue = false
                    return
                }

                let combination = Set([KeyDown.key(keyCode.rawValue)] + modifierKeyDowns)
                onKeyReceive(combination)
            } else if event.type == .otherMouseDown,
                let mouseCode = MouseCode(rawValue: Int(event.buttonNumber))
            {
                let combination = Set([KeyDown.mouse(mouseCode.rawValue)] + modifierKeyDowns)
                onKeyReceive(combination)
            }
        }
    }

    func makeNSView(context _: Context) -> NSView {
        let view = KeyView()
        if isEditing {
            DispatchQueue.main.async {
                view.window?.makeFirstResponder(view)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context _: Context) {
        guard let view = nsView as? KeyView else { return }
        view.isEditing = _isEditing
        view.onKeyReceive = {
            self.onKeyReceive($0)
            self.isEditing = false
        }
        if isEditing {
            DispatchQueue.main.async { // bring it outside of SwiftUI update context
                view.window?.makeFirstResponder(view)
            }
        }
    }
}
