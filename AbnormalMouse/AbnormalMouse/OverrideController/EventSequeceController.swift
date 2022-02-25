import AppKit
import Foundation

/// The logical refresh rate.
let virtualRefreshRate: Double = 60
/// The actual physical refresh rate of main display.
var refreshRate: Double {
    max(CGDisplayCopyDisplayMode(CGMainDisplayID())?.refreshRate ?? virtualRefreshRate, 60)
}

var refreshSpeedScale: Double { refreshRate / virtualRefreshRate }

/// Used to send a sequence of event to fire one per each frame.
final class EventSequenceController {
    typealias Task = () -> Void

    static var shared: EventSequenceController? {
        if let controller = _shared { return controller }
        _shared = EventSequenceController()
        return _shared
    }

    private static var _shared: EventSequenceController?

    private var queuedTasks = [AnyHashable: [Task]]()
    private var displayLink: CVDisplayLink!
    private var isDisplayLinkStarted: Bool = false

    private init?() {
        _ = CVDisplayLinkCreateWithCGDisplay(CGMainDisplayID(), &displayLink)
        guard displayLink != nil else { return nil }
        CVDisplayLinkSetOutputHandler(displayLink) { [weak self] _, _, _, _, _ in
            guard let self = self else { return kCVReturnSuccess }
            let tasks: [Task] = DispatchQueue.default.sync {
                var runNow = [Task]()
                var temp = self.queuedTasks
                for (key, _list) in self.queuedTasks {
                    var list = _list
                    guard !list.isEmpty else { continue }
                    runNow.append(list.removeFirst())
                    temp[key] = list
                }
                self.queuedTasks = temp
                return runNow
            }

            // for better performance, we disable displayLink when there is no more event to send.
            if tasks.isEmpty {
                self.disableLink()
                return kCVReturnDisplayLinkNotRunning
            }
            tasks.forEach { $0() }
            return kCVReturnSuccess
        }
    }

    /// Schedule a sequence of event to be fired for a specific feature.
    func scheduleTasks(_ tasks: [() -> Void], forKey key: AnyHashable) {
        DispatchQueue.main.async {
            if !tasks.isEmpty {
                CVDisplayLinkStart(self.displayLink)
                self.isDisplayLinkStarted = true
            }
            self.queuedTasks[key] = tasks
        }
    }

    private func disableLink() {
        DispatchQueue.main.async {
            CVDisplayLinkStop(self.displayLink)
            self.isDisplayLinkStarted = false
        }
    }
}
