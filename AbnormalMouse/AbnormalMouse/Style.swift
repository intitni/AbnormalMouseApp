import AppKit
import SwiftUI

// MARK: - Text

extension Font {
    public static let pageTitle: Font = .system(size: 22, weight: .bold, design: .default)
    public static let introduction: Font = .system(size: 12)
    public static let widgetTitle: Font = .system(size: 14, weight: .semibold, design: .default)
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

struct Style_Title_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Feature Title").asFeatureTitle()
            Text("Feature Introduction").asFeatureIntroduction()
            Text("Widget Title").asWidgetTitle()
        }
        .frame(width: 200, alignment: .leading)
        .padding(4)
    }
}

// MARK: - Background

struct ShadowModifier: ViewModifier {
    var color = Color(NSColor.shadowColor).opacity(0.2)
    var radius: CGFloat = 4
    var x: CGFloat = 0
    var y: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius, x: x, y: y)
    }
}

extension View {
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
}

struct Style_RoundedCornerBackground_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
            .padding(4)
            .roundedCornerBackground(
                cornerRadius: 4,
                fillColor: .gray,
                strokeColor: .black,
                strokeWidth: 2,
                shadow: ShadowModifier(color: .black, radius: 4, x: 0, y: 1)
            )
            .padding(10)
    }
}

extension View {
    func circleBackground(
        fillColor: Color = .white,
        strokeColor: Color = .clear,
        strokeWidth: CGFloat = 0,
        shadow: ShadowModifier? = nil
    ) -> some View {
        let content = GeometryReader { proxy in
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
        if let shadowModifier = shadow {
            return background(AnyView(content.modifier(shadowModifier)))
        }
        return background(AnyView(content))
    }
}

struct Style_CircleBackground_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
            .padding(4)
            .circleBackground(
                fillColor: .gray,
                strokeColor: .black,
                strokeWidth: 2
            )
            .padding(10)
    }
}

extension View {
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
