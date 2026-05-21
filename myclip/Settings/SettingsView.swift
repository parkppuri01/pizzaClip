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
                TextEditor(text: $blacklistJoined)
                    .frame(height: 120)
                    .font(.system(.body, design: .monospaced))
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
