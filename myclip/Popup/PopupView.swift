import SwiftUI

struct PopupView: View {
    @ObservedObject var vm: PopupViewModel
    var onPick: (Item) -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search clipboard…", text: $vm.query)
                .textFieldStyle(.roundedBorder)
                .padding(12)
            List {
                ForEach(Array(vm.items.enumerated()), id: \.element.id) { idx, item in
                    Text(item.text ?? "[image]")
                        .lineLimit(1)
                        .background(idx == vm.selectedIndex ? Color.accentColor.opacity(0.18) : .clear)
                        .onTapGesture { onPick(item) }
                }
            }
        }
        .frame(width: 440, height: 480)
    }
}
