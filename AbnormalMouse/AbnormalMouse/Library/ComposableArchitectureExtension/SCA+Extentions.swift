import ComposableArchitecture
import SwiftUI

extension View {
    func backgroundEmptyViewWithViewStore<State, Action, Content>(
        _ store: Store<State, Action>,
        modify: @escaping (EmptyView, ViewStore<State, Action>) -> Content
    ) -> some View where State: Equatable, Content: View {
        background(WithViewStore(store) { viewStore in
            modify(EmptyView(), viewStore)
        })
    }

    func lifeCycleWithViewStore<State, Action>(
        _ store: Store<State, Action>,
        onAppear: @escaping (ViewStore<State, Action>) -> Void = { _ in },
        onDisappear: @escaping (ViewStore<State, Action>) -> Void = { _ in }
    ) -> some View where State: Equatable {
        backgroundEmptyViewWithViewStore(store) { view, viewStore in
            view
                .onAppear { onAppear(viewStore) }
                .onDisappear { onDisappear(viewStore) }
        }
    }
}
