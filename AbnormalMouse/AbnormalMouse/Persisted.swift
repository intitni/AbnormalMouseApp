import Foundation
import KeychainAccess

struct Persisted: PersistedType {
    init(userDefaults: PropertyListStorage, keychainAccess: KeychainAccess) {
        replace(userDefaults: userDefaults, keychainAccess: keychainAccess)
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
        @UserDefault(key("ListenToKeyboardEvent"), defaultValue: true)
        var listenToKeyboardEvent: Bool
        @UserDefault(key("TapGestureDelay"), defaultValue: 0)
        var tapGestureDelayInMilliseconds: Int
    }

    // MARK: Magic Scroll

    let moveToScroll = MoveToScroll()
    struct MoveToScroll: PersistedType {
        static func key(_ name: String) -> String { "MoveToScroll\(name)" }
        @UserDefault(key("KeyCombination"), defaultValue: nil)
        var keyCombination: KeyCombination?
        @UserDefault(key("SpeedMultiplier"), defaultValue: 3)
        var scrollSpeedMultiplier: Double
        @UserDefault(key("SwipeSpeedMultiplier"), defaultValue: 0.5)
        var swipeSpeedMultiplier: Double
        @UserDefault(key("InertiaEffect"), defaultValue: true)
        var isInertiaEffectEnabled: Bool
    }

    // MARK: Zoom and Rotate

    let zoomAndRotate = ZoomAndRotate()
    struct ZoomAndRotate: PersistedType {
        static func key(_ name: String) -> String { "ZoomAndRotate\(name)" }
        @UserDefault(key("KeyCombination"), defaultValue: nil)
        var keyCombination: KeyCombination?
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
        }
    }

    // MARK: Dock Swipe

    let dockSwipe = DockSwipe()
    struct DockSwipe: PersistedType {
        static func key(_ name: String) -> String { "DockSwipe\(name)" }
        @UserDefault(key("KeyCombination"), defaultValue: nil)
        var keyCombination: KeyCombination?
    }
}

// MARK: - PersistedType

private protocol PersistedType {}

extension PersistedType {
    fileprivate func replace(userDefaults: PropertyListStorage, keychainAccess: KeychainAccess) {
        for child in Mirror(reflecting: self).children {
            if let ud = child.value as? UserDefaultStorableWrapper {
                ud.userDefaults = userDefaults
            }
            if let ud = child.value as? KeychainStorableWrapper {
                ud.keychain = keychainAccess
            }
            if let pt = child.value as? PersistedType {
                pt.replace(userDefaults: userDefaults, keychainAccess: keychainAccess)
            }
        }
    }

    fileprivate func reset() {
        for child in Mirror(reflecting: self).children {
            if let ud = child.value as? UserDefaultStorableWrapper {
                ud.reset()
            }
            if let ud = child.value as? KeychainStorableWrapper {
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

// MARK: - Keychain

protocol KeychainStorableWrapper: AnyObject {
    var keychain: KeychainAccess { get set }
    func reset()
}

extension KeychainStored: KeychainStorableWrapper {
    func reset() {
        wrappedValue = defaultValue
    }
}

extension Keychain: KeychainAccess {
    public func set(_ string: String, for key: String) {
        try? set(string, key: key)
    }

    public func set(_ data: Data, for key: String) {
        try? set(data, key: key)
    }

    public func remove(key: String) {
        try? remove(key)
    }

    public func string(for key: String) -> String? {
        try? getString(key)
    }

    public func data(for key: String) -> Data? {
        try? getData(key)
    }
}
