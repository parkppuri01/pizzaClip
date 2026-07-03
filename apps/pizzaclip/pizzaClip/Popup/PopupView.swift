import SwiftUI
import AppKit

struct PopupView: View {
    @ObservedObject var vm: PopupViewModel
    var onPick: (Item) -> Void
    var onClose: () -> Void
    var onSettings: () -> Void
    var onClearAll: () -> Void

    /// Slot numbers run down the visible list in display order — pinned items
    /// first (they float to the top, ordered by when they were pinned), then
    /// the most-recent non-pinned items. So a pinned item literally *is* slot
    /// 1, and fresh captures stack below it from the next free number.
    private var slotForItem: [String: Int] {
        var map: [String: Int] = [:]
        var n = 1
        for item in vm.items where n <= 9 {
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
                Divider().overlay(AppColors.separator)
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
        HStack(spacing: 8) {
            Text("🍕")
                .font(.system(size: 13))
            Text(L("pizzaClip — Clipboard History", "pizzaClip — 클립보드 기록"))
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            if !vm.items.isEmpty {
                Text("\(vm.items.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.inkOnAmber)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(AppColors.amberFill, in: Capsule())
            }
            lockButton
            closeButton
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    /// 자물쇠 toggle. Unlocked = faded open padlock (default): the popup closes
    /// when you click away. Locked = solid white padlock: the popup stays open
    /// until you press ✕. `.focusable(false)` keeps the blue focus ring off.
    private var lockButton: some View {
        Button { vm.isLocked.toggle() } label: {
            Image(systemName: vm.isLocked ? "lock.fill" : "lock.open")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(vm.isLocked ? Color.white : Color.white.opacity(0.4))
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help(vm.isLocked ? L("Locked: stays open even when you click away (close with ✕)",
                              "잠금: 다른 창을 눌러도 닫히지 않아요 (✕로 닫기)")
                          : L("Unlocked: closes when you click away",
                              "잠금 해제: 다른 창을 누르면 닫혀요"))
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help(L("Close (Esc)", "닫기 (Esc)"))
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 12) {
                shortcutLabel(symbol: "↵", action: L("Paste(or Num)", "붙여넣기(또는 숫자)"))
                shortcutLabel(symbol: "⌫", action: L("Delete", "삭제"))
                shortcutLabel(symbol: "⌘P", action: L("Pin", "고정"))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text(L("Clear all", "모두 지우기"))
                }
                .foregroundColor(AppColors.secondaryLabel)
                .contentShape(Rectangle())
                .onTapGesture(perform: onClearAll)
                .help(L("Clear all clipboard history", "모든 클립보드 기록 지우기"))
                Text(L("⌘, Settings", "⌘, 설정"))
                    .foregroundColor(AppColors.secondaryLabel)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onSettings)
                    .help(L("Open Settings", "설정 열기"))
            }
            HStack(spacing: 4) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 9))
                    .foregroundColor(AppColors.tertiaryLabel)
                Text(abbreviatedStoragePath)
                    .foregroundColor(AppColors.tertiaryLabel)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: revealStorage)
                    .help(L("Reveal in Finder", "Finder에서 보기"))
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
