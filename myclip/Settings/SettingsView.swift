import SwiftUI
import AppKit
import KeyboardShortcuts

struct SettingsView: View {
    @AppStorage("historyCap") private var historyCap: Int = 9
    @AppStorage("blacklist") private var blacklistJoined: String =
        "com.1password.1password,com.agilebits.onepassword7,com.bitwarden.desktop,com.apple.keychainaccess"
    @AppStorage(AppPaths.storageDirectoryDefaultsKey) private var customStorageDirectory: String = ""

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }
            shortcutsTab
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
            privacyTab
                .tabItem { Label("Privacy", systemImage: "hand.raised") }
            storageTab
                .tabItem { Label("Storage", systemImage: "internaldrive") }
        }
        .frame(width: 560, height: 460)
        .background(WindowAccessor { window in
            window.title = "MyClip Settings"
        })
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            LabeledContent("History cap") {
                HStack(spacing: 8) {
                    Stepper(value: $historyCap, in: 1...20, step: 1) {
                        Text("\(historyCap) items")
                            .frame(minWidth: 70, alignment: .leading)
                            .monospacedDigit()
                    }
                }
            }
            Text("When the number of non-pinned items exceeds this cap, the oldest entries are deleted automatically. Pinned items are never auto-deleted.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
    }

    // MARK: - Shortcuts

    private var shortcutsTab: some View {
        Form {
            Section("Popup") {
                KeyboardShortcuts.Recorder("Open popup:", name: .togglePopup)
            }
            Section("Direct paste — nth most-recent non-pinned") {
                ForEach(1..<10) { n in
                    KeyboardShortcuts.Recorder("Slot \(n):", name: .slot(n))
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Privacy

    private var privacyTab: some View {
        Form {
            Section("Blacklisted apps") {
                Text("Clipboard from these bundle identifiers is never recorded. Comma-separated.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                TextEditor(text: $blacklistJoined)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 110, maxHeight: 160)
                    .border(Color.secondary.opacity(0.25), width: 1)
            }
            Section {
                Label("Concealed clipboards (passwords, etc.) are always ignored regardless of this list.",
                      systemImage: "info.circle")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Storage

    private var storageTab: some View {
        Form {
            Section("Location") {
                Text(AppPaths.supportDirectory.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 10) {
                    Button("Change…", action: changeStorageFolder)
                    Button("Reset to default", action: resetStorageFolder)
                        .disabled(customStorageDirectory.isEmpty)
                    Spacer()
                    Button {
                        NSWorkspace.shared.open(AppPaths.supportDirectory)
                    } label: {
                        Label("Open in Finder", systemImage: "folder")
                    }
                }
            }
            Section("History") {
                HStack(spacing: 10) {
                    Button {
                        NotificationCenter.default.post(name: .myclipExportHistory, object: nil)
                    } label: {
                        Label("Export to text…", systemImage: "square.and.arrow.up")
                    }
                    Spacer()
                    Button(role: .destructive, action: confirmClearAll) {
                        Label("Clear all history", systemImage: "trash")
                    }
                }
                Text("Clearing wipes both database rows and image files, including pinned items.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
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
}

/// Tiny shim so we can poke the underlying NSWindow once SwiftUI mounts the view
/// (e.g. to set its title — SwiftUI's Settings scene uses "MyclipApp" by default).
private struct WindowAccessor: NSViewRepresentable {
    let configure: (NSWindow) -> Void
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            if let window = v.window { configure(window) }
        }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window { configure(window) }
    }
}

extension Notification.Name {
    static let myclipClearAll = Notification.Name("myclipClearAll")
    static let myclipExportHistory = Notification.Name("myclipExportHistory")
    static let myclipOpenSettings = Notification.Name("myclipOpenSettings")
}
