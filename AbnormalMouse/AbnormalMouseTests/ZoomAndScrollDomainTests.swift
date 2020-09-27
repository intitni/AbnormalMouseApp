import CGEventOverride
import ComposableArchitecture
import XCTest

@testable import AbnormalMouse

class ZoomAndScrollDomainTests: XCTestCase {
    func testZoomAndRotationKeyCombinationSettings() throws {
        let persisted = Persisted(
            userDefaults: MemoryPropertyListStorage(),
            keychainAccess: FakeKeychainAccess()
        )

        persisted.zoomAndRotate.keyCombination = nil
        persisted.zoomAndRotate.numberOfTapsRequired = 1

        var hasConflict: (ActivatorConflictChecker.Feature) -> Bool = { $0 == .zoomAndRotate }

        let initialState = ZoomAndRotateDomain.State(from: persisted.zoomAndRotate)
        let store = TestStore(
            initialState: initialState,
            reducer: ZoomAndRotateDomain.reducer,
            environment: .init(
                environment: .init(
                    persisted: persisted.zoomAndRotate,
                    featureHasConflict: { hasConflict($0) }
                ),
                date: { Date() },
                openURL: { _ in },
                quitApp: {},
                mainQueue: { .main }
            )
        )

        let keyCombination = KeyCombination(Set([
            .key(KeyboardCode.command.rawValue),
            .key(KeyboardCode.a.rawValue),
        ]))

        store.assert(
            .send(.zoomAndRotate(.setKeyCombination(keyCombination))) {
                $0.zoomAndRotateActivator.keyCombination = keyCombination
            },
            .receive(._internal(.checkConflict)) {
                $0.zoomAndRotateActivator.hasConflict = true
            },
            .do {
                XCTAssertEqual(persisted.zoomAndRotate.keyCombination, keyCombination)
                hasConflict = { _ in false }
            },
            .send(.zoomAndRotate(.clearKeyCombination)) {
                $0.zoomAndRotateActivator.keyCombination = nil
            },
            .receive(._internal(.checkConflict)) {
                $0.zoomAndRotateActivator.hasConflict = false
            },
            .do {
                XCTAssertEqual(persisted.zoomAndRotate.keyCombination, nil)
            }
        )
    }

    func testZoomAndScrollDirectionSettings() {
        let persisted = Persisted(
            userDefaults: MemoryPropertyListStorage(),
            keychainAccess: FakeKeychainAccess()
        )

        let initialState = ZoomAndRotateDomain.State(from: persisted.zoomAndRotate)
        let store = TestStore(
            initialState: initialState,
            reducer: ZoomAndRotateDomain.reducer,
            environment: .init(
                environment: .init(
                    persisted: persisted.zoomAndRotate,
                    featureHasConflict: { _ in false }
                ),
                date: { Date() },
                openURL: { _ in },
                quitApp: {},
                mainQueue: { .main }
            )
        )

        XCTAssertEqual(initialState.rotateGestureDirection, .right)
        XCTAssertEqual(initialState.zoomGestureDirection, .up)

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
    }

    func testSmartZoomSettings() {
        let persisted = Persisted(
            userDefaults: MemoryPropertyListStorage(),
            keychainAccess: FakeKeychainAccess()
        )

        var hasConflict: (ActivatorConflictChecker.Feature) -> Bool = { _ in false }

        let initialState = ZoomAndRotateDomain.State(from: persisted.zoomAndRotate)
        let store = TestStore(
            initialState: initialState,
            reducer: ZoomAndRotateDomain.reducer,
            environment: .init(
                environment: .init(
                    persisted: persisted.zoomAndRotate,
                    featureHasConflict: { hasConflict($0) }
                ),
                date: { Date() },
                openURL: { _ in },
                quitApp: {},
                mainQueue: { .main }
            )
        )

        let keyCombination = KeyCombination(Set([
            .key(KeyboardCode.command.rawValue),
            .key(KeyboardCode.a.rawValue),
        ]))

        XCTAssertTrue(initialState.smartZoomActivator.shouldUseZoomAndRotateKeyCombinationDoubleTap)
        XCTAssertNil(initialState.smartZoomActivator.keyCombination)
        XCTAssertEqual(initialState.smartZoomActivator.numberOfTapsRequired, 1)
        XCTAssertFalse(initialState.smartZoomActivator.hasConflict)

        store.assert(
            .send(.smartZoom(.toggleUseZoomAndRotateKeyCombinationDoubleTap)) {
                $0.smartZoomActivator.shouldUseZoomAndRotateKeyCombinationDoubleTap = false
            },
            .receive(._internal(.checkConflict)),
            .do {
                XCTAssertFalse(persisted.zoomAndRotate.smartZoom.useZoomAndRotateDoubleTap)
                hasConflict = { $0 == .smartZoom }
            },
            .send(.smartZoom(.setKeyCombination(keyCombination))) {
                $0.smartZoomActivator.keyCombination = keyCombination
            },
            .receive(._internal(.checkConflict)) {
                $0.smartZoomActivator.hasConflict = true
            },
            .do {
                XCTAssertEqual(persisted.zoomAndRotate.smartZoom.keyCombination, keyCombination)
                hasConflict = { _ in false }
            },
            .send(.smartZoom(.setNumberOfTapsRequired(2))) {
                $0.smartZoomActivator.numberOfTapsRequired = 2
            },
            .receive(._internal(.checkConflict)) {
                $0.smartZoomActivator.hasConflict = false
            },
            .do {
                XCTAssertEqual(persisted.zoomAndRotate.smartZoom.numberOfTapsRequired, 2)
            },
            .send(.smartZoom(.clearKeyCombination)) {
                $0.smartZoomActivator.keyCombination = nil
            },
            .receive(._internal(.checkConflict)),
            .do {
                XCTAssertEqual(persisted.zoomAndRotate.smartZoom.keyCombination, nil)
            }
        )
    }
}
