protocol Updater: AnyObject {
    var automaticallyChecksForUpdates: Bool { get set }
    func checkForUpdates(_ sender: Any!)
}

#if canImport(Sparkle)
import Sparkle
final class SparkleUpdater: Updater {
    var automaticallyChecksForUpdates: Bool {
        get { SUUpdater.shared()?.automaticallyChecksForUpdates ?? false }
        set { SUUpdater.shared()?.automaticallyChecksForUpdates = newValue }
    }

    func checkForUpdates(_ sender: Any!) {
        SUUpdater.shared()?.checkForUpdates(sender)
    }

    func initialize() {
        _ = SUUpdater.shared()
    }
}
#endif

final class FakeUpdater: Updater {
    var automaticallyChecksForUpdates: Bool = false
    func checkForUpdates(_: Any!) {}
}
