import Foundation

public final class PopupViewModel: ObservableObject {
    @Published public var items: [Item] = []
    @Published public var selectedIndex: Int = 0

    /// Set true by keyboard navigation. Observed once by the view to drive a
    /// `scrollTo`, then reset by the consumer. Hover-driven selection never
    /// flips this on, so mouse-driven highlight stays put without scrolling.
    @Published public var pendingKeyboardScroll: Bool = false

    /// Bumps to a new UUID every time the pizza easter-egg should fire — the
    /// `PizzaBurst` view watches this via `.onChange` and starts a fresh
    /// confetti animation. Nil = no burst has happened yet.
    @Published public var pizzaBurstID: UUID? = nil

    private let store: HistoryStore
    private var lastKeyboardNavAt: Date = .distantPast
    /// Brief window after keyboard nav during which hover events are ignored —
    /// otherwise a `scrollTo` animation drags new rows under the cursor and
    /// the resulting onHover steals the highlight from the row the user just
    /// arrowed to.
    private let hoverIgnoreWindow: TimeInterval = 0.25

    public init(store: HistoryStore) {
        self.store = store
        reload()
    }

    public func reload() {
        // Remember which item was highlighted before refetching so the user's
        // selection sticks to the same row even when new captures arrive or
        // pins float to the top.
        let previousID = items.indices.contains(selectedIndex) ? items[selectedIndex].id : nil
        items = (try? store.search("", limit: 200)) ?? []
        if let previousID, let idx = items.firstIndex(where: { $0.id == previousID }) {
            selectedIndex = idx
        } else {
            selectedIndex = min(selectedIndex, max(0, items.count - 1))
        }
    }

    public func moveDown() {
        guard selectedIndex + 1 < items.count else { return }
        lastKeyboardNavAt = Date()
        pendingKeyboardScroll = true
        selectedIndex += 1
    }
    public func moveUp() {
        guard selectedIndex > 0 else { return }
        lastKeyboardNavAt = Date()
        pendingKeyboardScroll = true
        selectedIndex -= 1
    }

    /// Mouse hover → just move the highlight. Never schedules a scroll. Briefly
    /// ignored right after a keyboard arrow so the scroll-induced motion doesn't
    /// hijack the selection.
    public func setHovered(_ idx: Int) {
        guard items.indices.contains(idx) else { return }
        if Date().timeIntervalSince(lastKeyboardNavAt) < hoverIgnoreWindow { return }
        if selectedIndex != idx {
            selectedIndex = idx
        }
    }

    public func triggerPizzaBurst() {
        pizzaBurstID = UUID()
    }

    public func selectedItem() -> Item? {
        guard items.indices.contains(selectedIndex) else { return nil }
        return items[selectedIndex]
    }

    public func topNNonPinned(_ n: Int) throws -> [Item] {
        try store.topNNonPinned(n)
    }
}
