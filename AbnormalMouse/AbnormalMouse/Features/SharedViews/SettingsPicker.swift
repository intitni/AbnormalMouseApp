import SwiftUI

struct SettingsPicker<Title: View, SelectionValue: Hashable, Content: View>: View {
    let title: Title
    let selection: Binding<SelectionValue>
    let content: () -> Content

    var body: some View {
        HStack(alignment: .center) {
            title.asWidgetTitle()
            Picker(selection: selection, label: EmptyView(), content: content)
                .frame(maxWidth: 200)
        }
    }
}

struct SettingsPicker_Previews: PreviewProvider {
    @State static var selected = 1

    static var previews: some View {
        SettingsPicker(
            title: Text("Title"),
            selection: $selected,
            content: {
                ForEach(1..<4) {
                    Text(String($0))
                }
            }
        )
        .padding(10)
    }
}
