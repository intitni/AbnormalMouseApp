import CGEventOverride
import ComposableArchitecture
import XCTest

@testable import AbnormalMouse

class ZoomAndScrollDomainTests: XCTestCase {
    let suiteName = String(describing: ZoomAndScrollDomainTests.self)

    override func tearDown() {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    func testSettings() throws {
        let persisted = Persisted(
            userDefaults: UserDefaults(suiteName: suiteName)!,
            keychainAccess: FakeKeychainAccess()
        )
        defer { UserDefaults().removeSuite(named: suiteName) }
        persisted.zoomAndRotate.rotateGestureDirection = .none
        persisted.zoomAndRotate.zoomGestureDirection = .none
        persisted.zoomAndRotate.keyCombination = nil
        persisted.zoomAndRotate.smartZoom.keyCombination = nil
        persisted.zoomAndRotate.smartZoom.useZoomAndRotateDoubleTap = false
        persisted.moveToScroll.isInertiaEffectEnabled = true

        let overrideController = FakeOverrideController()
        let initialState = ZoomAndRotateDomain.State(
            from: persisted.zoomAndRotate,
            moveToScrollPersisted: persisted.moveToScroll
        )
        let store = TestStore(
            initialState: initialState,
            reducer: ZoomAndRotateDomain.reducer,
            environment: ZoomAndRotateDomain.Environment(
                persisted: persisted.zoomAndRotate,
                moveToScrollPersisted: persisted.moveToScroll,
                openURL: { _ in }
            )
        )

        let keyCombination = KeyCombination(Set([
            .key(KeyboardCode.command.rawValue),
            .key(KeyboardCode.a.rawValue),
        ]))

        XCTAssertEqual(initialState.zoomAndRotateActivationKeyCombination, nil)
        XCTAssertEqual(initialState.smartZoomActivationKeyCombination, nil)
        XCTAssertEqual(initialState.zoomGestureDirection, .none)
        XCTAssertEqual(initialState.rotateGestureDirection, .none)
        XCTAssertEqual(initialState.shouldSmartZoomUseZoomAndRotateKeyCombinationDoubleTap, false)
        XCTAssertEqual(initialState.isInertiaEffectEnabled, true)

        // key combination

        store.assert(
            .send(.setZoomAndRotateActivationKeyCombination(keyCombination)) {
                $0.zoomAndRotateActivationKeyCombination = keyCombination
            },
            .send(.setSmartZoomActivationKeyCombination(keyCombination)) {
                $0.smartZoomActivationKeyCombination = keyCombination
            },
            .do {
                XCTAssertEqual(persisted.zoomAndRotate.keyCombination, keyCombination)
                XCTAssertEqual(persisted.zoomAndRotate.smartZoom.keyCombination, keyCombination)
            },
            .send(.clearZoomAndRotateActivationKeyCombination) {
                $0.zoomAndRotateActivationKeyCombination = nil
            },
            .send(.clearSmartZoomActivationKeyCombination) {
                $0.smartZoomActivationKeyCombination = nil
            },
            .do {
                XCTAssertEqual(persisted.zoomAndRotate.keyCombination, nil)
                XCTAssertEqual(persisted.zoomAndRotate.smartZoom.keyCombination, nil)
            }
        )

        overrideController.updateSettingsCount = 0

        // double tap

        store.assert(
            .send(.toggleSmartZoomUseZoomAndRotateKeyCombinationDoubleTap) {
                $0.shouldSmartZoomUseZoomAndRotateKeyCombinationDoubleTap = true
            },
            .do {
                XCTAssertEqual(persisted.zoomAndRotate.smartZoom.useZoomAndRotateDoubleTap, true)
            },
            .send(.toggleSmartZoomUseZoomAndRotateKeyCombinationDoubleTap) {
                $0.shouldSmartZoomUseZoomAndRotateKeyCombinationDoubleTap = false
            },
            .do {
                XCTAssertEqual(persisted.zoomAndRotate.smartZoom.useZoomAndRotateDoubleTap, false)
            }
        )

        overrideController.updateSettingsCount = 0

        // direction

        store.assert(
            .send(.changeRotateGestureDirectionToOption(1)) {
                $0.rotateGestureDirection = .left
            },
            .send(.changeZoomGestureDirectionToOption(3)) {
                $0.zoomGestureDirection = .up
            },
            .do {
                XCTAssertEqual(persisted.zoomAndRotate.rotateGestureDirection, .left)
                XCTAssertEqual(persisted.zoomAndRotate.zoomGestureDirection, .up)
            },
            // conflict
            .send(.changeRotateGestureDirectionToOption(3)) {
                $0.rotateGestureDirection = .up
                $0.zoomGestureDirection = .none
            },
            .send(.changeZoomGestureDirectionToOption(4)) {
                $0.rotateGestureDirection = .none
                $0.zoomGestureDirection = .down
            },
            .do {
                XCTAssertEqual(persisted.zoomAndRotate.rotateGestureDirection, .none)
                XCTAssertEqual(persisted.zoomAndRotate.zoomGestureDirection, .down)
            },
            .send(.changeRotateGestureDirectionToOption(1)) {
                $0.rotateGestureDirection = .left
            },
            .send(.changeZoomGestureDirectionToOption(2)) {
                $0.rotateGestureDirection = .none
                $0.zoomGestureDirection = .right
            },
            .send(.changeRotateGestureDirectionToOption(2)) {
                $0.rotateGestureDirection = .right
                $0.zoomGestureDirection = .none
            },
            .do {
                XCTAssertEqual(persisted.zoomAndRotate.rotateGestureDirection, .right)
                XCTAssertEqual(persisted.zoomAndRotate.zoomGestureDirection, .none)
            }
        )

        // turn off inertia effect

        store.assert(
            .send(.turnOffInertiaEffect) {
                $0.isInertiaEffectEnabled = false
            },
            .do {
                XCTAssertEqual(persisted.moveToScroll.isInertiaEffectEnabled, false)
            }
        )
    }
}
