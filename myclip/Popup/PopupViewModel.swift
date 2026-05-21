import Combine
import Foundation

public final class PopupViewModel: ObservableObject {
    @Published public var query: String = ""
    @Published public var items: [Item] = []
    @Published public var selectedIndex: Int = 0

    private let store: HistoryStore
    private var cancellables: Set<AnyCancellable> = []

    public init(store: HistoryStore) {
        self.store = store
        reload()
        $query
            .debounce(for: .milliseconds(80), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &cancellables)
    }

    public func reload() {
        items = (try? store.search(query, limit: 200)) ?? []
        selectedIndex = min(selectedIndex, max(0, items.count - 1))
    }

    public func moveDown() { if selectedIndex + 1 < items.count { selectedIndex += 1 } }
    public func moveUp() { if selectedIndex > 0 { selectedIndex -= 1 } }
    public func selectedItem() -> Item? {
        guard items.indices.contains(selectedIndex) else { return nil }
        return items[selectedIndex]
    }

    public func topNNonPinned(_ n: Int) throws -> [Item] {
        try store.topNNonPinned(n)
    }
}
