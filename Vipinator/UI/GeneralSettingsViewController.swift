//
//  GeneralSettingsViewController.swift
//  Vipinator
//

import AppKit
import ServiceManagement
import Carbon.HIToolbox

final class GeneralSettingsViewController: NSViewController {
    private let container = NSVisualEffectView()
    private let content = NSView()

    private let titleLabel = NSTextField(labelWithString: "Start at login")
    private let switchControl = NSSwitch()
    private let footnote = NSTextField(labelWithString: "The app automatically starts when you sign in.")
    private let separator = NSBox()

    private let hkContainer = NSVisualEffectView()
    private let hkContent = NSView()
    private let hkTitle = NSTextField(labelWithString: "Hotkey for quick VPN on/off")
    private let hkField = HotkeyRecordField()
    private let hkSeparator = NSBox()
    private let hkNote = NSTextField(labelWithString: "Use the hotkey to switch the VPN. It works on the one you last connected to.")

    override func loadView() { view = NSView() }

    override func viewDidLoad() {
        super.viewDidLoad()

        container.material = .contentBackground
        container.blendingMode = .behindWindow
        container.state = .active
        container.translatesAutoresizingMaskIntoConstraints = false
        container.wantsLayer = true
        container.layer?.cornerRadius = 12
        container.layer?.masksToBounds = true

        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),

            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            content.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.alignment = .left
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        switchControl.target = self
        switchControl.action = #selector(toggleOpenAtLogin)

        if #available(macOS 13.0, *) {
            switchControl.state = isOpenAtLoginEnabled ? .on : .off
        } else {
            switchControl.state = .off
            switchControl.isEnabled = false
            footnote.stringValue = "Requires macOS 13 or later."
        }

        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false

        footnote.alignment = .left
        footnote.textColor = .secondaryLabelColor
        footnote.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        footnote.translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, switchControl, separator, footnote].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: content.topAnchor),
            switchControl.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            switchControl.trailingAnchor.constraint(equalTo: content.trailingAnchor),

            separator.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            separator.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: content.trailingAnchor),

            footnote.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 8),
            footnote.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            footnote.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor),
            footnote.bottomAnchor.constraint(equalTo: content.bottomAnchor)
        ])

        hkContainer.material = .contentBackground
        hkContainer.blendingMode = .behindWindow
        hkContainer.state = .active
        hkContainer.translatesAutoresizingMaskIntoConstraints = false
        hkContainer.wantsLayer = true
        hkContainer.layer?.cornerRadius = 12
        hkContainer.layer?.masksToBounds = true

        hkContent.translatesAutoresizingMaskIntoConstraints = false
        hkContainer.addSubview(hkContent)
        view.addSubview(hkContainer)

        NSLayoutConstraint.activate([
            hkContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            hkContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            hkContainer.topAnchor.constraint(equalTo: container.bottomAnchor, constant: 12),

            hkContent.leadingAnchor.constraint(equalTo: hkContainer.leadingAnchor, constant: 16),
            hkContent.trailingAnchor.constraint(equalTo: hkContainer.trailingAnchor, constant: -16),
            hkContent.topAnchor.constraint(equalTo: hkContainer.topAnchor, constant: 14),
            hkContent.bottomAnchor.constraint(equalTo: hkContainer.bottomAnchor, constant: -14)
        ])

        hkTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        hkTitle.alignment = .left

        hkField.translatesAutoresizingMaskIntoConstraints = false
        hkField.onChange = { keyCode, modifiers in
            HotkeyManager.shared.saveAndRegister(keyCode: keyCode, modifiers: modifiers)
        }
        hkField.syncFromManager()

        hkSeparator.boxType = .separator
        hkSeparator.translatesAutoresizingMaskIntoConstraints = false

        hkNote.alignment = .left
        hkNote.textColor = .secondaryLabelColor
        hkNote.font = .systemFont(ofSize: NSFont.smallSystemFontSize)

        [hkTitle, hkField, hkSeparator, hkNote].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            hkContent.addSubview($0)
        }

        NSLayoutConstraint.activate([
            hkTitle.leadingAnchor.constraint(equalTo: hkContent.leadingAnchor),
            hkTitle.topAnchor.constraint(equalTo: hkContent.topAnchor),

            hkField.centerYAnchor.constraint(equalTo: hkTitle.centerYAnchor),
            hkField.trailingAnchor.constraint(equalTo: hkContent.trailingAnchor),
            hkField.widthAnchor.constraint(equalTo: hkContent.widthAnchor, multiplier: 0.30),

            hkSeparator.topAnchor.constraint(equalTo: hkTitle.bottomAnchor, constant: 12),
            hkSeparator.leadingAnchor.constraint(equalTo: hkContent.leadingAnchor),
            hkSeparator.trailingAnchor.constraint(equalTo: hkContent.trailingAnchor),

            hkNote.topAnchor.constraint(equalTo: hkSeparator.bottomAnchor, constant: 8),
            hkNote.leadingAnchor.constraint(equalTo: hkContent.leadingAnchor),
            hkNote.trailingAnchor.constraint(lessThanOrEqualTo: hkContent.trailingAnchor),
            hkNote.bottomAnchor.constraint(equalTo: hkContent.bottomAnchor)
        ])

        HotkeyManager.shared.ensureDefaultRegistered()
    }

    private var isOpenAtLoginEnabled: Bool {
        if #available(macOS 13.0, *) { SMAppService.mainApp.status == .enabled } else { false }
    }

    @objc private func toggleOpenAtLogin(_ sender: NSSwitch) {
        guard #available(macOS 13.0, *) else { return }
        do {
            if sender.state == .on { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            NSSound.beep()
            sender.state = isOpenAtLoginEnabled ? .on : .off
            NSLog("OpenAtLogin toggle error: \(error.localizedDescription)")
        }
    }

}

extension Notification.Name {
    static let vpnHotkeyPressed = Notification.Name("VPNHotkeyPressed")
}

final class HotkeyManager {
    static let shared = HotkeyManager()

    private let keyCodeKey = "VPNHotkeyKeyCode"
    private let modifiersKey = "VPNHotkeyModifiers"

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    private init() { ensureDefaultRegistered() }

    func ensureDefaultRegistered() {
        if UserDefaults.standard.object(forKey: keyCodeKey) == nil ||
           UserDefaults.standard.object(forKey: modifiersKey) == nil {
            saveAndRegister(keyCode: UInt32(kVK_ANSI_V), modifiers: (UInt32(cmdKey) | UInt32(shiftKey)))
        } else {
            registerCurrentFromDefaults()
        }
    }

    func currentDisplayString() -> String {
        guard let (code, mods) = current() else { return "Disabled" }
        return displayString(keyCode: code, modifiers: mods)
    }

    func current() -> (UInt32, UInt32)? {
        guard let code = (UserDefaults.standard.object(forKey: keyCodeKey) as? NSNumber)?.uint32Value,
              let mods = (UserDefaults.standard.object(forKey: modifiersKey) as? NSNumber)?.uint32Value else { return nil }
        return (code, mods)
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
        if let (code, mods) = current() {
            register(keyCode: code, modifiers: mods)
        }
    }

    private func register(keyCode: UInt32, modifiers: UInt32) {
        unregister()

        let hotKeyID = EventHotKeyID(signature: fourCC("VPNH"), id: 1)
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: OSType(kEventHotKeyPressed))

        let status = InstallEventHandler(GetApplicationEventTarget(), { (handlerRef, eventRef, userData) -> OSStatus in
            guard let userData else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.handleHotkey(event: eventRef)
            return noErr
        }, 1, &eventSpec, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &eventHandlerRef)

        if status == noErr {
            RegisterEventHotKey(UInt32(keyCode), modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        }
    }

    private func unregister() {
        if let hk = hotKeyRef {
            UnregisterEventHotKey(hk)
            hotKeyRef = nil
        }
        if let h = eventHandlerRef {
            RemoveEventHandler(h)
            eventHandlerRef = nil
        }
    }

    private func handleHotkey(event: EventRef?) {
        NotificationCenter.default.post(name: .vpnHotkeyPressed, object: nil)
    }

    func displayString(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        parts.append(keyName(for: keyCode))
        return parts.joined(separator: " ")
    }

    private func keyName(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        default: return "#\(keyCode)"
        }
    }
}

final class HotkeyRecordField: NSControl, NSGestureRecognizerDelegate {
    var onChange: (_ keyCode: UInt32?, _ modifiers: UInt32?) -> Void = { _,_  in }

    override var acceptsFirstResponder: Bool { true }

    private let bg = NSView()
    private let label = NSTextField(labelWithString: "")
    private var isRecording = false
    private let clearButton = NSButton()
    private var labelTrailingToClear: NSLayoutConstraint?
    private var labelTrailingToEdge: NSLayoutConstraint?
    private var outsideClickMonitor: Any?
    private var appAppearanceObserver: NSObjectProtocol?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    override var stringValue: String {
        get { label.stringValue }
        set { label.stringValue = newValue }
    }

    private func setup() {
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false

        bg.wantsLayer = true
        bg.layer = CALayer()
        bg.layer?.cornerRadius = 14
        bg.layer?.borderWidth = 1
        applyAdaptiveColors()
        bg.translatesAutoresizingMaskIntoConstraints = false

        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.alignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(bg)
        addSubview(label)

        clearButton.isBordered = false
        if #available(macOS 11.0, *) {
            clearButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Clear")
            clearButton.image?.isTemplate = true
            clearButton.contentTintColor = .tertiaryLabelColor
        } else {
            clearButton.title = "×"
            clearButton.font = .systemFont(ofSize: 14, weight: .regular)
        }
        clearButton.target = self
        clearButton.action = #selector(clearTapped)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(clearButton)
        applyAdaptiveColors()

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 28),

            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.topAnchor.constraint(equalTo: topAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor),

            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 16),
            clearButton.heightAnchor.constraint(equalToConstant: 16),

            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
        ])

        labelTrailingToClear = label.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -6)
        labelTrailingToEdge  = label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        labelTrailingToEdge?.isActive = true

        let click = NSClickGestureRecognizer(target: self, action: #selector(beginRecording))
        click.delegate = self
        addGestureRecognizer(click)
        // Observe system theme (auto light/dark) via distributed notification
        appAppearanceObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.applyAdaptiveColors()
            self.needsDisplay = true
            self.layoutSubtreeIfNeeded()
        }
    }

    private func applyAdaptiveColors() {
        // Manual adaptive colors so the capsule never stays white in dark mode
        let match = effectiveAppearance.bestMatch(from: [.darkAqua, .vibrantDark, .aqua, .vibrantLight])
        let isDark = (match == .darkAqua || match == .vibrantDark)

        // Neutral background + subtle border tuned per theme
        let bgColor: NSColor   = isDark ? NSColor.white.withAlphaComponent(0.06)
                                        : NSColor.black.withAlphaComponent(0.03)
        let borderColor: NSColor = isDark ? NSColor.white.withAlphaComponent(0.08)
                                          : NSColor.black.withAlphaComponent(0.08)

        bg.layer?.backgroundColor = bgColor.cgColor
        bg.layer?.borderColor = borderColor.cgColor
        bg.layer?.borderWidth = 1.0

        label.textColor = .labelColor
        if #available(macOS 10.14, *) {
            clearButton.contentTintColor = .tertiaryLabelColor
        } else {
            clearButton.contentTintColor = nil
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyAdaptiveColors()
    }

    func syncFromManager() {
        if let (code, mods) = HotkeyManager.shared.current() {
            label.stringValue = HotkeyManager.shared.displayString(keyCode: code, modifiers: mods)
            label.textColor = .labelColor
            showClear(true)
            isRecording = false
        } else {
            label.stringValue = "Record"
            label.textColor = .secondaryLabelColor
            showClear(false)
            isRecording = false
        }
        applyAdaptiveColors()
    }

    private func showClear(_ visible: Bool) {
        clearButton.isHidden = !visible
        labelTrailingToClear?.isActive = false
        labelTrailingToEdge?.isActive = false
        if visible {
            labelTrailingToClear?.isActive = true
        } else {
            labelTrailingToEdge?.isActive = true
        }
        needsLayout = true
        layoutSubtreeIfNeeded()
    }

    @objc private func beginRecording() {
        isRecording = true
        label.stringValue = "Press"
        label.textColor = .secondaryLabelColor
        showClear(false)
        bg.layer?.borderColor = NSColor.controlAccentColor.cgColor
        bg.layer?.borderWidth = 2
        window?.makeFirstResponder(self)
        addOutsideMonitor()
    }

    override func resignFirstResponder() -> Bool {
        let r = super.resignFirstResponder()
        isRecording = false
        syncFromManager()
        applyAdaptiveColors()
        removeOutsideMonitor()
        return r
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { super.keyDown(with: event); return }

        if event.keyCode == UInt16(kVK_Delete) || event.keyCode == UInt16(kVK_ForwardDelete) {
            onChange(nil, nil)
            isRecording = true
            label.stringValue = "Press"
            label.textColor = .secondaryLabelColor
            showClear(false)
            window?.makeFirstResponder(self)
            return
        }

        let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
        let carbonMods: UInt32 =
            (mods.contains(.command) ? UInt32(cmdKey) : 0) |
            (mods.contains(.shift)   ? UInt32(shiftKey) : 0) |
            (mods.contains(.option)  ? UInt32(optionKey) : 0) |
            (mods.contains(.control) ? UInt32(controlKey) : 0)

        let keyCode = UInt32(event.keyCode)

        if carbonMods == 0 {
            NSSound.beep()
            return
        }

        onChange(keyCode, carbonMods)
        isRecording = false
        syncFromManager()
        removeOutsideMonitor()
    }

    @objc private func clearTapped() {
        onChange(nil, nil)
        isRecording = false
        label.stringValue = "Record"
        label.textColor = .secondaryLabelColor
        showClear(false)
        applyAdaptiveColors()
        removeOutsideMonitor()
        window?.makeFirstResponder(nil)
    }

    private func addOutsideMonitor() {
        removeOutsideMonitor()
        outsideClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.isRecording else { return event }
            let locationInWindow = event.locationInWindow
            let locationInSelf = self.convert(locationInWindow, from: nil)
            if !self.bounds.contains(locationInSelf) {
                self.isRecording = false
                self.syncFromManager()
                self.window?.makeFirstResponder(nil)
                self.removeOutsideMonitor()
            }
            return event
        }
    }
    private func removeOutsideMonitor() {
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }
    func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldAttemptToRecognizeWith event: NSEvent) -> Bool {
        let point = convert(event.locationInWindow, from: nil)
        let hitRect = clearButton.frame.insetBy(dx: -4, dy: -4)
        return !hitRect.contains(point)
    }

    @objc private func systemAppearanceChanged(_ note: Notification) {
        applyAdaptiveColors()
        needsLayout = true
        needsDisplay = true
        layoutSubtreeIfNeeded()
    }

    deinit {
        if let token = appAppearanceObserver {
            DistributedNotificationCenter.default().removeObserver(token)
        }
    }
}

fileprivate func fourCC(_ s: String) -> OSType {
    var result: OSType = 0
    for c in s.utf8 { result = (result << 8) + OSType(c) }
    return result
}
