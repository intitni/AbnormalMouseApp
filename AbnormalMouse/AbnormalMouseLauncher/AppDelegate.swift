import Cocoa
import Combine

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var cancellable: AnyCancellable?

    func applicationDidFinishLaunching(_: Notification) {
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps
            .filter { $0.bundleIdentifier == LaunchAtLoginConstants.mainAppIdentifier }
            .isEmpty

        if !isRunning {
            cancellable = DistributedNotificationCenter.default().publisher(
                for: .killLauncher,
                object: LaunchAtLoginConstants.mainAppIdentifier as NSString
            ).sink { _ in
                NSApp.terminate(nil)
            }

            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append(LaunchAtLoginConstants.mainAppName) // main app name

            let newPath = NSString.path(withComponents: components)

            NSWorkspace.shared.launchApplication(newPath)
        } else {
            NSApp.terminate(nil)
        }
    }
}
