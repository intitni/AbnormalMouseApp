import Foundation

@propertyWrapper
class KeychainStored<Value: KeychainStorable> {
    let key: String
    let defaultValue: Value
    var keychain: KeychainAccess

    init(_ key: String, defaultValue: Value, keychain: KeychainAccess = FakeKeychainAccess()) {
        self.key = key
        self.defaultValue = defaultValue
        self.keychain = keychain
    }

    var wrappedValue: Value {
        get {
            if Value.KV.self == String.self || Value.KV.self == String?.self {
                guard let rawValue = keychain.string(for: key) as? Value.KV
                else { return defaultValue }
                return Value.makeFromKeychainValue(value: rawValue)
            }
            guard let rawValue = keychain.data(for: key) as? Value.KV else { return defaultValue }
            return Value.makeFromKeychainValue(value: rawValue)
        }
        set {
            let storableValue = newValue.keychianValue
            if storableValue.isKeychainRemoveValue {
                keychain.remove(key: key)
            } else if let string = storableValue as? String {
                keychain.set(string, for: key)
            } else if let data = storableValue as? Data {
                keychain.set(data, for: key)
            }
        }
    }
}

protocol KeychainAccess {
    func remove(key: String)
    func set(_ string: String, for key: String)
    func string(for key: String) -> String?
    func set(_ data: Data, for key: String)
    func data(for key: String) -> Data?
}

final class FakeKeychainAccess: KeychainAccess {
    enum Storable {
        case string(String)
        case data(Data)
    }

    var contents = [String: Storable]()
    func remove(key: String) { contents[key] = nil }
    func set(_ string: String, for key: String) { contents[key] = .string(string) }
    func set(_ data: Data, for key: String) { contents[key] = .data(data) }

    func string(for key: String) -> String? {
        if case let .string(s) = contents[key] { return s }
        return nil
    }

    func data(for key: String) -> Data? {
        if case let .data(d) = contents[key] { return d }
        return nil
    }
}

// MARK: - Storables

protocol KeychainValue {
    var isKeychainRemoveValue: Bool { get }
}

protocol KeychainStorable {
    associatedtype KV: KeychainValue
    /// The actual value to be stored in UserDefaults.
    var keychianValue: KV { get }
    /// Convert the stored data back into the type.
    static func makeFromKeychainValue(value: KV) -> Self
}

extension KeychainValue {
    var isKeychainRemoveValue: Bool { false }
}

extension KeychainStorable {
    var keychianValue: Self { self }
    static func makeFromKeychainValue(value: Self) -> Self { value }
}

typealias TrivialKeychainStorable = KeychainValue & KeychainStorable

extension String: TrivialKeychainStorable {}
extension Data: TrivialKeychainStorable {}

extension Int: KeychainStorable {
    var keychianValue: String { String(self) }
    static func makeFromKeychainValue(value: String) -> Int { Int(value) ?? 0 }
}

extension TimeInterval: KeychainStorable {
    var keychianValue: String { String(self) }
    static func makeFromKeychainValue(value: String) -> TimeInterval { TimeInterval(value) ?? 0 }
}

// MARK: - Optional

extension Optional: KeychainValue where Wrapped: KeychainValue {
    var isKeychainRemoveValue: Bool { self == nil }
}

extension Optional: KeychainStorable where Wrapped: KeychainStorable {
    var isKeychainRemoveValue: Bool { self == nil }
    var keychianValue: Wrapped.KV? { map(\.keychianValue) }
    static func makeFromKeychainValue(value: Wrapped.KV?) -> Self {
        value.map(Wrapped.makeFromKeychainValue)
    }
}

// MARK: - Set

extension Set: KeychainValue, KeychainStorable where Element: Codable {
    var isKeychainRemoveValue: Bool { isEmpty }
    var keychianValue: Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }

    static func makeFromKeychainValue(value: Data) -> Self {
        (try? JSONDecoder().decode(Self.self, from: value)) ?? .init()
    }
}

// MARK: - Date

extension Date: KeychainStorable {
    var keychianValue: String { timeIntervalSince1970.keychianValue }
    static func makeFromKeychainValue(value: String) -> Self {
        Date(timeIntervalSince1970: TimeInterval.makeFromKeychainValue(value: value))
    }
}
