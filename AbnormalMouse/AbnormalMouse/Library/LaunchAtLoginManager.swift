protocol LaunchAtLoginManagerType: AnyObject {
    var launchAtLogin: Bool { get set }
}

final class FakeLaunchAtLoginManager: LaunchAtLoginManagerType {
    var launchAtLogin: Bool = false
}

import LaunchAtLogin

final class LaunchAtLoginManager: LaunchAtLoginManagerType {
    var launchAtLogin: Bool {
        get { LaunchAtLogin.isEnabled }
        set { LaunchAtLogin.isEnabled = newValue }
    }
}
