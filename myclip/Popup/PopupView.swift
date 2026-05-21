import SwiftUI
import AppKit

struct PopupView: View {
    @ObservedObject var vm: PopupViewModel
    var onPick: (Item) -> Void
    var onClose: () -> Void
    var onDelete: (Item) -> Void
    var onTogglePin: (Item) -> Void

    var body: some View {
        ZStack {
            KeyHandlerView { event in
                switch event.keyCode {
                case 53: // esc
                    onClose(); return true
                case 36, 76: // return / numpad enter
                    if let item = vm.selectedItem() { onPick(item) }
                    return true
                case 125: // down arrow
                    vm.moveDown(); return true
                case 126: // up arrow
                    vm.moveUp(); return true
                case 51: // delete
                    if let item = vm.selectedItem() { onDelete(item) }
                    return true
                default:
                    if event.modifierFlags.contains(.command),
                       event.charactersIgnoringModifiers == "p",
                       let item = vm.selectedItem() {
                        onTogglePin(item)
                        return true
                    }
                    return false
                }
            }
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                TextField("Search clipboard…", text: $vm.query)
                    .textFieldStyle(.roundedBorder)
                    .padding(12)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(vm.items.enumerated()), id: \.element.id) { idx, item in
                            PopupRow(item: item, selected: idx == vm.selectedIndex)
                                .onTapGesture { onPick(item) }
                        }
                    }.padding(.horizontal, 8)
                }
                Divider()
                HStack(spacing: 12) {
                    Text("↵ Paste").foregroundColor(.secondary)
                    Text("⌫ Delete").foregroundColor(.secondary)
                    Text("⌘P Pin").foregroundColor(.secondary)
                    Spacer()
                    Text("⌘, Settings").foregroundColor(.secondary)
                }.font(.system(size: 11)).padding(.horizontal, 12).padding(.vertical, 6)
            }
        }
        .frame(width: 440, height: 480)
    }
}

struct KeyHandlerView: NSViewRepresentable {
    final class Coordinator: NSObject {
        var onKey: (NSEvent) -> Bool = { _ in false }
    }
    let onKey: (NSEvent) -> Bool

    func makeCoordinator() -> Coordinator {
        let c = Coordinator(); c.onKey = onKey; return c
    }
    func makeNSView(context: Context) -> NSView {
        let v = KeyView()
        v.coordinator = context.coordinator
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? KeyView)?.coordinator = context.coordinator
    }

    final class KeyView: NSView {
        weak var coordinator: Coordinator?
        override var acceptsFirstResponder: Bool { true }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(self)
        }
        override func keyDown(with event: NSEvent) {
            if coordinator?.onKey(event) == true { return }
            super.keyDown(with: event)
        }
    }
}
