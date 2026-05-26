import SwiftUI

@main
struct PizzaClipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Wiring the SwiftUI `Settings` scene with our actual SettingsView gives
        // us a real Settings window for free + makes the system's ⌘, accelerator
        // open the right thing (was previously opening an empty EmptyView).
        Settings { SettingsView() }
    }
}
