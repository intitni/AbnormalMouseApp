enum LaunchAtLoginConstants {
    static let mainAppIdentifier = Bundle.main.bundleIdentifier ?? ""
    static let mainAppName = "AbnormalMouse"
    static let launcherIdentifier = "\(Bundle.main.bundleIdentifier ?? "")Launcher"
}

import Cocoa

extension Notification.Name {
    static let killLauncher = Self(rawValue: "KillLauncher")
}
