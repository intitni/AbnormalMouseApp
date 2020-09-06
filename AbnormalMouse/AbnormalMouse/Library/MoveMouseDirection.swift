enum MoveMouseDirection: Int, Equatable, PropertyListStorable, CaseIterable {
    case none
    case left
    case right
    case up
    case down

    func isSameAxis(to another: MoveMouseDirection) -> Bool {
        switch (self, another) {
        case (.left, .right), (.right, .left): return true
        case (.up, .down), (.down, .up): return true
        default: return self == another
        }
    }

    var propertyListValue: Int { rawValue }
    static func makeFromPropertyListValue(value: Int) -> MoveMouseDirection {
        MoveMouseDirection(rawValue: value) ?? .none
    }
}
