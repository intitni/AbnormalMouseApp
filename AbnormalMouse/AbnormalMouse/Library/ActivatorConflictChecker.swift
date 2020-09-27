import AppKit
import Combine

final class ActivatorConflictChecker {
    enum Feature: Equatable {
        case scrollAndSwipe
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
        activators[.scrollAndSwipe] = Activator(
            keyCombination: persisted.moveToScroll.keyCombination,
            numberOfTapRequired: 1
        )
        activators[.halfPageScroll] = Activator(
            keyCombination: persisted.moveToScroll.keyCombination,
            numberOfTapRequired: 1
        )
        activators[.zoomAndRotate] = Activator(
            keyCombination: persisted.zoomAndRotate.keyCombination,
            numberOfTapRequired: 1
        )
        activators[.smartZoom] = {
            if persisted.zoomAndRotate.smartZoom.useZoomAndRotateDoubleTap {
                return Activator(
                    keyCombination: persisted.zoomAndRotate.keyCombination,
                    numberOfTapRequired: 1
                )
            }
            return Activator(
                keyCombination: persisted.zoomAndRotate.smartZoom.keyCombination,
                numberOfTapRequired: 1
            )
        }()
        activators[.dockSwipe] = Activator(
            keyCombination: persisted.dockSwipe.keyCombination,
            numberOfTapRequired: 1
        )
    }
}
