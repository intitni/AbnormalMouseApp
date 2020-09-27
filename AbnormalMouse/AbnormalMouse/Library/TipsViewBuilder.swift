import SwiftUI

@_functionBuilder
struct TipsViewBuilder {
    typealias Decorator = SettingsTipsDecorator

    static func d<Content: View>(_ content: Content) -> Decorator<Content> {
        Decorator(content: content)
    }

    static func buildBlock() -> EmptyView {
        EmptyView()
    }

    static func buildBlock<Content: View>(_ content: Content) -> Decorator<Content> {
        ViewBuilder.buildBlock(d(content))
    }

    static func buildBlock<C0: View, C1: View>(
        _ c0: C0,
        _ c1: C1
    ) -> TupleView<(Decorator<C0>, Decorator<C1>)> {
        ViewBuilder.buildBlock(d(c0), d(c1))
    }

    static func buildBlock<C0: View, C1: View, C2: View>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2
    ) -> TupleView<(Decorator<C0>, Decorator<C1>, Decorator<C2>)> {
        ViewBuilder.buildBlock(d(c0), d(c1), d(c2))
    }

    static func buildBlock<C0: View, C1: View, C2: View, C3: View>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3
    ) -> TupleView<(Decorator<C0>, Decorator<C1>, Decorator<C2>, Decorator<C3>)> {
        ViewBuilder.buildBlock(d(c0), d(c1), d(c2), d(c3))
    }

    static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4
    ) -> TupleView<(Decorator<C0>, Decorator<C1>, Decorator<C2>, Decorator<C3>, Decorator<C4>)> {
        ViewBuilder.buildBlock(d(c0), d(c1), d(c2), d(c3), d(c4))
    }

    static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5
    ) -> TupleView<(
        Decorator<C0>,
        Decorator<C1>,
        Decorator<C2>,
        Decorator<C3>,
        Decorator<C4>,
        Decorator<C5>
    )> {
        ViewBuilder.buildBlock(d(c0), d(c1), d(c2), d(c3), d(c4), d(c5))
    }

    static func buildEither<
        TrueContent: View,
        FalseContent: View
    >(
        first: TrueContent
    ) -> _ConditionalContent<Decorator<TrueContent>, Decorator<FalseContent>> {
        ViewBuilder.buildEither(first: d(first))
    }

    static func buildEither<
        TrueContent: View,
        FalseContent: View
    >(
        second: FalseContent
    ) -> _ConditionalContent<Decorator<TrueContent>, Decorator<FalseContent>> {
        ViewBuilder.buildEither(second: d(second))
    }

    static func buildIf<Content: View>(_ content: Content?) -> Decorator<Content>? {
        ViewBuilder.buildIf(content.map(d))
    }
}
