import SwiftUI
import AppKit

struct PopupView: View {
    @ObservedObject var vm: PopupViewModel
    var onPick: (Item) -> Void
    var onClose: () -> Void
    var onSettings: () -> Void
    var onClearAll: () -> Void
    var onPasteAll: () -> Void

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
                titleBar
                fullPasteRow
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(vm.items.enumerated()), id: \.element.id) { idx, item in
                                PopupRow(item: item,
                                         selected: idx == vm.selectedIndex,
                                         slot: slotForItem[item.id])
                                    .id(item.id)
                                    .contentShape(Rectangle())
                                    .onHover { hovered in
                                        if hovered { vm.setHovered(idx) }
                                    }
                                    .onTapGesture { onPick(item) }
                            }
                        }.padding(.horizontal, 8)
                    }
                    .onChange(of: vm.selectedIndex) { newValue in
                        // Only auto-scroll when the change came from a keyboard
                        // arrow. Hover-driven selection (and search reloads) just
                        // updates the highlight without yanking the viewport.
                        guard vm.pendingKeyboardScroll else { return }
                        vm.pendingKeyboardScroll = false
                        guard vm.items.indices.contains(newValue) else { return }
                        withAnimation(.linear(duration: 0.08)) {
                            proxy.scrollTo(vm.items[newValue].id, anchor: .center)
                        }
                    }
                }
                Divider().opacity(0.5)
                footer
            }

            // Easter egg overlay — sits on top of everything but ignores hits
            // so the underlying list/buttons stay interactive while pizzas
            // are flying. Clipped to the panel's rounded rect so particles
            // can't escape past the chrome.
            PizzaBurst(trigger: vm.pizzaBurstID)
                .clipShape(RoundedRectangle(cornerRadius: Theme.panelRadius))
                .allowsHitTesting(false)
        }
        .frame(width: Theme.panelWidth, height: Theme.panelHeight)
        .accentColor(AppColors.accent)
    }

    private var titleBar: some View {
        HStack(spacing: 6) {
            Text("🍕")
                .font(.system(size: 13))
            Text("pizzaClip — Clipboard History")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.secondaryLabel)
            Spacer()
            // Plain Image instead of Button — sidesteps SwiftUI's default
            // keyboard-focus ring (the blue selection look the user saw).
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.secondaryLabel)
                .contentShape(Rectangle())
                .onTapGesture(perform: onClose)
                .help("Close (Esc)")
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var fullPasteRow: some View {
        HStack(spacing: 10) {
            Text("0")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColors.inkOnAmber)
                .frame(width: 20, height: 20)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(AppColors.amberFill)
                )
            Text("9 → 1 full paste")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "arrow.down.to.line")
                .foregroundColor(AppColors.secondaryLabel)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onPasteAll)
        .help("Paste items 9 → 1 sequentially into the previous app")
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 12) {
                shortcutLabel(symbol: "↵", action: "Paste(or Num)")
                shortcutLabel(symbol: "⌫", action: "Delete")
                shortcutLabel(symbol: "⌘P", action: "Pin")
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text("Clear all")
                }
                .foregroundColor(AppColors.secondaryLabel)
                .contentShape(Rectangle())
                .onTapGesture(perform: onClearAll)
                .help("Clear all clipboard history")
                Text("⌘, Settings")
                    .foregroundColor(AppColors.secondaryLabel)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onSettings)
                    .help("Open Settings")
            }
            HStack(spacing: 4) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 9))
                    .foregroundColor(AppColors.tertiaryLabel)
                Text(abbreviatedStoragePath)
                    .foregroundColor(AppColors.tertiaryLabel)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: revealStorage)
                    .help("Reveal in Finder")
            }
        }
        .font(.system(size: 11))
        .padding(.horizontal, 12).padding(.vertical, 6)
    }

    /// Symbol in secondary gray, action word in coral accent.
    private func shortcutLabel(symbol: String, action: String) -> Text {
        Text("\(symbol) ").foregroundColor(AppColors.secondaryLabel)
        + Text(action).foregroundColor(AppColors.accent)
    }


    private var abbreviatedStoragePath: String {
        (AppPaths.supportDirectory.path as NSString).abbreviatingWithTildeInPath
    }

    private func revealStorage() {
        NSWorkspace.shared.open(AppPaths.supportDirectory)
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
