import AppKit
import Combine

final class ActivatorConflictChecker {
    enum Feature: Equatable, CaseIterable {
        case moveToScroll
        case halfPageScroll
        case zoomAndRotate
        case smartZoom
        case dockSwipe
    }

    private let persisted: Readonly<Persisted>
    private var activators = [Feature: Activator]()
    private var cancellables = Set<AnyCancellable>()

    init(persisted: Readonly<Persisted>) {
        self.persisted = persisted
        updateKeyCombinations()
    }

    func featureHasConflict(_ feature: Feature) -> Bool {
        updateKeyCombinations()
        guard let activator = activators[feature] else { return false }
        for key in activators.keys {
            guard key != feature else { continue }
            if activators[key] == activator { return true }
        }
        return false
    }

    private func updateKeyCombinations() {
        activators[.moveToScroll] = Activator(
            keyCombination: persisted.moveToScroll.keyCombination,
            numberOfTapRequired: persisted.moveToScroll.numberOfTapsRequired
        )
        activators[.halfPageScroll] = {
            if persisted.moveToScroll.halfPageScroll.useMoveToScrollDoubleTap {
                return Activator(
                    keyCombination: persisted.moveToScroll.keyCombination,
                    numberOfTapRequired: persisted.moveToScroll.numberOfTapsRequired + 1
                )
            }
            return Activator(
                keyCombination: persisted.moveToScroll.halfPageScroll.keyCombination,
                numberOfTapRequired: persisted.moveToScroll.halfPageScroll.numberOfTapsRequired
            )
        }()
        activators[.zoomAndRotate] = Activator(
            keyCombination: persisted.zoomAndRotate.keyCombination,
            numberOfTapRequired: persisted.zoomAndRotate.numberOfTapsRequired
        )
        activators[.smartZoom] = {
            if persisted.zoomAndRotate.smartZoom.useZoomAndRotateDoubleTap {
                return Activator(
                    keyCombination: persisted.zoomAndRotate.keyCombination,
                    numberOfTapRequired: persisted.zoomAndRotate.numberOfTapsRequired + 1
                )
            }
            return Activator(
                keyCombination: persisted.zoomAndRotate.smartZoom.keyCombination,
                numberOfTapRequired: persisted.zoomAndRotate.smartZoom.numberOfTapsRequired
            )
        }()
        activators[.dockSwipe] = Activator(
            keyCombination: persisted.dockSwipe.keyCombination,
            numberOfTapRequired: persisted.dockSwipe.numberOfTapsRequired
        )
    }
}
