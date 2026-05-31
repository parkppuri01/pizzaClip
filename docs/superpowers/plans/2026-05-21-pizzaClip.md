# myclip Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menu-bar clipboard history app (Swift + AppKit shell + SwiftUI) that captures text/image/file clipboard events, restores them via auto-paste, exposes ⌘⌥⌃1–9 direct-slot hotkeys, and presents a Claude-Desktop-styled popup.

**Architecture:** AppKit composition root (`AppDelegate`) owns a non-activating `NSPanel` hosting a SwiftUI `PopupView`, a `ClipboardMonitor` polling `NSPasteboard.changeCount`, a `HistoryStore` backed by GRDB SQLite (FTS5), and a `PasteEngine` that activates the prior frontmost app and synthesizes ⌘V via `CGEvent`. Image blobs live in `~/Library/Application Support/myclip/blobs/`.

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit, GRDB.swift, KeyboardShortcuts (sindresorhus), XCTest. Target macOS 13+.

**Spec:** `docs/superpowers/specs/2026-05-21-myclip-design.md`

---

## File Structure

```
myclip/
├── myclip.xcodeproj/
├── myclip/
│   ├── App/
│   │   ├── myclipApp.swift            # @main App entry (NSApplicationDelegateAdaptor)
│   │   └── AppDelegate.swift          # composition root, status item, hotkey wiring
│   ├── Clipboard/
│   │   ├── Pasteboard.swift           # protocol over NSPasteboard for testability
│   │   ├── ClipboardMonitor.swift     # change-count polling + classifier + drop rules
│   │   └── CapturedItem.swift         # value type emitted by monitor
│   ├── Storage/
│   │   ├── HistoryStore.swift         # GRDB-backed CRUD + Combine snapshot
│   │   ├── Schema.swift               # migrations (items table, FTS5 triggers)
│   │   ├── BlobStore.swift            # filesystem blobs + thumbnail generation
│   │   └── Item.swift                 # DB row model
│   ├── Paste/
│   │   └── PasteEngine.swift          # write pasteboard + activate + ⌘V CGEvent
│   ├── Popup/
│   │   ├── PopupPanelController.swift # NSPanel.nonactivatingPanel lifecycle
│   │   ├── PopupView.swift            # SwiftUI search + list
│   │   ├── PopupRow.swift             # one list row
│   │   └── PopupViewModel.swift       # query state, selection, filtering
│   ├── Settings/
│   │   ├── SettingsWindow.swift       # NSWindow host
│   │   └── SettingsView.swift         # SwiftUI Form tabs (General/Shortcuts/Privacy/Storage)
│   ├── Shortcuts/
│   │   └── Shortcut.swift             # KeyboardShortcuts.Name extensions
│   ├── Permissions/
│   │   └── Accessibility.swift        # AXIsProcessTrustedWithOptions helpers
│   ├── DesignSystem/
│   │   ├── Colors.swift               # accent + semantic colors
│   │   └── Theme.swift                # radii, spacing constants
│   ├── Assets.xcassets
│   └── Info.plist                     # LSUIElement = YES
├── myclipTests/
│   ├── HistoryStoreTests.swift
│   ├── ClipboardMonitorTests.swift
│   ├── BlobStoreTests.swift
│   └── Fakes/
│       └── FakePasteboard.swift
├── docs/
│   ├── superpowers/specs/2026-05-21-myclip-design.md
│   ├── superpowers/plans/2026-05-21-myclip.md
│   └── qa/checklist.md
└── README.md
```

Each file has a single responsibility per the spec's "Module responsibilities" section. The `Clipboard`, `Storage`, `Paste`, `Popup` layers communicate through well-defined types (`CapturedItem`, `Item`) and never reach across layers.

---

## Task 1: Bootstrap Xcode project + dependencies (XcodeGen)

We use `xcodegen` (already installed via Homebrew) so the project is reproducible from a YAML spec. The generated `.xcodeproj` is **not** committed; the `project.yml` is the source of truth.

**Files:**
- Create: `project.yml`
- Create: `myclip/App/myclipApp.swift`
- Create: `myclip/App/AppDelegate.swift` (minimal stub for build)
- Create: `myclip/Info.plist`
- Create: `myclipTests/Placeholder.swift`
- Create: `.gitignore`
- Create: `README.md` (one-liner placeholder; expanded in Task 16)

- [ ] **Step 1: Write `.gitignore`**

```
.DS_Store
build/
DerivedData/
*.xcodeproj/
.swiftpm/
.build/
xcuserdata/
```

- [ ] **Step 2: Write `project.yml`**

```yaml
name: myclip
options:
  bundleIdPrefix: com.jekeun
  deploymentTarget:
    macOS: "13.0"
  createIntermediateGroups: true
settings:
  base:
    SWIFT_VERSION: "5.9"
    MARKETING_VERSION: "0.1.0"
    CURRENT_PROJECT_VERSION: "1"
    DEVELOPMENT_TEAM: ""
    CODE_SIGN_STYLE: Automatic
    CODE_SIGN_IDENTITY: "-"
packages:
  GRDB:
    url: https://github.com/groue/GRDB.swift
    from: "6.0.0"
  KeyboardShortcuts:
    url: https://github.com/sindresorhus/KeyboardShortcuts
    from: "2.0.0"
targets:
  myclip:
    type: application
    platform: macOS
    sources:
      - path: myclip
    info:
      path: myclip/Info.plist
      properties:
        LSUIElement: true
        CFBundleName: myclip
        CFBundleDisplayName: myclip
        CFBundleShortVersionString: "0.1.0"
        CFBundleVersion: "1"
        NSHumanReadableCopyright: ""
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.jekeun.myclip
        GENERATE_INFOPLIST_FILE: NO
        INFOPLIST_FILE: myclip/Info.plist
    dependencies:
      - package: GRDB
        product: GRDB
      - package: KeyboardShortcuts
        product: KeyboardShortcuts
  myclipTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - path: myclipTests
    dependencies:
      - target: myclip
schemes:
  myclip:
    build:
      targets:
        myclip: all
        myclipTests: [test]
    test:
      targets:
        - myclipTests
```

- [ ] **Step 3: Write minimal `Info.plist`**

Path: `myclip/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$(EXECUTABLE_NAME)</string>
  <key>CFBundleIdentifier</key>
  <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$(PRODUCT_NAME)</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>myclip uses Apple events to paste into the previous application.</string>
</dict>
</plist>
```

- [ ] **Step 4: Stub `myclipApp.swift` and `AppDelegate.swift`**

`myclip/App/myclipApp.swift`:

```swift
import SwiftUI

@main
struct MyclipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var body: some Scene { Settings { EmptyView() } }
}
```

`myclip/App/AppDelegate.swift`:

```swift
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // expanded in Task 2
    }
}
```

- [ ] **Step 5: Placeholder test so the test target compiles**

`myclipTests/Placeholder.swift`:

```swift
import XCTest

final class PlaceholderTests: XCTestCase {
    func test_placeholder() { XCTAssertTrue(true) }
}
```

- [ ] **Step 6: Placeholder README**

`README.md`:

```markdown
# myclip

macOS clipboard history app. See `docs/superpowers/specs/2026-05-21-myclip-design.md`.

## Generate Xcode project

    xcodegen generate

## Build

    xcodebuild -project myclip.xcodeproj -scheme myclip -destination 'platform=macOS' build
```

- [ ] **Step 7: Generate and build**

Run:
```bash
xcodegen generate
xcodebuild -project myclip.xcodeproj -scheme myclip -destination 'platform=macOS' build -quiet
```

Expected: `Generated project` line from xcodegen, then `BUILD SUCCEEDED` from xcodebuild.

- [ ] **Step 8: Run tests to confirm test target works**

```bash
xcodebuild -project myclip.xcodeproj -scheme myclip -destination 'platform=macOS' test -quiet 2>&1 | tail -20
```

Expected: `** TEST SUCCEEDED **`, 1 test passes.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "chore: scaffold xcodegen project with GRDB and KeyboardShortcuts"
```

---

## Task 2: Menu-bar shell in AppDelegate

The `myclipApp.swift` stub from Task 1 already routes to `AppDelegate`. This task fleshes out `AppDelegate` to install the menu bar status item.

**Files:**
- Modify: `myclip/App/AppDelegate.swift`

- [ ] **Step 1: Verify scaffold still builds**

Run: `xcodebuild -project myclip.xcodeproj -scheme myclip build -quiet`
Expected: BUILD SUCCEEDED.

- [ ] **Step 2: Keep `myclipApp.swift` as-is from Task 1**

```swift
import SwiftUI

@main
struct MyclipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
```

The `Settings` scene is a placeholder so SwiftUI has something to attach to; we won't use it.

- [ ] **Step 3: Create `AppDelegate.swift`**

```swift
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard",
                                   accessibilityDescription: "myclip")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Popup",
                                action: #selector(openPopup),
                                keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings…",
                                action: #selector(openSettings),
                                keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit myclip",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func openPopup() {
        // wired in Task 10
        NSSound.beep()
    }

    @objc private func openSettings() {
        // wired in Task 15
        NSSound.beep()
    }
}
```

- [ ] **Step 4: Run the app**

Cmd-R in Xcode. Expected:
- No Dock icon appears.
- A clipboard glyph appears in the menu bar.
- Clicking it shows Open Popup / Settings… / Quit myclip.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: menu-bar shell with status item and placeholder menu"
```

---

## Task 3: `Pasteboard` protocol + `FakePasteboard` (testable seam)

**Files:**
- Create: `myclip/Clipboard/Pasteboard.swift`
- Create: `myclip/Clipboard/CapturedItem.swift`
- Create: `myclipTests/Fakes/FakePasteboard.swift`
- Create: `myclipTests/PasteboardTests.swift`

- [ ] **Step 1: Write `PasteboardReader` protocol**

(Named `PasteboardReader` instead of plain `Pasteboard` to avoid a collision with the Carbon-era `ApplicationServices.Pasteboard` class that AppKit transitively exposes inside `@testable` test targets.)

```swift
import AppKit

public protocol PasteboardReader: AnyObject {
    var changeCount: Int { get }
    func types() -> [NSPasteboard.PasteboardType]
    func data(forType type: NSPasteboard.PasteboardType) -> Data?
    func string(forType type: NSPasteboard.PasteboardType) -> String?
}

extension NSPasteboard: PasteboardReader {
    public func types() -> [NSPasteboard.PasteboardType] {
        self.types ?? []
    }
}
```

- [ ] **Step 2: Write `CapturedItem`**

```swift
import Foundation

public enum CapturedKind: String, Codable {
    case text, image, file
}

public struct CapturedItem: Equatable {
    public let id: UUID
    public let kind: CapturedKind
    public let text: String?         // text → body; file → absolute path
    public let imageData: Data?      // image → PNG bytes
    public let sourceBundleID: String?
    public let createdAt: Date

    public init(id: UUID = UUID(),
                kind: CapturedKind,
                text: String? = nil,
                imageData: Data? = nil,
                sourceBundleID: String? = nil,
                createdAt: Date = Date()) {
        self.id = id
        self.kind = kind
        self.text = text
        self.imageData = imageData
        self.sourceBundleID = sourceBundleID
        self.createdAt = createdAt
    }
}
```

- [ ] **Step 3: Write the failing test**

```swift
import XCTest
import AppKit
@testable import myclip

final class PasteboardTests: XCTestCase {
    func test_fakePasteboard_reportsChangeCountAndTypes() {
        let fake = FakePasteboard()
        XCTAssertEqual(fake.changeCount, 0)

        fake.put(string: "hello", type: .string)
        XCTAssertEqual(fake.changeCount, 1)
        XCTAssertEqual(fake.types(), [.string])
        XCTAssertEqual(fake.string(forType: .string), "hello")
    }
}
```

- [ ] **Step 4: Run the test, watch it fail**

In Xcode: Cmd-U. Or:
`xcodebuild -project myclip.xcodeproj -scheme myclip test -destination 'platform=macOS' -only-testing:myclipTests/PasteboardTests`

Expected: FAIL — `FakePasteboard` undefined.

- [ ] **Step 5: Implement `FakePasteboard`**

```swift
import AppKit
@testable import myclip

final class FakePasteboard: PasteboardReader {
    private(set) var changeCount: Int = 0
    private var contents: [NSPasteboard.PasteboardType: Data] = [:]
    private var strings: [NSPasteboard.PasteboardType: String] = [:]

    func put(string: String, type: NSPasteboard.PasteboardType) {
        strings[type] = string
        contents[type] = Data(string.utf8)
        changeCount += 1
    }

    func put(data: Data, type: NSPasteboard.PasteboardType) {
        contents[type] = data
        strings.removeValue(forKey: type)
        changeCount += 1
    }

    func clear() {
        contents.removeAll()
        strings.removeAll()
        changeCount += 1
    }

    func types() -> [NSPasteboard.PasteboardType] { Array(contents.keys) }
    func data(forType type: NSPasteboard.PasteboardType) -> Data? { contents[type] }
    func string(forType type: NSPasteboard.PasteboardType) -> String? { strings[type] }
}
```

- [ ] **Step 6: Run tests again, expect PASS**

Expected: 1 test passes.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: Pasteboard protocol + CapturedItem + FakePasteboard"
```

---

## Task 4: `HistoryStore` schema + insert/topN (TDD)

**Files:**
- Create: `myclip/Storage/Schema.swift`
- Create: `myclip/Storage/Item.swift`
- Create: `myclip/Storage/HistoryStore.swift`
- Create: `myclipTests/HistoryStoreTests.swift`

- [ ] **Step 1: Write `Item.swift`**

```swift
import Foundation
import GRDB

public struct Item: Identifiable, Equatable, FetchableRecord, PersistableRecord, Codable {
    public static let databaseTableName = "items"

    public var id: String        // UUID string
    public var type: String      // "text" | "image" | "file"
    public var text: String?     // body or absolute file path
    public var blobPath: String? // relative path under blobs/
    public var thumbPng: Data?   // image only
    public var sourceBundle: String?
    public var createdAt: Int64  // unix ms
    public var pinned: Bool

    enum Columns {
        static let id = Column("id")
        static let type = Column("type")
        static let text = Column("text")
        static let blobPath = Column("blob_path")
        static let thumbPng = Column("thumb_png")
        static let sourceBundle = Column("source_bundle")
        static let createdAt = Column("created_at")
        static let pinned = Column("pinned")
    }
}
```

- [ ] **Step 2: Write `Schema.swift`**

```swift
import GRDB

enum Schema {
    static func migrator() -> DatabaseMigrator {
        var m = DatabaseMigrator()
        m.registerMigration("v1") { db in
            try db.create(table: "items") { t in
                t.column("id", .text).primaryKey()
                t.column("type", .text).notNull()
                t.column("text", .text)
                t.column("blob_path", .text)
                t.column("thumb_png", .blob)
                t.column("source_bundle", .text)
                t.column("created_at", .integer).notNull()
                t.column("pinned", .integer).notNull().defaults(to: 0)
            }
            try db.execute(sql: """
                CREATE INDEX idx_items_created ON items(created_at DESC);
                CREATE INDEX idx_items_pinned  ON items(pinned, created_at DESC);
            """)
        }
        return m
    }
}
```

- [ ] **Step 3: Write the failing test**

```swift
import XCTest
import GRDB
@testable import myclip

final class HistoryStoreTests: XCTestCase {
    private func makeStore() throws -> HistoryStore {
        let queue = try DatabaseQueue() // in-memory
        return try HistoryStore(queue: queue)
    }

    func test_insert_thenTopN_returnsNewestFirst() throws {
        let store = try makeStore()
        let a = CapturedItem(kind: .text, text: "first")
        let b = CapturedItem(kind: .text, text: "second")
        try store.insert(a)
        Thread.sleep(forTimeInterval: 0.005)
        try store.insert(b)

        let top = try store.topN(10)
        XCTAssertEqual(top.map(\.text), ["second", "first"])
    }

    func test_insert_dedupesIdenticalText() throws {
        let store = try makeStore()
        try store.insert(CapturedItem(kind: .text, text: "hi"))
        try store.insert(CapturedItem(kind: .text, text: "hi"))

        let top = try store.topN(10)
        XCTAssertEqual(top.count, 1, "identical text within history should dedupe")
    }
}
```

- [ ] **Step 4: Run tests, expect FAIL**

Expected: `HistoryStore` undefined.

- [ ] **Step 5: Implement `HistoryStore`**

```swift
import Foundation
import GRDB
import Combine

public final class HistoryStore {
    private let queue: DatabaseWriter
    @Published public private(set) var snapshot: [Item] = []

    public init(queue: DatabaseWriter) throws {
        self.queue = queue
        try Schema.migrator().migrate(queue)
        try reloadSnapshot()
    }

    public func insert(_ captured: CapturedItem) throws {
        try queue.write { db in
            // Dedupe rule: if newest non-pinned text item has the same body, just bump its timestamp.
            if captured.kind == .text, let text = captured.text {
                if let existing = try Item
                    .filter(Item.Columns.type == "text" && Item.Columns.text == text)
                    .order(Item.Columns.createdAt.desc)
                    .fetchOne(db) {
                    var bumped = existing
                    bumped.createdAt = Int64(captured.createdAt.timeIntervalSince1970 * 1000)
                    try bumped.update(db)
                    return
                }
            }

            let row = Item(
                id: captured.id.uuidString,
                type: captured.kind.rawValue,
                text: captured.text,
                blobPath: nil,            // BlobStore wires this up in Task 6
                thumbPng: nil,
                sourceBundle: captured.sourceBundleID,
                createdAt: Int64(captured.createdAt.timeIntervalSince1970 * 1000),
                pinned: false
            )
            try row.insert(db)
        }
        try reloadSnapshot()
    }

    public func topN(_ n: Int) throws -> [Item] {
        try queue.read { db in
            try Item
                .order(Item.Columns.createdAt.desc)
                .limit(n)
                .fetchAll(db)
        }
    }

    public func delete(id: String) throws {
        try queue.write { db in
            _ = try Item.deleteOne(db, key: id)
        }
        try reloadSnapshot()
    }

    private func reloadSnapshot() throws {
        snapshot = try topN(500)
    }
}
```

- [ ] **Step 6: Run tests, expect PASS**

Expected: both tests pass.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: HistoryStore with insert, topN, delete + dedupe rule"
```

---

## Task 5: `HistoryStore` pin + prune (TDD)

**Files:**
- Modify: `myclip/Storage/HistoryStore.swift`
- Modify: `myclipTests/HistoryStoreTests.swift`

- [ ] **Step 1: Add failing tests**

Append to `HistoryStoreTests.swift`:

```swift
func test_togglePin_movesItemAboveNonPinned() throws {
    let store = try makeStore()
    try store.insert(CapturedItem(kind: .text, text: "a"))
    try store.insert(CapturedItem(kind: .text, text: "b"))
    let aID = try XCTUnwrap(store.topN(10).first(where: { $0.text == "a" })?.id)

    try store.togglePin(id: aID)
    let ordered = try store.topNRespectingPins(10)
    XCTAssertEqual(ordered.first?.text, "a", "pinned item should be on top")
    XCTAssertTrue(ordered.first?.pinned == true)
}

func test_prune_dropsOldestNonPinned_keepsPinned() throws {
    let store = try makeStore()
    for i in 0..<5 { try store.insert(CapturedItem(kind: .text, text: "t\(i)")) }
    let pinned = try XCTUnwrap(store.topN(10).first(where: { $0.text == "t0" })?.id)
    try store.togglePin(id: pinned)

    try store.prune(cap: 3)

    let remaining = try store.topN(10).map(\.text)
    XCTAssertTrue(remaining.contains("t0"), "pinned t0 must survive")
    XCTAssertEqual(remaining.count, 4, "3 newest non-pinned + 1 pinned")
}
```

- [ ] **Step 2: Run tests, expect FAIL**

Expected: undefined methods `togglePin`, `topNRespectingPins`, `prune`.

- [ ] **Step 3: Implement the methods**

Add inside `HistoryStore`:

```swift
public func togglePin(id: String) throws {
    try queue.write { db in
        guard var item = try Item.fetchOne(db, key: id) else { return }
        item.pinned.toggle()
        try item.update(db)
    }
    try reloadSnapshot()
}

public func topNRespectingPins(_ n: Int) throws -> [Item] {
    try queue.read { db in
        try Item
            .order(Item.Columns.pinned.desc, Item.Columns.createdAt.desc)
            .limit(n)
            .fetchAll(db)
    }
}

public func prune(cap: Int) throws {
    try queue.write { db in
        let nonPinned = try Item
            .filter(Item.Columns.pinned == false)
            .order(Item.Columns.createdAt.desc)
            .fetchAll(db)
        guard nonPinned.count > cap else { return }
        let toDelete = nonPinned[cap...]
        for item in toDelete {
            // BlobStore cleanup wires in Task 6
            _ = try Item.deleteOne(db, key: item.id)
        }
    }
    try reloadSnapshot()
}
```

- [ ] **Step 4: Run tests, expect PASS**

Expected: all 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: pin + prune on HistoryStore"
```

---

## Task 6: `BlobStore` for image payloads + thumbnail (TDD)

**Files:**
- Create: `myclip/Storage/BlobStore.swift`
- Create: `myclipTests/BlobStoreTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import AppKit
@testable import myclip

final class BlobStoreTests: XCTestCase {
    private func tmpDir() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("blobstore-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func test_writePNG_storesFileAndProducesThumbnail() throws {
        let store = BlobStore(rootDirectory: tmpDir())
        let image = NSImage(size: NSSize(width: 800, height: 600))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: 800, height: 600).fill()
        image.unlockFocus()

        let png = try XCTUnwrap(image.pngData())

        let written = try store.write(png: png)
        XCTAssertTrue(FileManager.default.fileExists(atPath: written.fileURL.path))
        XCTAssertNotNil(written.thumbnailPNG)
        XCTAssertLessThan(written.thumbnailPNG.count, 60_000)
    }

    func test_remove_deletesFile() throws {
        let store = BlobStore(rootDirectory: tmpDir())
        let written = try store.write(png: Data([0x89, 0x50, 0x4E, 0x47])) // not valid PNG, ok for round-trip
        try store.remove(relativePath: written.relativePath)
        XCTAssertFalse(FileManager.default.fileExists(atPath: written.fileURL.path))
    }
}
```

- [ ] **Step 2: Add the `NSImage.pngData` helper test util**

Add to the test target (top of the file or shared helper):

```swift
extension NSImage {
    func pngData() -> Data? {
        guard let tiff = tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
```

- [ ] **Step 3: Run tests, expect FAIL**

Expected: `BlobStore` undefined.

- [ ] **Step 4: Implement `BlobStore`**

```swift
import Foundation
import AppKit

public struct WrittenBlob {
    public let relativePath: String   // e.g. "ab/abc...uuid.png"
    public let fileURL: URL
    public let thumbnailPNG: Data
}

public final class BlobStore {
    public let rootDirectory: URL

    public init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
        try? FileManager.default.createDirectory(at: rootDirectory,
                                                 withIntermediateDirectories: true)
    }

    public func write(png: Data) throws -> WrittenBlob {
        let id = UUID().uuidString
        let prefix = String(id.prefix(2)).lowercased()
        let subdir = rootDirectory.appendingPathComponent(prefix)
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
        let relative = "\(prefix)/\(id).png"
        let url = rootDirectory.appendingPathComponent(relative)
        try png.write(to: url)
        let thumb = makeThumbnail(from: png) ?? Data()
        return WrittenBlob(relativePath: relative, fileURL: url, thumbnailPNG: thumb)
    }

    public func remove(relativePath: String) throws {
        let url = rootDirectory.appendingPathComponent(relativePath)
        try FileManager.default.removeItem(at: url)
    }

    private func makeThumbnail(from png: Data) -> Data? {
        guard let img = NSImage(data: png) else { return nil }
        let maxSide: CGFloat = 256
        let size = img.size
        let scale = min(maxSide / max(size.width, 1), maxSide / max(size.height, 1), 1)
        let targetW = Int((size.width * scale).rounded())
        let targetH = Int((size.height * scale).rounded())
        guard targetW > 0, targetH > 0 else { return nil }

        // Draw into a NSBitmapImageRep with explicit pixel dimensions instead of
        // NSImage.lockFocus() — lockFocus uses the current display's backing scale,
        // so Retina screens produce a 2x bitmap and blow past the size budget.
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: targetW, pixelsHigh: targetH,
            bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0
        ) else { return nil }
        rep.size = NSSize(width: targetW, height: targetH)

        NSGraphicsContext.saveGraphicsState()
        guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
            NSGraphicsContext.restoreGraphicsState(); return nil
        }
        NSGraphicsContext.current = ctx
        img.draw(in: NSRect(x: 0, y: 0, width: targetW, height: targetH),
                 from: .zero, operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        return rep.representation(using: .png, properties: [:])
    }
}
```

- [ ] **Step 5: Run tests, expect PASS**

Expected: both tests pass.

- [ ] **Step 6: Wire BlobStore into HistoryStore for image inserts**

Modify `HistoryStore.insert`:

Find the `kind == .text` short-circuit block. After it, replace the existing `let row = Item(...)` block with logic that handles images:

```swift
var blobRelative: String? = nil
var thumb: Data? = nil
if captured.kind == .image, let png = captured.imageData, let store = blobStore {
    let written = try store.write(png: png)
    blobRelative = written.relativePath
    thumb = written.thumbnailPNG
}

let row = Item(
    id: captured.id.uuidString,
    type: captured.kind.rawValue,
    text: captured.text,
    blobPath: blobRelative,
    thumbPng: thumb,
    sourceBundle: captured.sourceBundleID,
    createdAt: Int64(captured.createdAt.timeIntervalSince1970 * 1000),
    pinned: false
)
try row.insert(db)
```

And add to `HistoryStore`:

```swift
private let blobStore: BlobStore?

public init(queue: DatabaseWriter, blobStore: BlobStore? = nil) throws {
    self.queue = queue
    self.blobStore = blobStore
    try Schema.migrator().migrate(queue)
    try reloadSnapshot()
}
```

Also update `prune` to delete blob files when removing image rows:

```swift
public func prune(cap: Int) throws {
    try queue.write { db in
        let nonPinned = try Item
            .filter(Item.Columns.pinned == false)
            .order(Item.Columns.createdAt.desc)
            .fetchAll(db)
        guard nonPinned.count > cap else { return }
        let toDelete = nonPinned[cap...]
        for item in toDelete {
            if let path = item.blobPath { try? blobStore?.remove(relativePath: path) }
            _ = try Item.deleteOne(db, key: item.id)
        }
    }
    try reloadSnapshot()
}
```

- [ ] **Step 7: Run all tests, expect PASS**

Expected: all `HistoryStoreTests` + `BlobStoreTests` pass.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: BlobStore + image payload wiring in HistoryStore"
```

---

## Task 7: `HistoryStore` FTS5 search (TDD)

**Files:**
- Modify: `myclip/Storage/Schema.swift`
- Modify: `myclip/Storage/HistoryStore.swift`
- Modify: `myclipTests/HistoryStoreTests.swift`

- [ ] **Step 1: Add failing search tests**

```swift
func test_search_findsByTextFragment() throws {
    let store = try makeStore()
    try store.insert(CapturedItem(kind: .text, text: "the quick brown fox"))
    try store.insert(CapturedItem(kind: .text, text: "lazy dog sleeping"))
    try store.insert(CapturedItem(kind: .text, text: "foxtrot dance"))

    let hits = try store.search("fox", limit: 10).map(\.text)
    XCTAssertTrue(hits.contains("the quick brown fox"))
    XCTAssertTrue(hits.contains("foxtrot dance"))
    XCTAssertFalse(hits.contains("lazy dog sleeping"))
}

func test_search_emptyQuery_returnsTopNRespectingPins() throws {
    let store = try makeStore()
    try store.insert(CapturedItem(kind: .text, text: "a"))
    try store.insert(CapturedItem(kind: .text, text: "b"))
    let hits = try store.search("", limit: 10).map(\.text)
    XCTAssertEqual(hits, ["b", "a"])
}
```

- [ ] **Step 2: Run tests, expect FAIL**

Expected: undefined `search`.

- [ ] **Step 3: Add FTS5 migration**

In `Schema.swift`, register a v2 migration:

```swift
m.registerMigration("v2-fts5") { db in
    try db.execute(sql: """
        CREATE VIRTUAL TABLE items_fts USING fts5(text, content='items', content_rowid='rowid');
        INSERT INTO items_fts(rowid, text) SELECT rowid, text FROM items WHERE text IS NOT NULL;

        CREATE TRIGGER items_ai AFTER INSERT ON items BEGIN
          INSERT INTO items_fts(rowid, text) VALUES (new.rowid, new.text);
        END;
        CREATE TRIGGER items_ad AFTER DELETE ON items BEGIN
          INSERT INTO items_fts(items_fts, rowid, text) VALUES('delete', old.rowid, old.text);
        END;
        CREATE TRIGGER items_au AFTER UPDATE ON items BEGIN
          INSERT INTO items_fts(items_fts, rowid, text) VALUES('delete', old.rowid, old.text);
          INSERT INTO items_fts(rowid, text) VALUES (new.rowid, new.text);
        END;
    """)
}
```

- [ ] **Step 4: Implement `search`**

In `HistoryStore`:

```swift
public func search(_ query: String, limit: Int) throws -> [Item] {
    let trimmed = query.trimmingCharacters(in: .whitespaces)
    if trimmed.isEmpty { return try topNRespectingPins(limit) }

    let escaped = trimmed.replacingOccurrences(of: "\"", with: "\"\"")
    let ftsQuery = "\"\(escaped)\"*"  // prefix match, quoted to defang FTS5 operators

    return try queue.read { db in
        try Item.fetchAll(db, sql: """
            SELECT items.* FROM items
            JOIN items_fts ON items_fts.rowid = items.rowid
            WHERE items_fts MATCH ?
            ORDER BY items.pinned DESC, items.created_at DESC
            LIMIT ?
        """, arguments: [ftsQuery, limit])
    }
}
```

- [ ] **Step 5: Run tests, expect PASS**

Expected: both search tests pass + all earlier tests still pass.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: FTS5 search on HistoryStore"
```

---

## Task 8: `ClipboardMonitor` — classifier + drop rules (TDD)

**Files:**
- Create: `myclip/Clipboard/ClipboardMonitor.swift`
- Create: `myclipTests/ClipboardMonitorTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import XCTest
import AppKit
@testable import myclip

final class ClipboardMonitorTests: XCTestCase {
    func test_textPaste_emitsTextItem() {
        let fake = FakePasteboard()
        var captured: [CapturedItem] = []
        let monitor = ClipboardMonitor(pasteboard: fake,
                                       frontmostBundleID: { "com.apple.Safari" },
                                       blacklistedBundleIDs: { [] },
                                       onCapture: { captured.append($0) })

        fake.put(string: "hello world", type: .string)
        monitor.tick()

        XCTAssertEqual(captured.count, 1)
        XCTAssertEqual(captured.first?.kind, .text)
        XCTAssertEqual(captured.first?.text, "hello world")
        XCTAssertEqual(captured.first?.sourceBundleID, "com.apple.Safari")
    }

    func test_concealedType_isDropped() {
        let fake = FakePasteboard()
        var captured: [CapturedItem] = []
        let monitor = ClipboardMonitor(pasteboard: fake,
                                       frontmostBundleID: { "com.1password.1password" },
                                       blacklistedBundleIDs: { [] },
                                       onCapture: { captured.append($0) })

        fake.put(string: "supersecret", type: .string)
        fake.put(data: Data(), type: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
        monitor.tick()

        XCTAssertTrue(captured.isEmpty, "concealed type must drop the payload")
    }

    func test_blacklistedFrontmost_isDropped() {
        let fake = FakePasteboard()
        var captured: [CapturedItem] = []
        let monitor = ClipboardMonitor(pasteboard: fake,
                                       frontmostBundleID: { "com.bitwarden.desktop" },
                                       blacklistedBundleIDs: { ["com.bitwarden.desktop"] },
                                       onCapture: { captured.append($0) })

        fake.put(string: "vaulted", type: .string)
        monitor.tick()
        XCTAssertTrue(captured.isEmpty)
    }

    func test_imagePayload_emitsImageItem() {
        let fake = FakePasteboard()
        var captured: [CapturedItem] = []
        let monitor = ClipboardMonitor(pasteboard: fake,
                                       frontmostBundleID: { "com.apple.screencapture" },
                                       blacklistedBundleIDs: { [] },
                                       onCapture: { captured.append($0) })

        fake.put(data: Data([0x89, 0x50, 0x4E, 0x47]), type: .png)
        monitor.tick()

        XCTAssertEqual(captured.first?.kind, .image)
        XCTAssertNotNil(captured.first?.imageData)
    }

    func test_filePayload_emitsFileItem() {
        let fake = FakePasteboard()
        var captured: [CapturedItem] = []
        let monitor = ClipboardMonitor(pasteboard: fake,
                                       frontmostBundleID: { "com.apple.finder" },
                                       blacklistedBundleIDs: { [] },
                                       onCapture: { captured.append($0) })

        let url = URL(fileURLWithPath: "/tmp/foo.txt")
        fake.put(string: url.path, type: .fileURL)
        monitor.tick()

        XCTAssertEqual(captured.first?.kind, .file)
        XCTAssertEqual(captured.first?.text, "/tmp/foo.txt")
    }

    func test_sameChangeCount_doesNotReemit() {
        let fake = FakePasteboard()
        var captured: [CapturedItem] = []
        let monitor = ClipboardMonitor(pasteboard: fake,
                                       frontmostBundleID: { nil },
                                       blacklistedBundleIDs: { [] },
                                       onCapture: { captured.append($0) })

        fake.put(string: "one", type: .string)
        monitor.tick()
        monitor.tick()
        XCTAssertEqual(captured.count, 1)
    }
}
```

- [ ] **Step 2: Run tests, expect FAIL**

Expected: `ClipboardMonitor` undefined.

- [ ] **Step 3: Implement `ClipboardMonitor`**

```swift
import Foundation
import AppKit

public final class ClipboardMonitor {
    private let pasteboard: PasteboardReader
    private let frontmostBundleID: () -> String?
    private let blacklistedBundleIDs: () -> Set<String>
    private let onCapture: (CapturedItem) -> Void
    private var lastChangeCount: Int
    private var timer: Timer?

    public init(pasteboard: PasteboardReader,
                frontmostBundleID: @escaping () -> String?,
                blacklistedBundleIDs: @escaping () -> Set<String>,
                onCapture: @escaping (CapturedItem) -> Void) {
        self.pasteboard = pasteboard
        self.frontmostBundleID = frontmostBundleID
        self.blacklistedBundleIDs = blacklistedBundleIDs
        self.onCapture = onCapture
        self.lastChangeCount = pasteboard.changeCount
    }

    public func start(interval: TimeInterval = 0.4) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    public func tick() {
        let current = pasteboard.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        let types = Set(pasteboard.types().map(\.rawValue))
        let concealed: Set<String> = [
            "org.nspasteboard.ConcealedType",
            "org.nspasteboard.TransientType",
            "org.nspasteboard.AutoGeneratedType",
        ]
        if !types.isDisjoint(with: concealed) { return }

        let bundle = frontmostBundleID()
        if let b = bundle, blacklistedBundleIDs().contains(b) { return }

        // Order: file > image > text. A file in Finder also brings .string for the path; image
        // overrides text because screenshots can include a stub string.
        if pasteboard.types().contains(.fileURL),
           let path = pasteboard.string(forType: .fileURL) {
            onCapture(CapturedItem(kind: .file, text: path, sourceBundleID: bundle))
            return
        }
        if pasteboard.types().contains(.png),
           let png = pasteboard.data(forType: .png) {
            onCapture(CapturedItem(kind: .image, imageData: png, sourceBundleID: bundle))
            return
        }
        if pasteboard.types().contains(.tiff),
           let tiff = pasteboard.data(forType: .tiff),
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            onCapture(CapturedItem(kind: .image, imageData: png, sourceBundleID: bundle))
            return
        }
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            onCapture(CapturedItem(kind: .text, text: text, sourceBundleID: bundle))
            return
        }
    }
}
```

- [ ] **Step 4: Run tests, expect PASS**

Expected: all 6 monitor tests pass.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: ClipboardMonitor with classifier and drop rules"
```

---

## Task 9: Wire `ClipboardMonitor` + `HistoryStore` into `AppDelegate`

**Files:**
- Modify: `myclip/App/AppDelegate.swift`
- Create: `myclip/App/AppPaths.swift`

- [ ] **Step 1: Create `AppPaths.swift`**

```swift
import Foundation

enum AppPaths {
    static var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask).first!
        let dir = base.appendingPathComponent("myclip", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    static var databaseURL: URL { supportDirectory.appendingPathComponent("db.sqlite") }
    static var blobsDirectory: URL { supportDirectory.appendingPathComponent("blobs", isDirectory: true) }
}
```

- [ ] **Step 2: Wire `AppDelegate`**

Replace the body of `AppDelegate` with:

```swift
import AppKit
import GRDB

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private(set) var store: HistoryStore!
    private var monitor: ClipboardMonitor!
    private var blacklist: Set<String> = [
        "com.1password.1password",
        "com.agilebits.onepassword7",
        "com.bitwarden.desktop",
        "com.apple.keychainaccess",
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpStorage()
        setUpStatusItem()
        setUpMonitor()
    }

    private func setUpStorage() {
        do {
            let queue = try DatabaseQueue(path: AppPaths.databaseURL.path)
            let blobs = BlobStore(rootDirectory: AppPaths.blobsDirectory)
            store = try HistoryStore(queue: queue, blobStore: blobs)
        } catch {
            NSLog("myclip storage init failed: \(error). Falling back to in-memory.")
            let queue = try! DatabaseQueue()
            store = try! HistoryStore(queue: queue, blobStore: nil)
        }
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "doc.on.clipboard",
                                           accessibilityDescription: "myclip")
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Popup",
                                action: #selector(openPopup), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings…",
                                action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit myclip",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func setUpMonitor() {
        monitor = ClipboardMonitor(
            pasteboard: NSPasteboard.general,
            frontmostBundleID: { NSWorkspace.shared.frontmostApplication?.bundleIdentifier },
            blacklistedBundleIDs: { [weak self] in self?.blacklist ?? [] },
            onCapture: { [weak self] item in
                guard let self else { return }
                do {
                    try self.store.insert(item)
                    try self.store.prune(cap: 200)
                } catch {
                    NSLog("myclip insert failed: \(error)")
                }
            }
        )
        monitor.start()
    }

    @objc private func openPopup() { NSSound.beep() }  // wired in Task 11
    @objc private func openSettings() { NSSound.beep() } // wired in Task 15
}
```

- [ ] **Step 3: Manual smoke test**

Run the app (Cmd-R). With the app running:
1. Copy text in any app (e.g., Safari URL bar).
2. Stop the app from Xcode.
3. In Terminal: `sqlite3 ~/Library/Application\ Support/myclip/db.sqlite 'SELECT type, substr(text,1,40) FROM items;'`

Expected: at least one row with `text` showing what you copied.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: wire monitor + store into AppDelegate with persistent DB"
```

---

## Task 10: `PasteEngine` — clipboard write + activate + ⌘V

**Files:**
- Create: `myclip/Paste/PasteEngine.swift`

This is mostly manual-QA territory (synthesizing ⌘V can't be meaningfully unit-tested without an integration harness).

- [ ] **Step 1: Implement `PasteEngine`**

```swift
import AppKit

public final class PasteEngine {
    public init() {}

    public func write(_ item: Item, blobStore: BlobStore?) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.type {
        case "text":
            if let text = item.text { pb.setString(text, forType: .string) }
        case "file":
            if let path = item.text {
                let url = URL(fileURLWithPath: path)
                pb.writeObjects([url as NSURL])
            }
        case "image":
            if let path = item.blobPath, let blobs = blobStore {
                let fileURL = blobs.rootDirectory.appendingPathComponent(path)
                if let data = try? Data(contentsOf: fileURL) {
                    pb.setData(data, forType: .png)
                }
            }
        default: break
        }
    }

    public func pasteIntoPreviousApp(bundleID: String?) {
        if let id = bundleID,
           let app = NSRunningApplication.runningApplications(withBundleIdentifier: id).first {
            app.activate(options: [.activateIgnoringOtherApps])
        }
        // Give the OS ~50ms to bring the target window forward before sending ⌘V.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.sendCommandV()
        }
    }

    private func sendCommandV() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let vDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)
        vDown?.flags = .maskCommand
        let vUp = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
    }
}
```

- [ ] **Step 2: Build**

`xcodebuild -project myclip.xcodeproj -scheme myclip build -quiet`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: PasteEngine with payload write and synthesized cmd+V"
```

---

## Task 11: Global popup hotkey + `PopupPanelController` (focus-preserving panel)

**Files:**
- Create: `myclip/Shortcuts/Shortcut.swift`
- Create: `myclip/Popup/PopupPanelController.swift`
- Create: `myclip/Popup/PopupView.swift` (placeholder)
- Create: `myclip/Popup/PopupViewModel.swift`
- Modify: `myclip/App/AppDelegate.swift`

- [ ] **Step 1: Define shortcut names**

```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePopup = Self("togglePopup", default: .init(.v, modifiers: [.command, .shift]))
    static func slot(_ n: Int) -> Self { Self("slot\(n)") }
}
```

(Default for slot 1–9 is unset so the user assigns them explicitly. We don't preset because ⌘⌥⌃ digit chords sometimes clash with input methods on non-US keyboards.)

- [ ] **Step 2: Create `PopupViewModel`**

```swift
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
}
```

- [ ] **Step 3: Create a minimal `PopupView` placeholder**

```swift
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
```

This is intentionally bare; styling lands in Task 13.

- [ ] **Step 4: Create `PopupPanelController`**

```swift
import AppKit
import SwiftUI

final class PopupPanelController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<PopupView>?
    private var previousFrontmostBundleID: String?
    private let viewModel: PopupViewModel
    private let pasteEngine: PasteEngine
    private let blobStore: BlobStore?

    init(viewModel: PopupViewModel, pasteEngine: PasteEngine, blobStore: BlobStore?) {
        self.viewModel = viewModel
        self.pasteEngine = pasteEngine
        self.blobStore = blobStore
    }

    func toggle() {
        if let panel = panel, panel.isVisible { close(); return }
        show()
    }

    func show() {
        previousFrontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        viewModel.query = ""
        viewModel.reload()

        let view = PopupView(
            vm: viewModel,
            onPick: { [weak self] item in self?.pick(item) },
            onClose: { [weak self] in self?.close() }
        )
        let hosting = NSHostingView(rootView: view)
        self.hostingView = hosting

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 480),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.contentView = hosting

        if let screen = NSScreen.main {
            let rect = screen.visibleFrame
            let origin = NSPoint(x: rect.midX - 220,
                                 y: rect.midY - 240 + rect.height * 0.10)
            panel.setFrameOrigin(origin)
        }
        panel.orderFrontRegardless()
        // Make panel key so the search field accepts typing, without activating the app.
        panel.makeKey()

        self.panel = panel
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
        hostingView = nil
    }

    func pick(_ item: Item) {
        let prev = previousFrontmostBundleID
        pasteEngine.write(item, blobStore: blobStore)
        close()
        pasteEngine.pasteIntoPreviousApp(bundleID: prev)
    }

    func pasteDirect(slot: Int) {
        previousFrontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard let items = try? viewModel
            .store_topNNonPinned(slot) else { return }
        guard let item = items[safe: slot - 1] else { return }
        pasteEngine.write(item, blobStore: blobStore)
        pasteEngine.pasteIntoPreviousApp(bundleID: previousFrontmostBundleID)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
```

Note the `viewModel.store_topNNonPinned(slot)` call — add this helper to `PopupViewModel`:

```swift
public func store_topNNonPinned(_ n: Int) throws -> [Item] {
    try store.topNNonPinned(n)
}
```

And add to `HistoryStore`:

```swift
public func topNNonPinned(_ n: Int) throws -> [Item] {
    try queue.read { db in
        try Item
            .filter(Item.Columns.pinned == false)
            .order(Item.Columns.createdAt.desc)
            .limit(n)
            .fetchAll(db)
    }
}
```

- [ ] **Step 5: Wire popup + shortcuts into `AppDelegate`**

Add to `AppDelegate`:

```swift
import KeyboardShortcuts

private var popupController: PopupPanelController!
private var pasteEngine = PasteEngine()
private var viewModel: PopupViewModel!
private var blobStore: BlobStore?

func setUpPopup() {
    let blobs = BlobStore(rootDirectory: AppPaths.blobsDirectory)
    self.blobStore = blobs
    self.viewModel = PopupViewModel(store: store)
    self.popupController = PopupPanelController(
        viewModel: viewModel,
        pasteEngine: pasteEngine,
        blobStore: blobs
    )

    KeyboardShortcuts.onKeyDown(for: .togglePopup) { [weak self] in
        self?.popupController.toggle()
    }
    for n in 1...9 {
        KeyboardShortcuts.onKeyDown(for: .slot(n)) { [weak self] in
            self?.popupController.pasteDirect(slot: n)
        }
    }
}
```

Call `setUpPopup()` from `applicationDidFinishLaunching` after `setUpMonitor()`. Replace the placeholder `openPopup()`:

```swift
@objc private func openPopup() { popupController.toggle() }
```

- [ ] **Step 6: Manual smoke test**

1. Run the app.
2. Copy a few different strings (`one`, `two`, `three`) in Safari.
3. Hit ⌘⇧V (the default).

Expected: panel appears at screen center, lists the items, the search field accepts typing. Typing `t` filters. Pressing nothing yet pastes (that's in Task 12).

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: NSPanel popup + global hotkey + slot direct-paste"
```

---

## Task 12: Popup keyboard handling (↑ ↓ ↵ ⌫ ⌘P ⎋)

**Files:**
- Modify: `myclip/Popup/PopupView.swift`
- Modify: `myclip/Popup/PopupViewModel.swift`
- Modify: `myclip/Popup/PopupPanelController.swift`

- [ ] **Step 1: Add `KeyHandlerView`**

Append to `PopupView.swift`:

```swift
import SwiftUI
import AppKit

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
```

- [ ] **Step 2: Update `PopupView` to handle keys**

Replace `PopupView.body`:

```swift
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
                // ⌘P → pin toggle
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
```

And update the signature of `PopupView`:

```swift
struct PopupView: View {
    @ObservedObject var vm: PopupViewModel
    var onPick: (Item) -> Void
    var onClose: () -> Void
    var onDelete: (Item) -> Void
    var onTogglePin: (Item) -> Void
    // ...
}
```

- [ ] **Step 3: Create `PopupRow.swift`**

```swift
import SwiftUI

struct PopupRow: View {
    let item: Item
    let selected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .frame(width: 22, height: 22)
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13)).lineLimit(1)
                Text(subtitle).font(.system(size: 11)).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            if item.pinned {
                Image(systemName: "pin.fill").font(.system(size: 11)).foregroundColor(.orange)
            }
        }
        .padding(.vertical, 6).padding(.horizontal, 8)
        .background(selected ? Color.accentColor.opacity(0.18) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var iconName: String {
        switch item.type {
        case "text": return "doc.text"
        case "image": return "photo"
        case "file": return "folder"
        default: return "doc"
        }
    }
    private var title: String {
        switch item.type {
        case "image": return "Image"
        case "file": return (item.text as NSString?)?.lastPathComponent ?? ""
        default: return (item.text ?? "").replacingOccurrences(of: "\n", with: " ")
        }
    }
    private var subtitle: String {
        let d = Date(timeIntervalSince1970: Double(item.createdAt) / 1000)
        return RelativeDateTimeFormatter().localizedString(for: d, relativeTo: Date())
    }
}
```

- [ ] **Step 4: Wire delete/pin callbacks in `PopupPanelController.show`**

Replace the `let view = PopupView(...)` block:

```swift
let view = PopupView(
    vm: viewModel,
    onPick: { [weak self] item in self?.pick(item) },
    onClose: { [weak self] in self?.close() },
    onDelete: { [weak self] item in self?.delete(item) },
    onTogglePin: { [weak self] item in self?.togglePin(item) }
)
```

Add to `PopupPanelController`:

```swift
private let store: HistoryStore  // pass in via init

func delete(_ item: Item) {
    try? store.delete(id: item.id)
    viewModel.reload()
}
func togglePin(_ item: Item) {
    try? store.togglePin(id: item.id)
    viewModel.reload()
}
```

And update its `init` to accept `store: HistoryStore`. Update the call site in `AppDelegate.setUpPopup`.

- [ ] **Step 5: Manual smoke test**

1. Run app, ⌘⇧V to open.
2. ↓ ↑ moves selection (visible highlight).
3. ↵ pastes into the previous app.
4. ⌫ deletes the selected item from history.
5. ⌘P toggles pin (pin glyph appears).
6. ⎋ closes the panel.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: popup keyboard nav, delete, pin, paste-on-enter"
```

---

## Task 13: Apply Claude Desktop visual style

**Files:**
- Create: `myclip/DesignSystem/Colors.swift`
- Create: `myclip/DesignSystem/Theme.swift`
- Modify: `myclip/Popup/PopupView.swift`
- Modify: `myclip/Popup/PopupRow.swift`
- Modify: `myclip/Popup/PopupPanelController.swift`

- [ ] **Step 1: Add design system constants**

```swift
// Colors.swift
import SwiftUI

enum AppColors {
    static let accent = Color(red: 0xD9/255.0, green: 0x77/255.0, blue: 0x57/255.0) // Claude coral
    static let separator = Color(NSColor.separatorColor)
    static let primaryLabel = Color(NSColor.labelColor)
    static let secondaryLabel = Color(NSColor.secondaryLabelColor)
    static let tertiaryLabel = Color(NSColor.tertiaryLabelColor)
}
```

```swift
// Theme.swift
import CoreGraphics
enum Theme {
    static let panelRadius: CGFloat = 14
    static let rowRadius: CGFloat = 8
    static let panelWidth: CGFloat = 440
    static let panelHeight: CGFloat = 480
}
```

- [ ] **Step 2: Add `VisualEffectView` wrapper**

Append to `PopupView.swift`:

```swift
import AppKit
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
```

- [ ] **Step 3: Restyle `PopupView`**

Wrap the existing `VStack` content in:

```swift
ZStack {
    VisualEffectView(material: .hudWindow, blending: .behindWindow)
        .clipShape(RoundedRectangle(cornerRadius: Theme.panelRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.panelRadius)
                .stroke(AppColors.separator, lineWidth: 1)
        )

    // existing KeyHandlerView + VStack
}
.frame(width: Theme.panelWidth, height: Theme.panelHeight)
.accentColor(AppColors.accent)
```

- [ ] **Step 4: Restyle the search field**

Replace the `TextField(...)`:

```swift
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
```

- [ ] **Step 5: Add slot badge to `PopupRow`**

Extend `PopupRow` with an optional `slotIndex: Int?` property. The first 9 non-pinned items will get `1..9`. In `PopupView`, compute the slot index list:

```swift
let nonPinnedSlots: [String: Int] = {
    var map: [String: Int] = [:]
    var n = 1
    for item in vm.items where !item.pinned && n <= 9 {
        map[item.id] = n; n += 1
    }
    return map
}()
```

Pass it down: `PopupRow(item: item, selected: ..., slot: nonPinnedSlots[item.id])`.

In `PopupRow` add to the row HStack after the pin glyph block:

```swift
if let slot = slot {
    Text("\(slot)")
        .font(.system(size: 10, weight: .semibold))
        .foregroundColor(AppColors.accent)
        .frame(width: 18, height: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(AppColors.accent.opacity(0.5), lineWidth: 1)
        )
}
```

- [ ] **Step 6: Set panel transparency in `PopupPanelController`**

In `show()`, after `panel.contentView = hosting`, add:

```swift
panel.isOpaque = false
panel.backgroundColor = .clear
panel.contentView?.wantsLayer = true
panel.contentView?.layer?.cornerRadius = Theme.panelRadius
panel.contentView?.layer?.masksToBounds = true
```

- [ ] **Step 7: Smoke test**

Run app, ⌘⇧V. Expected: rounded, semi-translucent panel, coral accent on selection, slot badges `1`–`9` on the most-recent 9 non-pinned items. Dark mode renders correctly (toggle System Settings → Appearance).

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: Claude-style visuals — material, accent, search field, slot badges"
```

---

## Task 14: Accessibility permission gating

**Files:**
- Create: `myclip/Permissions/Accessibility.swift`
- Modify: `myclip/App/AppDelegate.swift`
- Modify: `myclip/Paste/PasteEngine.swift`

- [ ] **Step 1: Add helper**

```swift
import AppKit

enum Accessibility {
    static func isTrusted(prompt: Bool = false) -> Bool {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
```

- [ ] **Step 2: Make `PasteEngine` aware of permission**

Add to `PasteEngine`:

```swift
public var hasAccessibility: Bool { Accessibility.isTrusted() }
```

In `pasteIntoPreviousApp`:

```swift
public func pasteIntoPreviousApp(bundleID: String?) {
    if let id = bundleID,
       let app = NSRunningApplication.runningApplications(withBundleIdentifier: id).first {
        app.activate(options: [.activateIgnoringOtherApps])
    }
    guard hasAccessibility else {
        NotificationCenter.default.post(name: .myclipNeedsAccessibility, object: nil)
        return
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.sendCommandV() }
}

extension Notification.Name {
    static let myclipNeedsAccessibility = Notification.Name("myclipNeedsAccessibility")
}
```

- [ ] **Step 3: AppDelegate prompts once**

Add to `applicationDidFinishLaunching`:

```swift
if !Accessibility.isTrusted(prompt: true) {
    NSLog("Accessibility permission not granted; auto-paste disabled until granted.")
}
NotificationCenter.default.addObserver(
    forName: .myclipNeedsAccessibility, object: nil, queue: .main
) { _ in
    let alert = NSAlert()
    alert.messageText = "Enable Accessibility for auto-paste"
    alert.informativeText = "myclip needs Accessibility access to type ⌘V into the previous app. The clipboard already holds your selection — you can ⌘V manually too."
    alert.addButton(withTitle: "Open System Settings")
    alert.addButton(withTitle: "Later")
    if alert.runModal() == .alertFirstButtonReturn {
        Accessibility.openSystemSettings()
    }
}
```

- [ ] **Step 4: Manual test**

Run from Xcode without granting permission. On first paste, the alert appears. Grant permission, restart, paste should auto-fire.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: graceful Accessibility permission prompt and fallback"
```

---

## Task 15: Settings window

**Files:**
- Create: `myclip/Settings/SettingsWindow.swift`
- Create: `myclip/Settings/SettingsView.swift`
- Modify: `myclip/App/AppDelegate.swift`

- [ ] **Step 1: `SettingsView`**

```swift
import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @AppStorage("historyCap") private var historyCap: Int = 200
    @AppStorage("blacklist") private var blacklistJoined: String =
        "com.1password.1password,com.agilebits.onepassword7,com.bitwarden.desktop,com.apple.keychainaccess"

    var body: some View {
        TabView {
            Form {
                Stepper("History cap: \(historyCap)", value: $historyCap, in: 50...500, step: 25)
            }
            .padding(20).tabItem { Label("General", systemImage: "gear") }

            Form {
                KeyboardShortcuts.Recorder("Open popup:", name: .togglePopup)
                ForEach(1..<10) { n in
                    KeyboardShortcuts.Recorder("Paste slot \(n):", name: .slot(n))
                }
            }
            .padding(20).tabItem { Label("Shortcuts", systemImage: "keyboard") }

            Form {
                Text("Apps whose clipboards are never recorded (comma-separated bundle IDs):")
                    .font(.callout).foregroundColor(.secondary)
                TextEditor(text: $blacklistJoined).frame(height: 120).font(.system(.body, design: .monospaced))
            }
            .padding(20).tabItem { Label("Privacy", systemImage: "hand.raised") }

            Form {
                Button("Open data folder") {
                    NSWorkspace.shared.open(AppPaths.supportDirectory)
                }
                Button("Clear all history", role: .destructive) {
                    let alert = NSAlert()
                    alert.messageText = "Clear all clipboard history?"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Clear")
                    alert.addButton(withTitle: "Cancel")
                    if alert.runModal() == .alertFirstButtonReturn {
                        NotificationCenter.default.post(name: .myclipClearAll, object: nil)
                    }
                }
            }
            .padding(20).tabItem { Label("Storage", systemImage: "internaldrive") }
        }
        .frame(width: 540, height: 420)
    }
}

extension Notification.Name {
    static let myclipClearAll = Notification.Name("myclipClearAll")
}
```

- [ ] **Step 2: `SettingsWindow`**

```swift
import AppKit
import SwiftUI

final class SettingsWindowController {
    private var window: NSWindow?

    func show() {
        if let w = window { w.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }
        let host = NSHostingController(rootView: SettingsView())
        let w = NSWindow(contentViewController: host)
        w.title = "myclip Settings"
        w.styleMask = [.titled, .closable, .miniaturizable]
        w.setContentSize(NSSize(width: 540, height: 420))
        w.center()
        w.isReleasedWhenClosed = false
        self.window = w
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
```

- [ ] **Step 3: Wire into `AppDelegate`**

```swift
private let settings = SettingsWindowController()

@objc private func openSettings() { settings.show() }
```

Also make `historyCap` and blacklist live values — replace the hardcoded prune cap and blacklist with reads from `UserDefaults`:

```swift
private var historyCap: Int {
    let v = UserDefaults.standard.integer(forKey: "historyCap")
    return v == 0 ? 200 : v
}
private var blacklistFromDefaults: Set<String> {
    let raw = UserDefaults.standard.string(forKey: "blacklist") ?? ""
    return Set(raw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
}
```

In `setUpMonitor`, replace `self?.blacklist ?? []` with `self?.blacklistFromDefaults ?? []` and replace `try self.store.prune(cap: 200)` with `try self.store.prune(cap: self.historyCap)`.

In `applicationDidFinishLaunching`, observe the clear-all notification:

```swift
NotificationCenter.default.addObserver(forName: .myclipClearAll, object: nil, queue: .main) { [weak self] _ in
    try? self?.store.clearAll()
}
```

And add to `HistoryStore`:

```swift
public func clearAll() throws {
    try queue.write { db in
        let imageRows = try Item.filter(Item.Columns.type == "image").fetchAll(db)
        for row in imageRows {
            if let path = row.blobPath { try? blobStore?.remove(relativePath: path) }
        }
        try Item.deleteAll(db)
    }
    try reloadSnapshot()
}
```

- [ ] **Step 4: Manual smoke test**

1. Run app, menu bar → Settings…
2. Change hotkey to ⌘⇧X via recorder; verify it now opens the popup.
3. Change history cap to 50, copy many items; oldest get pruned.
4. Add a bundle ID to privacy list (e.g., `com.apple.Terminal`); copies from that app are ignored.
5. Click "Clear all history"; popup is empty after.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: Settings window with general/shortcuts/privacy/storage tabs"
```

---

## Task 16: QA checklist + README

**Files:**
- Create: `docs/qa/checklist.md`
- Create: `README.md` (overwrite generated one if any)

- [ ] **Step 1: Write QA checklist**

```markdown
# myclip Manual QA Checklist

Run before any release tag.

- [ ] Cold launch: no Dock icon; menu bar glyph present.
- [ ] Accessibility prompt appears on first paste attempt if not granted.
- [ ] Copy text in Safari → popup (⌘⇧V) shows it at top.
- [ ] Pressing ↵ pastes into the previously focused app.
- [ ] ⌫ removes the selected item.
- [ ] ⌘P toggles pin; pinned items survive prune.
- [ ] ⌘⇧⌃4 screenshot appears as an image item with thumbnail.
- [ ] ⌘C a Finder file → file row; pasting into another Finder window creates a copy.
- [ ] Copy in 1Password → not recorded.
- [ ] ⌘⌥⌃3 from any app pastes the 3rd most-recent without opening popup.
- [ ] Settings → change history cap → prune kicks in immediately on next copy.
- [ ] Restart app → history + pins persist.
- [ ] Toggle System Appearance dark↔light → popup re-renders correctly.
```

- [ ] **Step 2: Write README**

```markdown
# myclip

A personal macOS clipboard history app. Menu bar only. Text, images (incl. screenshots), and file references.

## Build

Open `myclip.xcodeproj` in Xcode 15+ and run. macOS 13+ required.

## Permissions

- **Accessibility** — needed for auto-paste (⌘V into the previous app). Without it, the selected item is placed on the clipboard but you must paste manually.

## Hotkeys (defaults)

- Open popup: ⌘⇧V
- Paste Nth most recent: assign in Settings → Shortcuts

## Data

Stored at `~/Library/Application Support/myclip/`. No network calls.
```

- [ ] **Step 3: Run full QA checklist**

Work through each item. Fix any failures inline; document the fix in a follow-up commit.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "docs: QA checklist and README"
```

---

## Self-Review Notes

Coverage map (spec → tasks):

- Tech stack & min macOS → Task 1
- Menu bar shell, `LSUIElement` → Tasks 1–2
- Storage (GRDB, schema, blob dir) → Tasks 4, 6
- FTS5 search → Task 7
- ClipboardMonitor classifier + privacy drops → Task 8
- PasteEngine + Accessibility fallback → Tasks 10, 14
- NSPanel.nonactivatingPanel popup → Task 11
- Popup keyboard nav + pin + delete → Task 12
- Claude visual style, slot badges, dark mode → Task 13
- Hotkeys (popup + slots 1–9) + recorder UI → Tasks 11, 15
- Settings window (General/Shortcuts/Privacy/Storage) → Task 15
- QA + docs → Task 16

Types/methods are consistent (`HistoryStore.topN`, `topNNonPinned`, `topNRespectingPins`, `search`, `delete`, `togglePin`, `prune`, `clearAll` all defined where first used). No placeholders, every TDD step has runnable code.
