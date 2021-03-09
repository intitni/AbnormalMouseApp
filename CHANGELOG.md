# Change Log

### 2020.10

- Fix that SUUpdater was loaded too early and messed up windows. 
- Again use CocoaPods for Sparkle.
- Remove the name localization.

### 2020.9

- Fix Reeder.app won't recognize scroll sometimes.
- Fix Calendar.app won't recognize scroll.

### 2020.8

- Adjust app icon to have a stronger Big Sur taste.
- Add more keyboard code name.
- Build for Apple Silicon (not tested).

### 2020.7

- Update UI for Big Sur.
- Use a swift package AppDependencies to handle all swift dependencies.
- Compute rotation value with mouse translation.

### 2020.6

- Fix that multiple tap hold gesture with keyboard key as activator is automatically canceled after trigger.
- Fix that modifiers are ignored when using mouse buttons as activators.

### 2020.5

- Code cleanup.
- New activator setter.
- Allow setting half page scroll activator.
- Support activator sharing with different number-of-taps-required.
- Add activator conflict check.
- Tweak zoom and rotate.

### 2020.4

- Support 4 finger swipe gestures.
- Fix that smart zoom settings are not persisted.

### Open Source

- Open source.
- Support to build without license management logics.
- Detach license management and CGEventOverride to other repos.

### 2020.3

- Gesture base override controllers.
- Code clean up.
- Add listen to keyboard event toggle.
- Rename "Scroll" to "Scroll and Swipe".
- Add `MainDomain` extracted from `TheApp`.
- Tweak zooming.

### 2020.2

- Remove sandbox entitlement from launcher.

### 2020.1

- Enable harden runtime.
- Fix crashes.
- Fix main scene accessability sheet can't present.

### 2020.0

- Initial release.
- Move to scroll, gesture, half page scroll.
- Rotate and zoom, smart zoom.
- License management, trial mode.
