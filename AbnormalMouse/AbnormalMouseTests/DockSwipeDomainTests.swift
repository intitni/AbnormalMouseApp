import CGEventOverride
import ComposableArchitecture
import XCTest

@testable import AbnormalMouse

class DockSwipeDomainTests: XCTestCase {
    func testDockSwipeSettings() {
        let persisted = Persisted(
            userDefaults: MemoryPropertyListStorage(),
            keychainAccess: FakeKeychainAccess()
        ).dockSwipe

        var hasConflict: (ActivatorConflictChecker.Feature) -> Bool = { $0 == .dockSwipe }

        let initialState = DockSwipeDomain.State(from: persisted)
        let store = TestStore(
            initialState: initialState,
            reducer: DockSwipeDomain.reducer,
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

        XCTAssertEqual(initialState.dockSwipeActivator.keyCombination, nil)
        XCTAssertEqual(initialState.dockSwipeActivator.numberOfTapsRequired, 1)
        XCTAssertEqual(initialState.dockSwipeActivator.hasConflict, false)

        store.assert(
            .send(.dockSwipe(.setKeyCombination(keyCombination))) {
                $0.dockSwipeActivator.keyCombination = keyCombination
            },
            .receive(._internal(.checkConflict)) {
                $0.dockSwipeActivator.hasConflict = true
            },
            .do {
                XCTAssertEqual(persisted.keyCombination, keyCombination)
                hasConflict = { _ in false }
            },
            .send(.dockSwipe(.setKeyCombination(keyCombination))) {
                $0.dockSwipeActivator.keyCombination = keyCombination
            },
            .receive(._internal(.checkConflict)) {
                $0.dockSwipeActivator.hasConflict = false
            },
            .do {
                XCTAssertEqual(persisted.keyCombination, keyCombination)
            },
            .send(.dockSwipe(.setNumberOfTapsRequired(2))) {
                $0.dockSwipeActivator.numberOfTapsRequired = 2
            },
            .receive(._internal(.checkConflict)),
            .do {
                XCTAssertEqual(persisted.numberOfTapsRequired, 2)
            },
            .send(.dockSwipe(.clearKeyCombination)) {
                $0.dockSwipeActivator.keyCombination = nil
            },
            .receive(._internal(.checkConflict)),
            .do {
                XCTAssertEqual(persisted.keyCombination, nil)
            }
        )
    }
}
