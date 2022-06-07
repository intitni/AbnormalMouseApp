import Foundation

struct Persisted: PersistedType {
    init(userDefaults: PropertyListStorage) {
        replace(userDefaults: userDefaults)
    }

    // MARK: App

    @UserDefault("LaunchCount", defaultValue: 0)
    var launchCount: Int

    // MARK: General

    let general = General()
    struct General: PersistedType {
        @UserDefault("StartAtLogin", defaultValue: false)
        var startAtLogin: Bool
    }

    let advanced = Advanced()
    struct Advanced: PersistedType {
        static func key(_ name: String) -> String { "Advanced\(name)" }
        @UserDefault(key("ListenToKeyboardEvent"), defaultValue: false)
        var listenToKeyboardEvent: Bool
        @UserDefault(key("TapGestureDelay"), defaultValue: 0)
        var tapGestureDelayInMilliseconds: Int
        @UserDefault(key("GlobalExcludedApplications"), defaultValue: [])
        var gloablExcludedApplications: [ExcludedApplication]
        struct ExcludedApplication: PropertyListStorable, Equatable, Identifiable, Hashable {
            var appName: String
            var bundleIdentifier: String
            var id: String { bundleIdentifier }

            static func makeFromPropertyListValue(
                value: [String: String]
            ) throws -> ExcludedApplication {
                .init(
                    appName: value["appName"] ?? "N/A",
                    bundleIdentifier: value["bundleIdentifier"] ?? "N/A"
                )
            }

            var propertyListValue: [String: String] {
                [
                    "appName": appName,
                    "bundleIdentifier": bundleIdentifier,
                ]
            }
        }
    }

    // MARK: Magic Scroll

    let moveToScroll = MoveToScroll()
    struct MoveToScroll: PersistedType {
        static func key(_ name: String) -> String { "MoveToScroll\(name)" }
        @UserDefault(key("KeyCombination"), defaultValue: nil)
        var keyCombination: KeyCombination?
        @UserDefault(key("NumberOfTapsRequired"), defaultValue: 1)
        var numberOfTapsRequired: Int
        @UserDefault(key("SpeedMultiplier"), defaultValue: 3)
        var scrollSpeedMultiplier: Double
        @UserDefault(key("SwipeSpeedMultiplier"), defaultValue: 0.5)
        var swipeSpeedMultiplier: Double
        @UserDefault(key("InertiaEffect"), defaultValue: true)
        var isInertiaEffectEnabled: Bool

        let halfPageScroll = HalfPageScroll()
        struct HalfPageScroll: PersistedType {
            static func key(_ name: String) -> String { "HalfPageScroll\(name)" }
            @UserDefault(key("UseMoveToScrollDoubleTap"), defaultValue: true)
            var useMoveToScrollDoubleTap: Bool
            @UserDefault(key("KeyCombination"), defaultValue: nil)
            var keyCombination: KeyCombination?
            @UserDefault(key("NumberOfTapsRequired"), defaultValue: 1)
            var numberOfTapsRequired: Int
        }
    }

    // MARK: Zoom and Rotate

    let zoomAndRotate = ZoomAndRotate()
    struct ZoomAndRotate: PersistedType {
        static func key(_ name: String) -> String { "ZoomAndRotate\(name)" }
        @UserDefault(key("KeyCombination"), defaultValue: nil)
        var keyCombination: KeyCombination?
        @UserDefault(key("NumberOfTapsRequired"), defaultValue: 1)
        var numberOfTapsRequired: Int
        @UserDefault(key("ZoomSpeedDirection"), defaultValue: .up)
        var zoomGestureDirection: MoveMouseDirection
        @UserDefault(key("RotateSpeedDirection"), defaultValue: .right)
        var rotateGestureDirection: MoveMouseDirection

        let smartZoom = SmartZoom()
        struct SmartZoom: PersistedType {
            static func key(_ name: String) -> String { "SmartZoom\(name)" }
            @UserDefault(key("UseZoomAndRotateDoubleTap"), defaultValue: true)
            var useZoomAndRotateDoubleTap: Bool
            @UserDefault(key("KeyCombination"), defaultValue: nil)
            var keyCombination: KeyCombination?
            @UserDefault(key("NumberOfTapsRequired"), defaultValue: 1)
            var numberOfTapsRequired: Int
        }
    }

    // MARK: Dock Swipe

    let dockSwipe = DockSwipe()
    struct DockSwipe: PersistedType {
        static func key(_ name: String) -> String { "DockSwipe\(name)" }
        @UserDefault(key("KeyCombination"), defaultValue: nil)
        var keyCombination: KeyCombination?
        @UserDefault(key("NumberOfTapsRequired"), defaultValue: 1)
        var numberOfTapsRequired: Int
    }
}

// MARK: - PersistedType

private protocol PersistedType {}

private extension PersistedType {
    func replace(userDefaults: PropertyListStorage) {
        for child in Mirror(reflecting: self).children {
            if let ud = child.value as? UserDefaultStorableWrapper {
                ud.userDefaults = userDefaults
            }
            if let pt = child.value as? PersistedType {
                pt.replace(userDefaults: userDefaults)
            }
        }
    }

    func reset() {
        for child in Mirror(reflecting: self).children {
            if let ud = child.value as? UserDefaultStorableWrapper {
                ud.reset()
            }
            if let pt = child.value as? PersistedType {
                pt.reset()
            }
        }
    }
}

protocol UserDefaultStorableWrapper: AnyObject {
    var userDefaults: PropertyListStorage { get set }
    func reset()
}

extension UserDefault: UserDefaultStorableWrapper {
    func reset() {
        wrappedValue = defaultValue
    }
}
