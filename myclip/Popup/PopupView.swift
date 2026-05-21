import SwiftUI
import AppKit

struct PopupView: View {
    @ObservedObject var vm: PopupViewModel
    var onPick: (Item) -> Void
    var onClose: () -> Void
    var onDelete: (Item) -> Void
    var onTogglePin: (Item) -> Void

    private var slotForItem: [String: Int] {
        var map: [String: Int] = [:]
        var n = 1
        for item in vm.items where !item.pinned && n <= 9 {
            map[item.id] = n; n += 1
        }
        return map
    }

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blending: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: Theme.panelRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.panelRadius)
                        .stroke(AppColors.separator, lineWidth: 1)
                )

            VStack(spacing: 0) {
                searchField
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(vm.items.enumerated()), id: \.element.id) { idx, item in
                            PopupRow(item: item,
                                     selected: idx == vm.selectedIndex,
                                     slot: slotForItem[item.id])
                                .onTapGesture { onPick(item) }
                        }
                    }.padding(.horizontal, 8)
                }
                Divider().opacity(0.5)
                footer
            }
        }
        .frame(width: Theme.panelWidth, height: Theme.panelHeight)
        .accentColor(AppColors.accent)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(AppColors.secondaryLabel)
            TextField("Search clipboard…", text: $vm.query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
        )
        .padding(12)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Text("↵ Paste").foregroundColor(AppColors.secondaryLabel)
            Text("⌫ Delete").foregroundColor(AppColors.secondaryLabel)
            Text("⌘P Pin").foregroundColor(AppColors.secondaryLabel)
            Spacer()
            Text("⌘, Settings").foregroundColor(AppColors.secondaryLabel)
        }
        .font(.system(size: 11))
        .padding(.horizontal, 12).padding(.vertical, 6)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blending: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blending
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
