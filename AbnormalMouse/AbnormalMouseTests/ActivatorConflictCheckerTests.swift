import XCTest

@testable import AbnormalMouse

class ActivatorConflictCheckerTests: XCTestCase {
    func testNilKeyCombinationNoConflict() throws {
        let persisted = Persisted(
            userDefaults: MemoryPropertyListStorage(),
            keychainAccess: FakeKeychainAccess()
        )

        let checker = ActivatorConflictChecker(persisted: Readonly(persisted))

        for f in ActivatorConflictChecker.Feature.allCases {
            XCTAssertFalse(checker.featureHasConflict(f))
        }
    }

    func testDifferenctKeyCombinationNoConflict() throws {
        let persisted = Persisted(
            userDefaults: MemoryPropertyListStorage(),
            keychainAccess: FakeKeychainAccess()
        )

        let checker = ActivatorConflictChecker(persisted: Readonly(persisted))

        persisted.moveToScroll.keyCombination = .init(modifiers: [.key(2)], activator: .key(2))
        persisted.moveToScroll.numberOfTapsRequired = 1
        persisted.zoomAndRotate.keyCombination = .init(modifiers: [.key(1)], activator: .key(2))
        persisted.zoomAndRotate.numberOfTapsRequired = 1

        XCTAssertFalse(checker.featureHasConflict(.moveToScroll))
        XCTAssertFalse(checker.featureHasConflict(.zoomAndRotate))

        persisted.moveToScroll.keyCombination = .init(modifiers: [.key(1)], activator: .key(1))
        persisted.moveToScroll.numberOfTapsRequired = 1
        persisted.zoomAndRotate.keyCombination = .init(modifiers: [.key(1)], activator: .key(2))
        persisted.zoomAndRotate.numberOfTapsRequired = 1

        XCTAssertFalse(checker.featureHasConflict(.moveToScroll))
        XCTAssertFalse(checker.featureHasConflict(.zoomAndRotate))
    }

    func testSameCombinationSameNumberOfTapsConflict() throws {
        let persisted = Persisted(
            userDefaults: MemoryPropertyListStorage(),
            keychainAccess: FakeKeychainAccess()
        )

        let checker = ActivatorConflictChecker(persisted: Readonly(persisted))

        persisted.moveToScroll.keyCombination = .init(modifiers: [.key(1)], activator: .key(2))
        persisted.moveToScroll.numberOfTapsRequired = 1
        persisted.zoomAndRotate.keyCombination = .init(modifiers: [.key(1)], activator: .key(2))
        persisted.zoomAndRotate.numberOfTapsRequired = 2
        persisted.dockSwipe.keyCombination = .init(modifiers: [.key(1)], activator: .key(2))
        persisted.dockSwipe.numberOfTapsRequired = 3
        persisted.moveToScroll.halfPageScroll.useMoveToScrollDoubleTap = false
        persisted.zoomAndRotate.smartZoom.useZoomAndRotateDoubleTap = false

        XCTAssertFalse(checker.featureHasConflict(.moveToScroll))
        XCTAssertFalse(checker.featureHasConflict(.zoomAndRotate))
        XCTAssertFalse(checker.featureHasConflict(.dockSwipe))

        persisted.moveToScroll.numberOfTapsRequired = 2

        XCTAssertTrue(checker.featureHasConflict(.moveToScroll))
        XCTAssertTrue(checker.featureHasConflict(.zoomAndRotate))
        XCTAssertFalse(checker.featureHasConflict(.dockSwipe))

        persisted.moveToScroll.numberOfTapsRequired = 3

        XCTAssertTrue(checker.featureHasConflict(.moveToScroll))
        XCTAssertFalse(checker.featureHasConflict(.zoomAndRotate))
        XCTAssertTrue(checker.featureHasConflict(.dockSwipe))
    }

    func testDoubleTapGesturesConflictToHoldGestures() throws {
        let persisted = Persisted(
            userDefaults: MemoryPropertyListStorage(),
            keychainAccess: FakeKeychainAccess()
        )

        let checker = ActivatorConflictChecker(persisted: Readonly(persisted))

        persisted.moveToScroll.keyCombination = .init(modifiers: [.key(1)], activator: .key(2))
        persisted.moveToScroll.numberOfTapsRequired = 1
        persisted.zoomAndRotate.keyCombination = .init(modifiers: [.key(1)], activator: .key(2))
        persisted.zoomAndRotate.numberOfTapsRequired = 2
        persisted.dockSwipe.keyCombination = .init(modifiers: [.key(1)], activator: .key(2))
        persisted.dockSwipe.numberOfTapsRequired = 3
        persisted.moveToScroll.halfPageScroll.useMoveToScrollDoubleTap = true
        persisted.zoomAndRotate.smartZoom.useZoomAndRotateDoubleTap = true

        XCTAssertTrue(checker.featureHasConflict(.halfPageScroll))
        XCTAssertTrue(checker.featureHasConflict(.zoomAndRotate))
        XCTAssertTrue(checker.featureHasConflict(.smartZoom))
        XCTAssertTrue(checker.featureHasConflict(.dockSwipe))

        persisted.zoomAndRotate.keyCombination = .init(modifiers: [.key(2)], activator: .key(2))

        XCTAssertFalse(checker.featureHasConflict(.halfPageScroll))
        XCTAssertFalse(checker.featureHasConflict(.zoomAndRotate))
        XCTAssertFalse(checker.featureHasConflict(.smartZoom))
        XCTAssertFalse(checker.featureHasConflict(.dockSwipe))
    }
}
