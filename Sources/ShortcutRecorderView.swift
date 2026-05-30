import SwiftUI
import AppKit

// MARK: - Shortcut recorder
// Click to start recording, then press a key combo (with at least one of
// ⌘/⌥/⌃). Esc cancels. The chosen shortcut is saved to AppSettings.

struct ShortcutRecorderView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        Button {
            recording ? stop() : start()
        } label: {
            Text(recording ? "Press keys…" : settings.hotkeyDisplay)
                .frame(minWidth: 64)
        }
        .onDisappear(perform: stop)
    }

    private func start() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Esc cancels.
            if event.keyCode == 53 {
                stop()
                return nil
            }
            let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
            // Require a "real" modifier so we don't capture a bare key.
            guard mods.contains(.command) || mods.contains(.option) || mods.contains(.control) else {
                return nil // keep waiting
            }
            settings.setHotkey(
                keyCode: Int(event.keyCode),
                modifiers: mods,
                display: Self.display(mods, event)
            )
            stop()
            return nil // swallow the event so it doesn't type anywhere
        }
    }

    private func stop() {
        recording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    static func display(_ mods: NSEvent.ModifierFlags, _ event: NSEvent) -> String {
        var s = ""
        if mods.contains(.control) { s += "⌃" }
        if mods.contains(.option)  { s += "⌥" }
        if mods.contains(.shift)   { s += "⇧" }
        if mods.contains(.command) { s += "⌘" }
        let key = (event.charactersIgnoringModifiers ?? "").uppercased()
        return s + (key.isEmpty ? "•" : key)
    }
}
