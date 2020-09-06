import ComposableArchitecture
import SwiftUI

struct NeedAccessabilityScreen: View {
    let store: NeedAccessabilityDomain.Store

    var body: some View {
        NeedAccessabilityView(store: store)
    }
}

private struct NeedAccessabilityView: View {
    let store: NeedAccessabilityDomain.Store

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                Image(Asset.iconAccessabilityOff.name)
                Text(_L10n.View.title)
                    .font(.pageTitle)
                Spacer().frame(height: 8)
                Text(_L10n.View.introduction)
                    .asFeatureIntroduction()
                Spacer().frame(height: 8)
                Button(action: { viewStore.send(.goToAccessbilityPreferencePane) }) {
                    Text(_L10n.View.enableButtonTitle)
                }
                Text(_L10n.View.manual)
                    .asFeatureIntroduction()
            }
        }
        .padding(.init(top: 20, leading: 20, bottom: 20, trailing: 20))
        .frame(width: 500)
    }
}

struct NeedAccessabilityView_Previews: PreviewProvider {
    static var previews: some View {
        NeedAccessabilityView(store: .testStore)
    }
}

private enum _L10n {
    typealias View = L10n.NeedAccessability.View
}
