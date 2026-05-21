import SwiftUI
import AppKit
import KeyboardShortcuts

struct SettingsView: View {
    @AppStorage("historyCap") private var historyCap: Int = 200
    @AppStorage("blacklist") private var blacklistJoined: String =
        "com.1password.1password,com.agilebits.onepassword7,com.bitwarden.desktop,com.apple.keychainaccess"
    @AppStorage(AppPaths.storageDirectoryDefaultsKey) private var customStorageDirectory: String = ""

    var body: some View {
        TabView {
            generalTab
                .padding(20).tabItem { Label("General", systemImage: "gear") }

            shortcutsTab
                .padding(20).tabItem { Label("Shortcuts", systemImage: "keyboard") }

            privacyTab
                .padding(20).tabItem { Label("Privacy", systemImage: "hand.raised") }

            storageTab
                .padding(20).tabItem { Label("Storage", systemImage: "internaldrive") }
        }
        .frame(width: 560, height: 460)
    }

    // MARK: - Tabs

    private var generalTab: some View {
        Form {
            Stepper("History cap: \(historyCap)", value: $historyCap, in: 20...500, step: 10)
            Text("When the number of non-pinned items exceeds this cap, the oldest entries are deleted automatically. Pinned items are never auto-deleted.")
                .font(.callout).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var shortcutsTab: some View {
        Form {
            KeyboardShortcuts.Recorder("Open popup:", name: .togglePopup)
            ForEach(1..<10) { n in
                KeyboardShortcuts.Recorder("Paste slot \(n):", name: .slot(n))
            }
        }
    }

    private var privacyTab: some View {
        Form {
            Text("Apps whose clipboards are never recorded (comma-separated bundle IDs):")
                .font(.callout).foregroundColor(.secondary)
            TextEditor(text: $blacklistJoined)
                .frame(height: 120)
                .font(.system(.body, design: .monospaced))
        }
    }

    private var storageTab: some View {
        Form {
            Section {
                LabeledContent("Location") {
                    Text(AppPaths.supportDirectory.path)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
                HStack {
                    Button("Change…", action: changeStorageFolder)
                    Button("Reset to default", action: resetStorageFolder)
                        .disabled(customStorageDirectory.isEmpty)
                    Spacer()
                    Button("Open in Finder") {
                        NSWorkspace.shared.open(AppPaths.supportDirectory)
                    }
                }
            }
            Divider().padding(.vertical, 8)
            Section {
                Button("Export history to text…", action: exportHistory)
                Button("Clear all history", role: .destructive, action: confirmClearAll)
            }
        }
    }

    // MARK: - Actions

    private func changeStorageFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Pick a folder where myclip will store db.sqlite and blobs/."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        customStorageDirectory = url.path
        showRestartAlert(message: "Storage location set to \(url.path).")
    }

    private func resetStorageFolder() {
        customStorageDirectory = ""
        showRestartAlert(message: "Storage location reset to the default.")
    }

    private func showRestartAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Restart required"
        alert.informativeText = """
            \(message)

            Quit and relaunch myclip for the change to take effect. Existing data is not moved automatically — copy db.sqlite and blobs/ manually if you want to keep your history.
            """
        alert.runModal()
    }

    private func confirmClearAll() {
        let alert = NSAlert()
        alert.messageText = "Clear all clipboard history?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            NotificationCenter.default.post(name: .myclipClearAll, object: nil)
        }
    }

    private func exportHistory() {
        NotificationCenter.default.post(name: .myclipExportHistory, object: nil)
    }
}

extension Notification.Name {
    static let myclipClearAll = Notification.Name("myclipClearAll")
    static let myclipExportHistory = Notification.Name("myclipExportHistory")
    static let myclipOpenSettings = Notification.Name("myclipOpenSettings")
}
