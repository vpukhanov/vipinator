import Foundation
import Carbon.HIToolbox

extension Notification.Name {
    static let vpnHotkeyPressed = Notification.Name("VPNHotkeyPressed")
}

@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()

    private let keyCodeKey = "VPNHotkeyKeyCode"
    private let modifiersKey = "VPNHotkeyModifiers"

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    private init() {
        registerCurrentOrDefault()
    }

    func registerCurrentOrDefault() {
        if currentShortcut() == nil {
            saveAndRegister(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(cmdKey | shiftKey))
        } else {
            registerCurrentFromDefaults()
        }
    }

    func currentShortcut() -> (UInt32, UInt32)? {
        guard let keyValue = UserDefaults.standard.object(forKey: keyCodeKey) as? NSNumber,
              let modifiersValue = UserDefaults.standard.object(forKey: modifiersKey) as? NSNumber else {
            return nil
        }
        return (keyValue.uint32Value, modifiersValue.uint32Value)
    }

    func currentDisplayString() -> String {
        Self.displayString(for: currentShortcut())
    }

    func saveAndRegister(keyCode: UInt32?, modifiers: UInt32?) {
        unregister()

        guard let keyCode, let modifiers else {
            UserDefaults.standard.removeObject(forKey: keyCodeKey)
            UserDefaults.standard.removeObject(forKey: modifiersKey)
            return
        }

        UserDefaults.standard.set(NSNumber(value: keyCode), forKey: keyCodeKey)
        UserDefaults.standard.set(NSNumber(value: modifiers), forKey: modifiersKey)

        register(keyCode: keyCode, modifiers: modifiers)
    }

    func registerCurrentFromDefaults() {
        guard let (code, modifiers) = currentShortcut() else { return }
        register(keyCode: code, modifiers: modifiers)
    }

    private func register(keyCode: UInt32, modifiers: UInt32) {
        unregister()

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: OSType(kEventHotKeyPressed))

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, userData) -> OSStatus in
                guard let pointer = userData else { return noErr }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(pointer).takeUnretainedValue()
                manager.handleHotkey()
                return noErr
            },
            1,
            &eventSpec,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )

        guard status == noErr else { return }

        let hotKeyID = EventHotKeyID(signature: fourCC("VPNH"), id: 1)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    private func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }

    private func handleHotkey() {
        NotificationCenter.default.post(name: .vpnHotkeyPressed, object: nil)
    }

    static func displayString(for shortcut: (UInt32, UInt32)?) -> String {
        guard let shortcut else { return "Record" }
        return displayString(keyCode: shortcut.0, modifiers: shortcut.1)
    }

    static func displayString(keyCode: UInt32, modifiers: UInt32) -> String {
        var symbols: [String] = []
        if modifiers & UInt32(cmdKey) != 0 { symbols.append("⌘") }
        if modifiers & UInt32(shiftKey) != 0 { symbols.append("⇧") }
        if modifiers & UInt32(optionKey) != 0 { symbols.append("⌥") }
        if modifiers & UInt32(controlKey) != 0 { symbols.append("⌃") }

        symbols.append(keyNames[keyCode] ?? "#\(keyCode)")
        return symbols.joined(separator: " ")
    }

    private static let keyNames: [UInt32: String] = [
        UInt32(kVK_ANSI_A): "A",
        UInt32(kVK_ANSI_B): "B",
        UInt32(kVK_ANSI_C): "C",
        UInt32(kVK_ANSI_D): "D",
        UInt32(kVK_ANSI_E): "E",
        UInt32(kVK_ANSI_F): "F",
        UInt32(kVK_ANSI_G): "G",
        UInt32(kVK_ANSI_H): "H",
        UInt32(kVK_ANSI_I): "I",
        UInt32(kVK_ANSI_J): "J",
        UInt32(kVK_ANSI_K): "K",
        UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M",
        UInt32(kVK_ANSI_N): "N",
        UInt32(kVK_ANSI_O): "O",
        UInt32(kVK_ANSI_P): "P",
        UInt32(kVK_ANSI_Q): "Q",
        UInt32(kVK_ANSI_R): "R",
        UInt32(kVK_ANSI_S): "S",
        UInt32(kVK_ANSI_T): "T",
        UInt32(kVK_ANSI_U): "U",
        UInt32(kVK_ANSI_V): "V",
        UInt32(kVK_ANSI_W): "W",
        UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y",
        UInt32(kVK_ANSI_Z): "Z",
        UInt32(kVK_ANSI_0): "0",
        UInt32(kVK_ANSI_1): "1",
        UInt32(kVK_ANSI_2): "2",
        UInt32(kVK_ANSI_3): "3",
        UInt32(kVK_ANSI_4): "4",
        UInt32(kVK_ANSI_5): "5",
        UInt32(kVK_ANSI_6): "6",
        UInt32(kVK_ANSI_7): "7",
        UInt32(kVK_ANSI_8): "8",
        UInt32(kVK_ANSI_9): "9"
    ]
}

private func fourCC(_ string: String) -> OSType {
    var result: OSType = 0
    for scalar in string.utf16 {
        result = (result << 8) | OSType(scalar)
    }
    return result
}
