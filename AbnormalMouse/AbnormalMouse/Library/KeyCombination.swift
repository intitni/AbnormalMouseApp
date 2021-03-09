import CGEventOverride
import Foundation

// MARK: - Activator

struct Activator: Equatable {
    var keyCombination: KeyCombination
    var numberOfTapsRequired: Int

    init?(keyCombination: KeyCombination?, numberOfTapRequired: Int) {
        guard let combination = keyCombination else { return nil }
        self.keyCombination = combination
        numberOfTapsRequired = numberOfTapRequired
    }
}

// MARK: - KeyDown

/// Defines what the key or mouse-key is when a physical key is pressed down.
enum KeyDown: Hashable {
    /// Press down a keyboard key
    case key(Int)
    /// Press down a mouse key
    case mouse(Int)

    var name: String {
        switch self {
        case let .key(raw):
            return KeyboardCode(rawValue: raw)?.name ?? ""
        case let .mouse(raw):
            return MouseCode(rawValue: raw)?.name ?? ""
        }
    }

    var rawValue: Int {
        switch self {
        case let .key(raw),
             let .mouse(raw): return raw
        }
    }
}

extension KeyDown: Codable {
    enum CodingKeys: CodingKey {
        case type
        case code
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let code = try container.decode(Int.self, forKey: .code)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "key": self = .key(code)
        case "mouse": self = .mouse(code)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: CodingKeys.type,
                in: container,
                debugDescription: "\(type) is not a valid KeyDown type."
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .key(code):
            try container.encode("key", forKey: .type)
            try container.encode(code, forKey: .code)
        case let .mouse(code):
            try container.encode("mouse", forKey: .type)
            try container.encode(code, forKey: .code)
        }
    }
}

// MARK: - KeyCombination

/// A combination of `KeyDown`s.
struct KeyCombination: Equatable {
    let modifiers: Set<KeyDown>
    let activator: KeyDown

    init?(_ keys: Set<KeyDown>) {
        guard !keys.isEmpty else { return nil }
        var modifiers: [KeyDown] = []
        var activator: KeyDown?

        for key in keys {
            switch key {
            case let .key(raw):
                guard let keyCode = KeyboardCode(rawValue: raw) else { continue }
                if keyCode.isModifier {
                    modifiers.append(key)
                } else {
                    activator = key
                }
            case .mouse:
                activator = key
            }
        }

        guard let act = activator else { return nil }
        self.modifiers = Set(modifiers.sorted { $0.rawValue < $1.rawValue })
        self.activator = act
    }

    init(modifiers: [KeyDown], activator: KeyDown) {
        self.modifiers = Set(modifiers)
        self.activator = activator
    }

    init?(rawKeys: [Int64], rawMouse: Int64?) {
        var keys = Set(rawKeys.lazy.map(Int.init).map(KeyDown.key))
        if let mouse = rawMouse.map(Int.init).map(KeyDown.mouse) {
            keys.insert(mouse)
        }
        self.init(keys)
    }

    var name: String {
        modifiers.map(\.name).joined() + activator.name
    }

    var keyDowns: Set<KeyDown> {
        Set(modifiers + [activator])
    }

    var raw: (rawKeys: [Int64], rawMouse: Int64?) {
        var keys = [Int64]()
        var mouse: Int64?

        for case let .key(raw) in modifiers {
            keys.append(Int64(raw))
        }

        switch activator {
        case let .mouse(raw): mouse = Int64(raw)
        case let .key(raw): keys.append(Int64(raw))
        }

        return (keys, mouse)
    }

    var modifierFlags: CGEventFlags {
        let flags: [CGEventFlags] = modifiers.compactMap { keyDown in
            switch keyDown {
            case .mouse: return nil
            case let .key(code):
                let modifier = KeyboardCode(rawValue: code)
                switch modifier {
                case .command: return .maskCommand
                case .option: return .maskAlternate
                case .shift: return .maskShift
                case .control: return .maskControl
                default: return nil
                }
            }
        }

        var result: UInt64 = 0
        for f in flags {
            result |= f.rawValue
        }
        return CGEventFlags(rawValue: result)
    }

    func matchesFlags(_ flags: CGEventFlags) -> Bool {
        let modifierCodes: [Int] = modifiers.compactMap {
            guard case let .key(code) = $0 else { return nil }
            let key = KeyboardCode(rawValue: code)
            if key == .rightShift { return KeyboardCode.shift.rawValue }
            if key == .rightOption { return KeyboardCode.option.rawValue }
            if key == .rightControl { return KeyboardCode.control.rawValue }
            return code
        }
        for m in [KeyboardCode.shift, .command, .option, .control] {
            if modifierCodes.contains(m.rawValue), !flags.contains(m.modifierFlag) { return false }
            if !modifierCodes.contains(m.rawValue), flags.contains(m.modifierFlag) { return false }
        }
        return true
    }
}

private extension KeyboardCode {
    var modifierFlag: CGEventFlags {
        switch self {
        case .shift: return .maskShift
        case .command: return .maskCommand
        case .option: return .maskAlternate
        case .control: return .maskControl
        case .rightShift: return .maskShift
        case .rightOption: return .maskAlternate
        case .rightControl: return .maskControl
        default: return CGEventFlags(rawValue: .max)
        }
    }
}

extension KeyCombination: Codable, PropertyListStorable {
    var propertyListValue: String {
        do {
            let data = try JSONEncoder().encode(self)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }

    static func makeFromPropertyListValue(value: String) -> KeyCombination {
        do {
            let data = value.data(using: .utf8) ?? Data()
            let keyCombination = try JSONDecoder().decode(KeyCombination.self, from: data)
            return keyCombination
        } catch {
            return KeyCombination([.mouse(7)])!
        }
    }
}
