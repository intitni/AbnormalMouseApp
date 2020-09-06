enum LaunchAtLoginConstants {
    static let mainAppIdentifier = "com.intii.AbnormalMouse"
    static let mainAppName = "AbnormalMouse"
    static let launcherIdentifier = "com.intii.AbnormalMouseLauncher"
}

import Cocoa

extension Notification.Name {
    static let killLauncher = Self(rawValue: "KillLauncher")
}
