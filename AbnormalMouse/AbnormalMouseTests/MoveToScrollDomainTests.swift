import CGEventOverride
import ComposableArchitecture
import XCTest

@testable import AbnormalMouse

class MoveToScrollDomainTests: XCTestCase {
    let suiteName = String(describing: MoveToScrollDomainTests.self)

    override func tearDown() {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    func testSettings() throws {
        let persisted = Persisted(
            userDefaults: UserDefaults(suiteName: suiteName)!,
            keychainAccess: FakeKeychainAccess()
        ).moveToScroll
        defer { UserDefaults().removeSuite(named: suiteName) }
        persisted.scrollSpeedMultiplier = 1
        persisted.keyCombination = nil
        let initialState = MoveToScrollDomain.State(from: persisted)
        let store = TestStore(
            initialState: initialState,
            reducer: MoveToScrollDomain.reducer,
            environment: MoveToScrollDomain.Environment(
                persisted: persisted
            )
        )

        let keyCombination = KeyCombination(Set([
            .key(KeyboardCode.command.rawValue),
            .key(KeyboardCode.a.rawValue),
        ]))

        XCTAssertEqual(initialState.scrollSpeedMultiplier, 1)
        XCTAssertEqual(initialState.activationKeyCombination, nil)

        store.assert(
            .send(.changeScrollSpeedMultiplierTo(2)) {
                $0.scrollSpeedMultiplier = 2
            },
            .send(.setActivationKeyCombination(keyCombination)) {
                $0.activationKeyCombination = keyCombination
            },
            .do {
                XCTAssertEqual(persisted.keyCombination, keyCombination)
            },
            .send(.clearActivationKeyCombination) {
                $0.activationKeyCombination = nil
            },
            .do {
                XCTAssertEqual(persisted.keyCombination, nil)
                XCTAssertEqual(persisted.scrollSpeedMultiplier, 2, accuracy: 0)
            }
        )
    }
}
