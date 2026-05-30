import AppKit
import Carbon.HIToolbox

// MARK: - Global hotkey (Carbon RegisterEventHotKey)
// Registers a true system-wide hotkey. Reliable and — unlike NSEvent global
// monitors — needs NO Accessibility permission.

final class HotkeyManager {
    static let shared = HotkeyManager()

    var onTrigger: () -> Void = {}

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let signature: OSType = 0x4E4D4554 // 'NMET'

    private init() {}

    /// (Re)register the global hotkey for the given key + modifiers.
    func update(keyCode: Int, modifiers: NSEvent.ModifierFlags) {
        installHandlerIfNeeded()

        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }

        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            Self.carbonModifiers(modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr { hotKeyRef = ref }
    }

    private func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, _ in
                HotkeyManager.shared.onTrigger()
                return noErr
            },
            1, &spec, nil, &handlerRef
        )
    }

    private static func carbonModifiers(_ m: NSEvent.ModifierFlags) -> UInt32 {
        var f: UInt32 = 0
        if m.contains(.command) { f |= UInt32(cmdKey) }
        if m.contains(.option)  { f |= UInt32(optionKey) }
        if m.contains(.control) { f |= UInt32(controlKey) }
        if m.contains(.shift)   { f |= UInt32(shiftKey) }
        return f
    }
}
