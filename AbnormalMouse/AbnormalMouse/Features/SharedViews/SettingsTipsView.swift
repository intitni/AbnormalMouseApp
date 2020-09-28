import SwiftUI

struct SettingsTips<Content: View>: View {
    let content: Content

    init(@TipsViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { content }
            .padding(.top, 12)
    }
}

struct SettingsTipsDecorator<Content: View>: View {
    let content: Content
    @State var title: String = ""
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(Color.white)
                    .padding([.leading, .trailing], 4)
                    .padding(.top, 2)
                    .padding(.bottom, 3)
                    .roundedCornerBackground(cornerRadius: 4, fillColor: Color.accentColor)
                    .shadow(radius: 1)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.clear,
                            ]),
                            startPoint: .init(x: 0.5, y: 0),
                            endPoint: .init(x: 0.5, y: 0.1)
                        )
                        .blur(radius: 4).cornerRadius(4)
                    )
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.1),
                                Color.clear,
                            ]),
                            startPoint: .init(x: 0.5, y: 1),
                            endPoint: .init(x: 0.5, y: 0.9)
                        )
                        .blur(radius: 4).cornerRadius(4)
                    )
            }

            content
                .asFeatureIntroduction()
        }
//        .onPreferenceChange(SettingsTipsTitleKey.self) { title in
//            self.title = title
//        } // There is a bug preventing the upper block to call! Workaround below.
        .overlayPreferenceValue(SettingsTipsTitleKey.self) { title in
            EmptyView().onAppear {
                self.title = title
            }
        }
    }
}

struct SettingsTipsTitleKey: PreferenceKey {
    static var defaultValue: String = ""
    static func reduce(value: inout String, nextValue: () -> String) {
        value = nextValue()
    }
}

extension View {
    func tipsTitle(_ title: String) -> some View {
        preference(key: SettingsTipsTitleKey.self, value: title)
    }
}

struct SettingsTipsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsTips(content: { Text("Hello world.").tipsTitle("New") })
            .padding(10)
            .frame(width: 300, alignment: .leading)
    }
}
