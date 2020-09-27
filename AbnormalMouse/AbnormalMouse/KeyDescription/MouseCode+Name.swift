import CGEventOverride

extension MouseCode {
    var name: String {
        switch self {
        case .mouseLeft: return L10n.Shared.MouseCodeName.left
        case .mouseRight: return L10n.Shared.MouseCodeName.right
        case .mouseMiddle: return L10n.Shared.MouseCodeName.middle
        case let .mouse(n): return L10n.Shared.MouseCodeName.other(String(n + 1))
        }
    }
}
