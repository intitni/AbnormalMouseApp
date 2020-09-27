import Foundation

/// Typed UserDefaults。
@propertyWrapper
class UserDefault<Value: PropertyListStorable> {
    let key: String
    let defaultValue: Value
    var userDefaults: PropertyListStorage

    init(
        _ key: String,
        defaultValue: Value,
        userDefaults: PropertyListStorage = MemoryPropertyListStorage()
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    var wrappedValue: Value {
        get {
            (
                try? (userDefaults.object(forKey: key) as? Value.V)
                    .map(Value.makeFromPropertyListValue(value:))
            ) ?? defaultValue
        }
        set {
            if newValue.shouldRemove {
                userDefaults.removeObject(forKey: key)
            } else {
                userDefaults.set(newValue.propertyListValue, forKey: key)
            }
        }
    }
}

protocol PropertyListStorage {
    func object(forKey: String) -> Any?
    func removeObject(forKey: String)
    func set(_: Any?, forKey: String)
}

extension UserDefaults: PropertyListStorage {}

final class MemoryPropertyListStorage: PropertyListStorage {
    var content = [String: Any]()
    func object(forKey key: String) -> Any? {
        content[key]
    }

    func removeObject(forKey key: String) {
        content[key] = nil
    }

    func set(_ value: Any?, forKey key: String) {
        content[key] = value
    }
}

// MARK: - Storables

/// Anything that can be stored in UserDefaults.
protocol PropertyListStorable {
    associatedtype V: PropertyListValue
    /// The actual value to be stored in UserDefaults.
    var propertyListValue: V { get }
    /// Convert the stored data back into the type.
    static func makeFromPropertyListValue(value: V) throws -> Self
}

extension PropertyListStorable {
    /// Determine when a value is considered *not exist* in UserDefaults.
    ///
    /// e.g. When an array is empty, we may want to remove the entry from UserDefaults.
    var shouldRemove: Bool { propertyListValue.isRemoveValue }
}

/// A type than can be stored in `UserDefaults`.
protocol PropertyListValue {
    /// If the value is considered *not exist*.
    var isRemoveValue: Bool { get }
}

extension PropertyListValue {
    var isRemoveValue: Bool { false }
}

extension PropertyListStorable where V: PropertyListValue {
    var propertyListValue: Self { self }
    static func makeFromPropertyListValue(value: Self) -> Self { value }
}

// MARK: - Trivial Values

typealias TrivialPropertyListStorable = PropertyListValue & PropertyListStorable

extension Data: TrivialPropertyListStorable {}
extension String: TrivialPropertyListStorable {}
extension Date: TrivialPropertyListStorable {}
extension Bool: TrivialPropertyListStorable {}
extension Int: TrivialPropertyListStorable {}
extension Int8: TrivialPropertyListStorable {}
extension Int16: TrivialPropertyListStorable {}
extension Int32: TrivialPropertyListStorable {}
extension Int64: TrivialPropertyListStorable {}
extension UInt: TrivialPropertyListStorable {}
extension UInt8: TrivialPropertyListStorable {}
extension UInt16: TrivialPropertyListStorable {}
extension UInt32: TrivialPropertyListStorable {}
extension UInt64: TrivialPropertyListStorable {}
extension Double: TrivialPropertyListStorable {}
extension Float: TrivialPropertyListStorable {}
#if os(macOS)
extension Float80: TrivialPropertyListStorable {}
#endif

// MARK: - Array

extension Array: PropertyListValue where Element: PropertyListValue {
    var isRemoveValue: Bool { isEmpty }
}

extension Array: PropertyListStorable where Element: PropertyListStorable {
    var isRemoveValue: Bool { isEmpty }
    var propertyListValue: [Element.V] { map(\.propertyListValue) }
    static func makeFromPropertyListValue(value: [Element.V]) throws -> Self {
        try value.map(Element.makeFromPropertyListValue(value:))
    }
}

// MARK: - Optional

extension Optional: PropertyListValue where Wrapped: PropertyListValue {
    var isRemoveValue: Bool { self == nil }
}

extension Optional: PropertyListStorable where Wrapped: PropertyListStorable {
    var isRemoveValue: Bool { self == nil }
    var propertyListValue: Wrapped.V? { map(\.propertyListValue) }
    static func makeFromPropertyListValue(value: Wrapped.V?) throws -> Self {
        try value.map(Wrapped.makeFromPropertyListValue(value:))
    }
}

// MARK: - Dictionary

/// When a dictionary has values of trivial values, it's already storable in UserDefaults.
extension Dictionary: PropertyListValue
    where Key == String, Value: TrivialPropertyListStorable
{
    var isRemoveValue: Bool { isEmpty }
}

/// When a dictionary has values that are codable, it's stored as JSON in UserDefaults.
extension Dictionary: PropertyListStorable where Key == String, Value: Codable {
    var isRemoveValue: Bool { isEmpty }

    var propertyListValue: [String: Data] {
        let encoder = JSONEncoder()
        return compactMapValues { try? encoder.encode($0) }
    }

    static func makeFromPropertyListValue(value: [String: Data]) throws -> Self {
        let decoder = JSONDecoder()
        return try value.compactMapValues { try decoder.decode(Value.self, from: $0) }
    }
}

// MARK: - Raw

private struct NilError: Swift.Error {}

extension PropertyListStorable where Self: RawRepresentable, Self.RawValue: PropertyListValue {
    var propertyListValue: RawValue { rawValue }
    static func makeFromPropertyListValue(value: RawValue) throws -> Self {
        guard let it = Self(rawValue: value) else { throw NilError() }
        return it
    }
}
