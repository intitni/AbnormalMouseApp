import AppKit
import SwiftUI

// MARK: - Text

extension Font {
    public static let pageTitle: Font = .system(size: 22, weight: .bold, design: .default)
    public static let introduction: Font = .footnote
    public static let widgetTitle: Font = .system(size: 14, weight: .semibold, design: .default)
}

struct FeatureIntroductionTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .font(.introduction)
            .foregroundColor(.gray)
    }
}

struct FeatureTitleTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.pageTitle)
    }
}

struct WidgetTitleTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.widgetTitle)
    }
}

struct ShadowModifier: ViewModifier {
    let color = Color(NSColor.shadowColor).opacity(0.2)
    let radius: CGFloat = 4
    let x: CGFloat = 0
    let y: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius, x: x, y: y)
    }
}

extension View {
    func asFeatureIntroduction() -> some View {
        modifier(FeatureIntroductionTextModifier())
    }

    func asFeatureTitle() -> some View {
        modifier(FeatureTitleTextModifier())
    }

    func asWidgetTitle() -> some View {
        modifier(WidgetTitleTextModifier())
    }

    func roundedCornerBackground(
        cornerRadius: CGFloat,
        fillColor: Color = .white,
        strokeColor: Color = .clear,
        strokeWidth: CGFloat = 0,
        shadow: ShadowModifier? = nil
    ) -> some View {
        let content = GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fillColor)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            }.frame(width: proxy.size.width, height: proxy.size.height)
        }
        if let shadowModifier = shadow {
            return background(AnyView(content.modifier(shadowModifier)))
        }
        return background(AnyView(content))
    }

    func circleBackground(
        fillColor: Color = .white,
        strokeColor: Color = .clear,
        strokeWidth: CGFloat = 0
    ) -> some View {
        background(
            GeometryReader { proxy in
                ZStack {
                    RoundedRectangle(
                        cornerRadius: min(proxy.size.width, proxy.size.height) / 2,
                        style: .continuous
                    )
                    .fill(fillColor)
                    RoundedRectangle(
                        cornerRadius: min(proxy.size.width, proxy.size.height) / 2,
                        style: .continuous
                    )
                    .stroke(strokeColor, lineWidth: strokeWidth)
                }.frame(width: proxy.size.width, height: proxy.size.height)
            }
        )
    }

    func overlayWhen<Overlay>(
        _ shouldOverlay: Bool,
        view: Overlay,
        alignment: Alignment = .center
    ) -> some View where Overlay: View {
        if shouldOverlay {
            return overlay(AnyView(view), alignment: alignment)
        }
        return overlay(AnyView(EmptyView()), alignment: alignment)
    }
}
