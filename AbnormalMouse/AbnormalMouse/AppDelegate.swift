import CGEventOverride
import Cocoa
import Combine
import ComposableArchitecture
import ServiceManagement
import SwiftUI

// MARK: - Global Scope

#if PREVIEW
private let userDefaults = MemoryPropertyListStorage()
private let persisted = Persisted(userDefaults: userDefaults)
private let eventHook = FakeCGEventHook()
private let purchaseManager = FakePurchaseManager()
private let launchAtLoginManager = FakeLaunchAtLoginManager()
private let updater = FakeUpdater()
#else
private let persisted = Persisted(userDefaults: UserDefaults.standard)
private let eoi: Set<CGEventType> = {
    if persisted.advanced.listenToKeyboardEvent {
        return [
            .keyDown, .keyUp, .mouseMoved,
            .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseUp, .rightMouseDown, .rightMouseDragged,
            .otherMouseUp, .otherMouseDown, .otherMouseDragged,
        ]
    }
    return [
        .leftMouseDown, .leftMouseUp, .leftMouseDragged,
        .rightMouseUp, .rightMouseDown, .rightMouseDragged,
        .otherMouseUp, .otherMouseDown, .otherMouseDragged,
    ]
}()

private let eventHook = CGEventHook(eventsOfInterest: eoi)
private let purchaseManager = RealPurchaseManager()
private let launchAtLoginManager = LaunchAtLoginManager()
private let updater = SparkleUpdater()
#endif

private let store = TheApp.Store(
    initialState: .init(),
    reducer: TheApp.reducer,
    environment: .live(environment: .init(
        persisted: persisted,
        purchaseManager: purchaseManager,
        updater: updater,
        activatorConflictChecker: .init(persisted: Readonly(persisted)),
        activatorValidityChecker: .init(),
        launchAtLoginManager: launchAtLoginManager,
        overrideControllers: [
            MoveToScrollController(
                persisted: Readonly(persisted.moveToScroll),
                hook: eventHook
            ),
            ZoomAndRotateController(
                persisted: Readonly(persisted.zoomAndRotate),
                hook: eventHook
            ),
            DockSwipeController(
                persisted: Readonly(persisted.dockSwipe),
                hook: eventHook
            ),
        ]
    ))
)

// MARK: - AppDelegate

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    private var statusBarItem: NSStatusItem!
    private var authorizationCheckTimer: Timer?
    private var cancellables = [AnyCancellable]()

    deinit {
        authorizationCheckTimer?.invalidate()
    }

    #if !PREVIEW
    func applicationWillFinishLaunching(_: Notification) {
        if EnvironmentVariable.isUnitTest { return }
        LetsMove.shared.moveToApplicationsFolderIfNecessary()
    }
    #endif

    func applicationDidFinishLaunching(_: Notification) {
        if EnvironmentVariable.isUnitTest { return }
        buildStatusBarMenu()

        #if !PREVIEW
        defer { persisted.launchCount += 1 }
        purchaseManager.startTrialIfNeeded()
        startupPurchaseManager()
        observeForSleeps()
        presentWindowIfNeeded()
        #endif
    }

    func applicationWillBecomeActive(_: Notification) {
        if EnvironmentVariable.isUnitTest { return }
        #if !PREVIEW
        checkAuthorization()
        activateEventHookIfPossible()
        purchaseManager.updatePurchaseState()
        #endif
    }
}

extension AppDelegate {
    @objc private func showSettingsWindow() {
        let contentView = MainScreen(store: store.scope(
            state: \.mainScreen,
            action: { .main($0) }
        ))
        NSApp.setActivationPolicy(.regular)
        if let window = window {
            window.makeKeyAndOrderFront(self)
        } else {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 700, height: 400),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.delegate = self
            window.canHide = false
            window.title = L10n.Shared.appName
            window.isReleasedWhenClosed = false
            window.center()
            window.setFrameAutosaveName("Main Window")
            window.contentView = NSHostingView(
                rootView:
                contentView
                    .frame(minWidth: 800, minHeight: 500)
            )
            window.makeKeyAndOrderFront(self)
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func buildStatusBarMenu() {
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(
            withLength: NSStatusItem.squareLength
        )
        statusBarItem.button?.image = Asset.iconMenuBar.image

        let statusBarMenu = NSMenu(title: "Status Bar Menu")
        statusBarMenu.delegate = self
        statusBarItem.menu = statusBarMenu

        let appStatusItem = NSMenuItem(
            title: L10n.Shared.appName,
            action: nil,
            keyEquivalent: ""
        )

        let purchaseStatusItem = NSMenuItem(
            title: L10n.StatusBarMenu.PurchaseStatus.fetching,
            action: nil,
            keyEquivalent: ""
        )

        let showSettingsItem = NSMenuItem(
            title: L10n.StatusBarMenu.showPreferences,
            action: #selector(showSettingsWindow),
            keyEquivalent: ""
        )
        showSettingsItem.target = self

        let quitItem = NSMenuItem(
            title: L10n.StatusBarMenu.quit,
            action: #selector(quit),
            keyEquivalent: ""
        )
        quitItem.target = self

        statusBarMenu.addItem(appStatusItem)
        statusBarMenu.addItem(.separator())
        statusBarMenu.addItem(purchaseStatusItem)
        statusBarMenu.addItem(showSettingsItem)
        statusBarMenu.addItem(quitItem)

        purchaseManager.purchaseState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [item = purchaseStatusItem, weak self] state in
                item.isHidden = false
                switch state {
                case .initial:
                    item.title = L10n.StatusBarMenu.PurchaseStatus.fetching
                    self?.deactivateEventHook()
                case .trialDidEnd:
                    item.title = L10n.StatusBarMenu.PurchaseStatus.ended
                    self?.deactivateEventHook()
                case let .trialMode(daysLeft):
                    if daysLeft > 0 {
                        self?.activateEventHookIfPossible()
                    } else {
                        self?.deactivateEventHook()
                    }
                    item.title = L10n.StatusBarMenu.PurchaseStatus.trial(daysLeft)
                case .activated:
                    self?.activateEventHookIfPossible()
                    item.title = L10n.StatusBarMenu.PurchaseStatus.activated
                case .activatedInvalid:
                    self?.deactivateEventHook()
                    item.title = L10n.StatusBarMenu.PurchaseStatus.invalid
                case .activatedUnverifiedForALongTime:
                    self?.deactivateEventHook()
                    item.title = L10n.StatusBarMenu.PurchaseStatus.cantVerify
                case .activatedRefunded:
                    self?.deactivateEventHook()
                    item.title = L10n.StatusBarMenu.PurchaseStatus.refunded
                case .activatedMaybePirateUser:
                    self?.deactivateEventHook()
                    item.title = L10n.StatusBarMenu.PurchaseStatus.invalid
                }
            }
            .store(in: &cancellables)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_: NSMenu) {
        checkAuthorization()
        purchaseManager.updatePurchaseState()
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

extension AppDelegate {
    private func checkAuthorization() {
        let isTrusted = AXIsProcessTrusted()
        ViewStore(store).send(.setAccessibilityAuthorized(isTrusted))
        statusBarItem?.menu?.item(at: 0)?.title = eventHook.isEnabled
            ? L10n.StatusBarMenu.isEnabled
            : L10n.StatusBarMenu.isDisabled

        if isTrusted {
            authorizationCheckTimer?.invalidate()
            authorizationCheckTimer = nil
        } else if authorizationCheckTimer == nil {
            authorizationCheckTimer = Timer(timeInterval: 3, repeats: true) { [weak self] _ in
                self?.checkAuthorization()
            }
            RunLoop.current.add(authorizationCheckTimer!, forMode: .common)
        }
    }

    private func startupPurchaseManager() {
        let viewStore = ViewStore(store)
        viewStore.send(.observePurchaseState)
        viewStore.send(.verifyLicense)
    }

    private func activateEventHookIfPossible() {
        let purchaseState = purchaseManager.purchaseState.value
        if case .initial = purchaseState { return }
        if case .activatedInvalid = purchaseState { return }
        if case .trialDidEnd = purchaseState { return }
        if case let .trialMode(d) = purchaseState, d <= 0 { return }
        eventHook.activateIfPossible()
    }

    private func deactivateEventHook() {
        eventHook.deactivate()
    }

    private func observeForSleeps() {
        Publishers.Merge(
            NSWorkspace.shared.notificationCenter
                .publisher(for: NSWorkspace.willSleepNotification),
            NSWorkspace.shared.notificationCenter
                .publisher(for: NSWorkspace.screensDidSleepNotification)
        )
        .debounce(for: 0.1, scheduler: DispatchQueue.main)
        .sink(receiveValue: { [weak self] _ in
            self?.deactivateEventHook()
        })
        .store(in: &cancellables)

        Publishers.Merge(
            NSWorkspace.shared.notificationCenter
                .publisher(for: NSWorkspace.didWakeNotification),
            NSWorkspace.shared.notificationCenter
                .publisher(for: NSWorkspace.screensDidWakeNotification)
        )
        .debounce(for: 1, scheduler: DispatchQueue.main)
        .sink(receiveValue: { [weak self] _ in
            self?.activateEventHookIfPossible()
            purchaseManager.updatePurchaseState()
            purchaseManager.reverifyIfNeeded()
        })
        .store(in: &cancellables)
    }

    private func presentWindowIfNeeded() {
        if persisted.launchCount == 0 {
            showSettingsWindow()
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

enum EnvironmentVariable {
    static var isUnitTest: Bool {
        ProcessInfo.processInfo.environment["IS_UNIT_TEST"] == "YES"
    }

    static var neverWaitAtLeast: Bool {
        ProcessInfo.processInfo.environment["NEVER_WAIT_AT_LEAST"] == "YES"
    }
}
