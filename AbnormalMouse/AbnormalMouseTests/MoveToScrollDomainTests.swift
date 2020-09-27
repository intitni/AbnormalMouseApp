import CGEventOverride
import ComposableArchitecture
import XCTest

@testable import AbnormalMouse

class MoveToScrollDomainTests: XCTestCase {
    func testMoveToScrollSettings() throws {
        let persisted = Persisted(
            userDefaults: MemoryPropertyListStorage(),
            keychainAccess: FakeKeychainAccess()
        ).moveToScroll

        var hasConflict: (ActivatorConflictChecker.Feature) -> Bool = { _ in false }

        let initialState = MoveToScrollDomain.State(from: persisted)
        let store = TestStore(
            initialState: initialState,
            reducer: MoveToScrollDomain.reducer,
            environment: .init(
                environment: .init(
                    persisted: persisted,
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

        XCTAssertEqual(initialState.scrollSpeedMultiplier, 3)
        XCTAssertEqual(initialState.moveToScrollActivator.keyCombination, nil)
        XCTAssertEqual(initialState.moveToScrollActivator.numberOfTapsRequired, 1)
        XCTAssertEqual(initialState.moveToScrollActivator.hasConflict, false)

        store.assert(
            .send(.changeScrollSpeedMultiplierTo(2)) {
                $0.scrollSpeedMultiplier = 2
            },
            .do {
                hasConflict = { $0 == .moveToScroll }
            },
            .send(.moveToScroll(.setKeyCombination(keyCombination))) {
                $0.moveToScrollActivator.keyCombination = keyCombination
            },
            .receive(._internal(.checkConflict)) {
                $0.moveToScrollActivator.hasConflict = true
            },
            .do {
                XCTAssertEqual(persisted.keyCombination, keyCombination)
                hasConflict = { _ in false }
            },
            .send(.moveToScroll(.setKeyCombination(keyCombination))) {
                $0.moveToScrollActivator.keyCombination = keyCombination
            },
            .receive(._internal(.checkConflict)) {
                $0.moveToScrollActivator.hasConflict = false
            },
            .do {
                XCTAssertEqual(persisted.keyCombination, keyCombination)
            },
            .send(.moveToScroll(.setNumberOfTapsRequired(2))) {
                $0.moveToScrollActivator.numberOfTapsRequired = 2
            },
            .receive(._internal(.checkConflict)),
            .do {
                XCTAssertEqual(persisted.numberOfTapsRequired, 2)
            },
            .send(.moveToScroll(.clearKeyCombination)) {
                $0.moveToScrollActivator.keyCombination = nil
            },
            .receive(._internal(.checkConflict)),
            .do {
                XCTAssertEqual(persisted.keyCombination, nil)
                XCTAssertEqual(persisted.scrollSpeedMultiplier, 2, accuracy: 0)
            }
        )
    }

    func testHalfPageScrollSettings() throws {
        let persisted = Persisted(
            userDefaults: MemoryPropertyListStorage(),
            keychainAccess: FakeKeychainAccess()
        ).moveToScroll

        var hasConflict: (ActivatorConflictChecker.Feature) -> Bool = { _ in false }

        let initialState = MoveToScrollDomain.State(from: persisted)
        let store = TestStore(
            initialState: initialState,
            reducer: MoveToScrollDomain.reducer,
            environment: .init(
                environment: .init(
                    persisted: persisted,
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

        XCTAssertTrue(initialState.halfPageScrollActivator.shouldUseMoveToScrollKeyCombination)
        XCTAssertNil(initialState.halfPageScrollActivator.keyCombination)
        XCTAssertEqual(initialState.halfPageScrollActivator.numberOfTapsRequired, 1)
        XCTAssertFalse(initialState.halfPageScrollActivator.hasConflict)

        store.assert(
            .send(.halfPageScroll(.toggleUseMoveToScrollKeyCombinationDoubleTap)) {
                $0.halfPageScrollActivator.shouldUseMoveToScrollKeyCombination = false
            },
            .receive(._internal(.checkConflict)),
            .do {
                XCTAssertFalse(persisted.halfPageScroll.useMoveToScrollDoubleTap)
                hasConflict = { $0 == .halfPageScroll }
            },
            .send(.halfPageScroll(.setKeyCombination(keyCombination))) {
                $0.halfPageScrollActivator.keyCombination = keyCombination
            },
            .receive(._internal(.checkConflict)) {
                $0.halfPageScrollActivator.hasConflict = true
            },
            .do {
                XCTAssertEqual(persisted.halfPageScroll.keyCombination, keyCombination)
                hasConflict = { _ in false }
            },
            .send(.halfPageScroll(.setNumberOfTapsRequired(2))) {
                $0.halfPageScrollActivator.numberOfTapsRequired = 2
            },
            .receive(._internal(.checkConflict)) {
                $0.halfPageScrollActivator.hasConflict = false
            },
            .do {
                XCTAssertEqual(persisted.halfPageScroll.numberOfTapsRequired, 2)
            },
            .send(.halfPageScroll(.clearKeyCombination)) {
                $0.halfPageScrollActivator.keyCombination = nil
            },
            .receive(._internal(.checkConflict)),
            .do {
                XCTAssertEqual(persisted.halfPageScroll.keyCombination, nil)
            }
        )
    }
}
