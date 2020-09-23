# Abnormal Mouse <img alt="Logo" src="https://abnormalmouse.intii.com/image/icon.png" align="right" height="50">

[Feature Description](https://abnormalmouse.intii.com) | [中文](https://github.com/intitni/AbnormalMouseApp/blob/master/README_CN.md)

At the end of 2019, I bought a strange mouse with an angular shape, an arrow key, a pair of AB keys, and an almost unusable touch wheel. It would be a nice decoration if I didn't think of it as a mouse. Because of the epidemic of Covid-19, I decided not to bring my MacBook Pro to work. I had to use a Mac Mini at work, and I couldn't find a reason to buy another Magic Mouse to use in the office, I decided to use the mouse.

Using a normal mouse in macOS is a terrible thing, the missing gestures and four-way scrolling is a huge problem. For example, there's no way to pan left or right when looking at UI designs. And Swish, my favorite window management tool, doesn't work anymore. So I decided to write an app to improve it, trying to trigger these features by just moving the mouse (and holding some buttons).

### The currently supported features are
- Four-way scrolling (drag-to-scroll by holding down the trigger button and moving the mouse, which may seem odd, but I kind of like it).
- Two-finger swipe gestures (Safari's swipe to back, Reeder's pull to refresh, etc.).
- Zoom and rotate.
  
### The planned features are
- [ ] Four-finger gesture.
- [ ] Shared triggers.

## About this version
Abnormal Mouse itself is a paid app, but the open-source part does not include code related to software activation. If you compile it yourself,  you will be able to use it for free. If you like this app, please consider [buying a copy here](https://abnormalmouse.intii.com).

## How to use it

1. Clone this repo.
2. Install [CocoaPods](https://cocoapods.org).
3. Execute `make bootstrap`.
4. Compile and run with Xcode.
5. Turn off automatically check for updates.

## Contribute.

- If you find a bug, or if there is a feature you want, please feel free to open an issue.
