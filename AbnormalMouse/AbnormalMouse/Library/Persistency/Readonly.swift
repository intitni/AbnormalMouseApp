/// `Readonly` provides a readonly interface of the wrapped object. Properties of wrapped object
/// can be directly accessed through this wrapper, but none of them will be mutatable.
@dynamicMemberLookup
struct Readonly<T> {
    private let wrappedValue: T

    init(_ object: T) {
        wrappedValue = object
    }

    subscript<V>(dynamicMember member: KeyPath<T, V>) -> V {
        wrappedValue[keyPath: member]
    }
}
