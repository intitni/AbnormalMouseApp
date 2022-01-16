protocol LaunchAtLoginManagerType: AnyObject {
    var launchAtLogin: Bool { get set }
}

final class FakeLaunchAtLoginManager: LaunchAtLoginManagerType {
    var launchAtLogin: Bool = false
}
