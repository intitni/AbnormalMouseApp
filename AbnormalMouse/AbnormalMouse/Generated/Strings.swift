// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
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
      /// Can't verify license, please check the key and email entered is correct.
      internal static let invalid = L10n.tr("Activation", "FailureReason.Invalid")
      /// Please check your network and try again.
      internal static let networkError = L10n.tr("Activation", "FailureReason.NetworkError")
      /// The license key has reached activation limit. Please deactivate first.
      internal static let reachedLimit = L10n.tr("Activation", "FailureReason.ReachedLimit")
      /// The license key has been refunded.
      internal static let refunded = L10n.tr("Activation", "FailureReason.Refunded")
    }
  }
  internal enum Advanced {
    internal enum View {
      /// Listen to keyboard event (restart app to take effect)
      internal static let listenToKeyboardEvent = L10n.tr("Advanced", "View.ListenToKeyboardEvent")
      /// Defaultly this app listens to your keystrokes so you can use hotkeys as activators. But letting an app read your keystrokes can be risky (though we are not doing anything). You can turn it off if you are only using mouse buttons as activators. You can use tools like ReiKey to check if the app is still listening to you keystrokes
      internal static let listenToKeyboardEventIntroduction = L10n.tr("Advanced", "View.ListenToKeyboardEventIntroduction")
      /// Advanced
      internal static let title = L10n.tr("Advanced", "View.Title")
    }
  }
  internal enum DockSwipeSettings {
    internal enum View {
      /// Active when holding
      internal static let activationKeyCombinationTitle = L10n.tr("DockSwipeSettings", "View.ActivationKeyCombinationTitle")
      /// This feature converts mouse movement into four-finger swipe, so you can switch spaces with a normal mouse.
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
    internal static func licenseTo(_ p1: String) -> String {
      return L10n.tr("General", "LicenseTo", p1)
    }
    /// License is valid.
    internal static let licenseValid = L10n.tr("General", "LicenseValid")
    /// Buy Now
    internal static let purchase = L10n.tr("General", "Purchase")
    /// Quit Abnormal Mouse
    internal static let quit = L10n.tr("General", "Quit")
    /// Trial will end in %d days.
    internal static func trialDaysRemain(_ p1: Int) -> String {
      return L10n.tr("General", "TrialDaysRemain", p1)
    }
    /// Trial has ended.
    internal static let trialEnd = L10n.tr("General", "TrialEnd")
    /// Version %@
    internal static func version(_ p1: String) -> String {
      return L10n.tr("General", "Version", p1)
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
  internal enum NeedAccessability {
    internal enum View {
      /// Turn On Accessability
      internal static let enableButtonTitle = L10n.tr("NeedAccessability", "View.EnableButtonTitle")
      /// The app needs accessability enabled to read and manipulate keyboard and mouse events.
      internal static let introduction = L10n.tr("NeedAccessability", "View.Introduction")
      /// Go to System Preferences > Security & Privacy > Privacy > Accessability
      internal static let manual = L10n.tr("NeedAccessability", "View.Manual")
      /// Abnormal Mouse Needs to Be Free!
      internal static let title = L10n.tr("NeedAccessability", "View.Title")
    }
  }
  internal enum ScrollSettings {
    internal enum View {
      /// Active when holding
      internal static let activationKeyCombinationTitle = L10n.tr("ScrollSettings", "View.ActivationKeyCombinationTitle")
      /// Emulate inertia effect
      internal static let inertiaEffectCheckboxTitle = L10n.tr("ScrollSettings", "View.InertiaEffectCheckboxTitle")
      /// We recommend you to keep it on, disabling it will disable inertia effect in some apps.
      internal static let inertiaEffectIntroduction = L10n.tr("ScrollSettings", "View.InertiaEffectIntroduction")
      /// This feature converts mouse movement into scrolling. Better than that, it also allows you to play drag gestures by moving the mouse, like navigating back in Safari or marking emails as read in the Mail app.
      internal static let introduction = L10n.tr("ScrollSettings", "View.Introduction")
      /// Scroll speed controls how mouse movements will be scaled into scrolls, a bigger number is preferred since you will not want to move the mouse a lot to scroll.
      internal static let scrollSpeedSliderIntroduction = L10n.tr("ScrollSettings", "View.ScrollSpeedSliderIntroduction")
      /// Scroll speed
      internal static let scrollSpeedSliderTitle = L10n.tr("ScrollSettings", "View.ScrollSpeedSliderTitle")
      /// Swipe speed controls how it's scaled into swipe gesture translations, a lower speed will make it feel more natural.
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
      internal static func other(_ p1: String) -> String {
        return L10n.tr("Shared", "MouseCodeName.Other", p1)
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
      /// Enter key combination
      internal static let enterKeyCombination = L10n.tr("Shared", "View.EnterKeyCombination")
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
      /// Trial ends in %d days.
      internal static func trial(_ p1: Int) -> String {
        return L10n.tr("StatusBarMenu", "PurchaseStatus.Trial", p1)
      }
    }
  }
  internal enum ZoomAndRotateSettings {
    internal enum SmartZoomView {
      /// Trigger when
      internal static let activationKeyCombinationTitle = L10n.tr("ZoomAndRotateSettings", "SmartZoomView.ActivationKeyCombinationTitle")
      /// Double tap key combination to smart zoom
      internal static let doubleTapToActivate = L10n.tr("ZoomAndRotateSettings", "SmartZoomView.DoubleTapToActivate")
      /// With trackpad, you can zoom in with double-tap. Now you can do the same with a key combination.
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
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // swiftlint:disable:next nslocalizedstring_key
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
