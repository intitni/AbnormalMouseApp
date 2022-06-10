// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum Activation {
    /// Email
    internal static let emailTitle = L10n.tr("Activation", "EmailTitle")
    /// Please enter your license key and email to activate.
    internal static let instruction = L10n.tr("Activation", "Instruction")
    /// License key
    internal static let licenseKeyTitle = L10n.tr("Activation", "LicenseKeyTitle")
    internal enum Button {
      /// Activate
      internal static let activate = L10n.tr("Activation", "Button.Activate")
      /// Activating..
      internal static let activating = L10n.tr("Activation", "Button.Activating")
      /// Buy Now
      internal static let buyNow = L10n.tr("Activation", "Button.BuyNow")
      /// Cancel
      internal static let cancel = L10n.tr("Activation", "Button.Cancel")
    }
    internal enum FailureReason {
      /// Can't verify the license. Please check the key and email entered are correct.
      internal static let invalid = L10n.tr("Activation", "FailureReason.Invalid")
      /// Please check your network and try again.
      internal static let networkError = L10n.tr("Activation", "FailureReason.NetworkError")
      /// The license key has reached the activation limit. Please deactivate first.
      internal static let reachedLimit = L10n.tr("Activation", "FailureReason.ReachedLimit")
      /// The license key has been refunded.
      internal static let refunded = L10n.tr("Activation", "FailureReason.Refunded")
    }
  }
  internal enum Advanced {
    internal enum View {
      /// Disable Abnormal Mouse for apps listing below
      internal static let excludeListTitle = L10n.tr("Advanced", "View.ExcludeListTitle")
      /// Listen to keyboard event (restart app to take effect)
      internal static let listenToKeyboardEvent = L10n.tr("Advanced", "View.ListenToKeyboardEvent")
      /// By default, this app does not listen to your keystrokes so you can't use keyboard keys (except modifiers) as activators. Letting an app read your keystrokes can be risky (though we are not doing anything with Abnormal Mouse). Turn it on if you want to use keyboard keys as activators. It will also slightly increase CPU usage when idel. \n\nYou can use tools like ReiKey to check if the app is still listening to your keystrokes
      internal static let listenToKeyboardEventIntroduction = L10n.tr("Advanced", "View.ListenToKeyboardEventIntroduction")
      /// Advanced
      internal static let title = L10n.tr("Advanced", "View.Title")
    }
  }
  internal enum DockSwipeSettings {
    internal enum View {
      /// Active when holding
      internal static let activationKeyCombinationTitle = L10n.tr("DockSwipeSettings", "View.ActivationKeyCombinationTitle")
      /// This feature converts mouse movement into a four-finger swipe, enabling you to switch spaces with a normal mouse.
      internal static let introduction = L10n.tr("DockSwipeSettings", "View.Introduction")
      /// 4-Finger Swipe
      internal static let title = L10n.tr("DockSwipeSettings", "View.Title")
      internal enum Tips {
        /// Hold activator then move your mouse to swipe.
        internal static let usage = L10n.tr("DockSwipeSettings", "View.Tips.Usage")
      }
    }
  }
  internal enum General {
    /// Activate
    internal static let activate = L10n.tr("General", "Activate")
    /// Automatically check for update
    internal static let automaticallyCheckForUpdate = L10n.tr("General", "AutomaticallyCheckForUpdate")
    /// Automatically start at login
    internal static let autoStart = L10n.tr("General", "AutoStart")
    /// Check Now
    internal static let checkForUpdate = L10n.tr("General", "CheckForUpdate")
    /// If you have any problem using the app, feel free to contact me at
    internal static let contactMe = L10n.tr("General", "ContactMe")
    /// Deactivate
    internal static let deactivate = L10n.tr("General", "Deactivate")
    /// Deactivating..
    internal static let deactivating = L10n.tr("General", "Deactivating")
    /// Developed by
    internal static let developedBy = L10n.tr("General", "DevelopedBy")
    /// License is not valid.
    internal static let licenseInvalid = L10n.tr("General", "LicenseInvalid")
    /// License is refunded.
    internal static let licenseRefunded = L10n.tr("General", "LicenseRefunded")
    /// Licensed to %@
    internal static func licenseTo(_ p1: Any) -> String {
      return L10n.tr("General", "LicenseTo", String(describing: p1))
    }
    /// License is valid.
    internal static let licenseValid = L10n.tr("General", "LicenseValid")
    /// Buy Now
    internal static let purchase = L10n.tr("General", "Purchase")
    /// Quit Abnormal Mouse
    internal static let quit = L10n.tr("General", "Quit")
    /// Trial will end in %@ days.
    internal static func trialDaysRemain(_ p1: Any) -> String {
      return L10n.tr("General", "TrialDaysRemain", String(describing: p1))
    }
    /// Trial has ended.
    internal static let trialEnd = L10n.tr("General", "TrialEnd")
    /// Version %@
    internal static func version(_ p1: Any) -> String {
      return L10n.tr("General", "Version", String(describing: p1))
    }
    internal enum ErrorMessage {
      /// Failed to deactivate, please try again later.
      internal static let failedToDeactivate = L10n.tr("General", "ErrorMessage.FailedToDeactivate")
      /// Please check your network and try again.
      internal static let networkError = L10n.tr("General", "ErrorMessage.NetworkError")
    }
    internal enum Title {
      /// About
      internal static let about = L10n.tr("General", "Title.About")
      /// General
      internal static let general = L10n.tr("General", "Title.General")
    }
  }
  internal enum MainView {
    internal enum ExpireAlert {
      /// Activate
      internal static let activate = L10n.tr("MainView", "ExpireAlert.Activate")
      /// Buy Now
      internal static let buyNow = L10n.tr("MainView", "ExpireAlert.BuyNow")
      /// Thanks for trying out Abnormal Mouse. To continue to use the app, you can activate it with an activation key.
      internal static let content = L10n.tr("MainView", "ExpireAlert.Content")
      /// Trial Has Ended.
      internal static let title = L10n.tr("MainView", "ExpireAlert.Title")
    }
    internal enum Status {
      /// Enable
      internal static let enableButtonTitle = L10n.tr("MainView", "Status.EnableButtonTitle")
      /// Abnormal Mouse is not enabled.
      internal static let notEnabled = L10n.tr("MainView", "Status.NotEnabled")
    }
    internal enum TabTitle {
      /// Advanced
      internal static let advanced = L10n.tr("MainView", "TabTitle.Advanced")
      /// 4-Finger Swipe
      internal static let dockSwipe = L10n.tr("MainView", "TabTitle.DockSwipe")
      /// General
      internal static let general = L10n.tr("MainView", "TabTitle.General")
      /// Scroll and Swipe
      internal static let moveToScroll = L10n.tr("MainView", "TabTitle.MoveToScroll")
      /// Tap and Click
      internal static let tapAndClick = L10n.tr("MainView", "TabTitle.TapAndClick")
      /// Zoom and Rotate
      internal static let zoomAndRotate = L10n.tr("MainView", "TabTitle.ZoomAndRotate")
    }
  }
  internal enum NeedAccessibility {
    internal enum View {
      /// Turn On Accessibility
      internal static let enableButtonTitle = L10n.tr("NeedAccessibility", "View.EnableButtonTitle")
      /// The app needs accessibility enabled to read and manipulate keyboard and mouse events.
      internal static let introduction = L10n.tr("NeedAccessibility", "View.Introduction")
      /// Go to System Preferences > Security & Privacy > Privacy > Accessibility
      internal static let manual = L10n.tr("NeedAccessibility", "View.Manual")
      /// Abnormal Mouse Needs to Be Free!
      internal static let title = L10n.tr("NeedAccessibility", "View.Title")
    }
  }
  internal enum ScrollSettings {
    internal enum HalfPageScrollView {
      /// Trigger when
      internal static let activationKeyCombinationTitle = L10n.tr("ScrollSettings", "HalfPageScrollView.ActivationKeyCombinationTitle")
      /// Reuse activator for "scroll and swipe"
      internal static let doubleTapToActivate = L10n.tr("ScrollSettings", "HalfPageScrollView.DoubleTapToActivate")
      /// Page-down is cool, but a full-page scroll can be annoying. This feature allows you to scroll down half a page.
      internal static let introduction = L10n.tr("ScrollSettings", "HalfPageScrollView.introduction")
      /// Half Page Scroll
      internal static let title = L10n.tr("ScrollSettings", "HalfPageScrollView.Title")
      internal enum Tips {
        /// Double tap activator for "move to scroll" to trigger half page scroll.
        internal static let usageA = L10n.tr("ScrollSettings", "HalfPageScrollView.Tips.UsageA")
        /// Tap activator to trigger half page scroll.
        internal static let usageB = L10n.tr("ScrollSettings", "HalfPageScrollView.Tips.UsageB")
      }
    }
    internal enum View {
      /// Active when holding
      internal static let activationKeyCombinationTitle = L10n.tr("ScrollSettings", "View.ActivationKeyCombinationTitle")
      /// Emulate inertia effect
      internal static let inertiaEffectCheckboxTitle = L10n.tr("ScrollSettings", "View.InertiaEffectCheckboxTitle")
      /// We recommend you to keep it on. Disabling it will disable inertia effect in some apps.
      internal static let inertiaEffectIntroduction = L10n.tr("ScrollSettings", "View.InertiaEffectIntroduction")
      /// This feature converts mouse movement into scrolling. Better than that, it also allows you to play drag gestures by moving the mouse, like navigating back in Safari or marking emails as read in the Mail app.
      internal static let introduction = L10n.tr("ScrollSettings", "View.Introduction")
      /// Scroll speed controls how mouse movements will be scaled-up into scrolls. A large number is preferred since you will not want to move the mouse a lot to scroll.
      internal static let scrollSpeedSliderIntroduction = L10n.tr("ScrollSettings", "View.ScrollSpeedSliderIntroduction")
      /// Scroll speed
      internal static let scrollSpeedSliderTitle = L10n.tr("ScrollSettings", "View.ScrollSpeedSliderTitle")
      /// Swipe speed controls how it's scaled into swipe gesture translations. A slower speed will make it feel more natural.
      internal static let swipeSpeedSliderIntroduction = L10n.tr("ScrollSettings", "View.SwipeSpeedSliderIntroduction")
      /// Swipe speed
      internal static let swipeSpeedSliderTitle = L10n.tr("ScrollSettings", "View.SwipeSpeedSliderTitle")
      /// Scroll and Swipe
      internal static let title = L10n.tr("ScrollSettings", "View.Title")
      internal enum Tips {
        /// Set a mouse button as activator to have a drag-to-scroll like experience.
        internal static let activatorChoice = L10n.tr("ScrollSettings", "View.Tips.ActivatorChoice")
        /// Double tap to scroll down half a page.
        internal static let pageDown = L10n.tr("ScrollSettings", "View.Tips.PageDown")
        /// Turn off show scroll bar in system preferences if you don't have a trackpad connected.
        internal static let scrollBar = L10n.tr("ScrollSettings", "View.Tips.ScrollBar")
        /// Hold activator then move your mouse to scroll.
        internal static let usage = L10n.tr("ScrollSettings", "View.Tips.Usage")
      }
    }
  }
  internal enum Shared {
    /// Abnormal Mouse
    internal static let appName = L10n.tr("Shared", "AppName")
    /// https://abnormalmouse.intii.com
    internal static let homepageURLString = L10n.tr("Shared", "HomepageURLString")
    internal enum MouseCodeName {
      /// Mouse(L)
      internal static let `left` = L10n.tr("Shared", "MouseCodeName.Left")
      /// Mouse(M)
      internal static let middle = L10n.tr("Shared", "MouseCodeName.Middle")
      /// Mouse(%@)
      internal static func other(_ p1: Any) -> String {
        return L10n.tr("Shared", "MouseCodeName.Other", String(describing: p1))
      }
      /// Mouse(R)
      internal static let `right` = L10n.tr("Shared", "MouseCodeName.Right")
    }
    internal enum TipsTitle {
      /// Bug
      internal static let bug = L10n.tr("Shared", "TipsTitle.Bug")
      /// Tips
      internal static let `default` = L10n.tr("Shared", "TipsTitle.Default")
      /// Usage
      internal static let usage = L10n.tr("Shared", "TipsTitle.Usage")
    }
    internal enum View {
      /// Activator already in use
      internal static let activatorConflict = L10n.tr("Shared", "View.ActivatorConflict")
      /// Recording...
      internal static let enterKeyCombination = L10n.tr("Shared", "View.EnterKeyCombination")
      /// Set modifiers for left/right mouse button
      internal static let keyCombinationLeftRightMouseButtonNeedModifier = L10n.tr("Shared", "View.KeyCombinationLeftRightMouseButtonNeedModifier")
      /// Turn on listen to keyboard events in advanced settings
      internal static let keyCombinationNeedsKeyboardEventListener = L10n.tr("Shared", "View.KeyCombinationNeedsKeyboardEventListener")
      /// Setup
      internal static let keyCombinationNotSetup = L10n.tr("Shared", "View.KeyCombinationNotSetup")
    }
  }
  internal enum StatusBarMenu {
    /// Abnormal Mouse is disabled..
    internal static let isDisabled = L10n.tr("StatusBarMenu", "IsDisabled")
    /// Abnormal Mouse is functioning..
    internal static let isEnabled = L10n.tr("StatusBarMenu", "IsEnabled")
    /// Quit
    internal static let quit = L10n.tr("StatusBarMenu", "Quit")
    /// Show preferences
    internal static let showPreferences = L10n.tr("StatusBarMenu", "ShowPreferences")
    internal enum PurchaseStatus {
      /// License is valid.
      internal static let activated = L10n.tr("StatusBarMenu", "PurchaseStatus.Activated")
      /// Failed to verify license.
      internal static let cantVerify = L10n.tr("StatusBarMenu", "PurchaseStatus.CantVerify")
      /// Trial has ended.
      internal static let ended = L10n.tr("StatusBarMenu", "PurchaseStatus.Ended")
      /// Fetching activation status..
      internal static let fetching = L10n.tr("StatusBarMenu", "PurchaseStatus.Fetching")
      /// License is invalid.
      internal static let invalid = L10n.tr("StatusBarMenu", "PurchaseStatus.Invalid")
      /// License is refunded.
      internal static let refunded = L10n.tr("StatusBarMenu", "PurchaseStatus.Refunded")
      /// Trial ends in %@ days.
      internal static func trial(_ p1: Any) -> String {
        return L10n.tr("StatusBarMenu", "PurchaseStatus.Trial", String(describing: p1))
      }
    }
  }
  internal enum ZoomAndRotateSettings {
    internal enum SmartZoomView {
      /// Trigger when
      internal static let activationKeyCombinationTitle = L10n.tr("ZoomAndRotateSettings", "SmartZoomView.ActivationKeyCombinationTitle")
      /// Reuse activator for "zoom and rotate"
      internal static let doubleTapToActivate = L10n.tr("ZoomAndRotateSettings", "SmartZoomView.DoubleTapToActivate")
      /// With trackpads, you can zoom in with a double-tap. Now you can do the same with a key combination.
      internal static let introduction = L10n.tr("ZoomAndRotateSettings", "SmartZoomView.introduction")
      /// Smart Zoom
      internal static let title = L10n.tr("ZoomAndRotateSettings", "SmartZoomView.Title")
      internal enum Tips {
        /// Double tap activator for "zoom and rotate" to trigger smart zoom.
        internal static let usageA = L10n.tr("ZoomAndRotateSettings", "SmartZoomView.Tips.UsageA")
        /// Tap activator to trigger smart zoom.
        internal static let usageB = L10n.tr("ZoomAndRotateSettings", "SmartZoomView.Tips.UsageB")
      }
    }
    internal enum ZoomAndRotateView {
      /// Active when holding
      internal static let activationKeyCombinationTitle = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.ActivationKeyCombinationTitle")
      /// This feature converts mouse movement into zoom and rotate gestures.
      internal static let introduction = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.Introduction")
      /// Down to rotate clockwise
      internal static let rotateDirectionDown = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.RotateDirectionDown")
      /// Left to rotate clockwise
      internal static let rotateDirectionLeft = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.RotateDirectionLeft")
      /// Never Rotate
      internal static let rotateDirectionNone = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.RotateDirectionNone")
      /// Right to rotate clockwise
      internal static let rotateDirectionRight = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.RotateDirectionRight")
      /// Rotate gesture direction
      internal static let rotateDirectionTitle = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.RotateDirectionTitle")
      /// Up to rotate clockwise
      internal static let rotateDirectionUp = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.RotateDirectionUp")
      /// Rotate speed
      internal static let rotateSpeedSliderTitle = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.rotateSpeedSliderTitle")
      /// Zoom and Rotate
      internal static let title = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.Title")
      /// Down to zoom-in
      internal static let zoomDirectionDown = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.ZoomDirectionDown")
      /// Left to zoom-in
      internal static let zoomDirectionLeft = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.ZoomDirectionLeft")
      /// Never zoom
      internal static let zoomDirectionNone = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.ZoomDirectionNone")
      /// Right to zoom-in
      internal static let zoomDirectionRight = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.ZoomDirectionRight")
      /// Zoom gesture direction
      internal static let zoomDirectionTitle = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.ZoomDirectionTitle")
      /// Up to zoom-in
      internal static let zoomDirectionUp = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.ZoomDirectionUp")
      /// Zoom speed
      internal static let zoomSpeedSliderTitle = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.zoomSpeedSliderTitle")
      internal enum Tips {
        /// Sometimes, zoom and rotate will stop working. It's a known os issue that can't be fixed on our side. If you encounter this issue, pleas try the following steps to recover: \n① Re-enable these gestures from system preferences trackpad pane.\n② If you are using any other app that is using these gestures as triggers, turn them off, then reboot.\n③ Reboot fixes everything.
        internal static let recover = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.Tips.Recover")
        /// Hold activator then move your mouse to zoom or rotate.
        internal static let usage = L10n.tr("ZoomAndRotateSettings", "ZoomAndRotateView.Tips.Usage")
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
