//
//  VPNMenuManager.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 07.07.2024.
//

import Cocoa
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleVPN = Self("toggleVPN")
}

@MainActor
class VPNMenuManager: NSObject, NSMenuDelegate {
    private let statusItemManager: VPNStatusItemManager
    private var vpnConnections: [VPNConnection] = []
    
    private let settingsMenuItem = NSMenuItem(title: "Settings…",
                                              action: #selector(openSettings),
                                              keyEquivalent: ",")
    private let quitMenuItem = NSMenuItem(title: "Quit",
                                          action: #selector(NSApplication.terminate(_:)),
                                          keyEquivalent: "q")
    
    private static let lastUsedVPNKey = "LastUsedVPNName"

    init(statusItemManager: VPNStatusItemManager) {
        self.statusItemManager = statusItemManager
        super.init()
        setupMenu()
        setupHotkey()
    }
    
    private func setupHotkey() {
        KeyboardShortcuts.onKeyUp(for: .toggleVPN) { [weak self] in
            Task { @MainActor [weak self] in
                await self?.toggleLastUsedVPN()
            }
        }
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.delegate = self
        statusItemManager.statusItem?.menu = menu
        settingsMenuItem.target = self
    }

    func rebuildMenu() {
        guard let menu = statusItemManager.statusItem?.menu else { return }
        
        menu.removeAllItems()

        for (index, vpn) in vpnConnections.enumerated() {
            let shortcut = index < 9 ? "\(index + 1)" : (index == 9 ? "0" : "")
            let item = NSMenuItem(title: vpn.name,
                                  action: #selector(vpnItemClicked(_:)),
                                  keyEquivalent: shortcut)

            if !shortcut.isEmpty { item.keyEquivalentModifierMask = .command }
            item.target = self
            item.representedObject = vpn
            menu.addItem(item)

            Task { await updateMenuItem(item, for: vpn) }
        }

        menu.addItem(.separator())
        menu.addItem(settingsMenuItem)
        menu.addItem(quitMenuItem)
    }

    func menuWillOpen(_ menu: NSMenu) {
        Task {
            await loadVPNConnections()
            rebuildMenu()
        }
    }

    @objc private func vpnItemClicked(_ sender: NSMenuItem) {
        guard let vpn = sender.representedObject as? VPNConnection else { return }
        Task {
            await toggleVPN(vpn)
        }
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if let event = NSEvent.keyEvent(
            with: .keyDown,
            location: NSPoint(),
            modifierFlags: .command,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: ",",
            isARepeat: false,
            keyCode: 43 // comma
        ) {
            NSApplication.shared.postEvent(event, atStart: false)
        }
    }

    private func updateMenuItem(_ menuItem: NSMenuItem, for vpn: VPNConnection) async {
        do {
            let status = try await VPNManager.getStatus(for: vpn)
            await MainActor.run {
                menuItem.isEnabled = status == .connected || status == .disconnected
                switch status {
                case .connected:
                    menuItem.state = .on
                case .disconnected, .invalid:
                    menuItem.state = .off
                case .connecting, .disconnecting:
                    menuItem.state = .mixed
                }
            }
        } catch {
            print("Error updating menu item for \(vpn.name): \(error)")
        }
    }

    func loadVPNConnections() async {
        do {
            vpnConnections = try await VPNManager.getAvailableVPNs()
        } catch {
            print("Error loading VPN connections: \(error)")
        }
    }

    private func toggleLastUsedVPN() async {
        if vpnConnections.isEmpty {
            await loadVPNConnections()
        }
        let name = loadLastUsedVPN() ?? ""
        guard
              let vpn = vpnConnections.first(where: { $0.name == name }) ?? vpnConnections.first else { return }
        await toggleVPN(vpn)
    }
    
    private func toggleVPN(_ vpn: VPNConnection) async {
        do {
            let status = try await VPNManager.getStatus(for: vpn)
            switch status {
            case .connected:
                await disconnectVPN(vpn)
            case .disconnected:
                await connectVPN(vpn)
            case .connecting, .disconnecting, .invalid:
                break
            }
        } catch {
            print("VPN toggle failed: \(error)")
        }
    }

    private func connectVPN(_ vpn: VPNConnection) async {
        do {
            let success = try await VPNManager.connect(to: vpn)
            if success {
                saveLastUsedVPN(vpn.name)
            } else {
                print("Failed to connect to VPN: \(vpn.name)")
            }
            await updateVPNStatuses()
        } catch {
            print("Error connecting to VPN: \(vpn.name). \(error)")
        }
    }

    private func disconnectVPN(_ vpn: VPNConnection) async {
        do {
            let success = try await VPNManager.disconnect(from: vpn)
            if !success { print("Failed to disconnect from VPN: \(vpn.name)") }
            await updateVPNStatuses()
        } catch {
            print("Error disconnecting from VPN: \(vpn.name). \(error)")
        }
    }

    func updateVPNStatuses() async {
        var isAnyVPNConnected = false

        for vpn in vpnConnections {
            do {
                let status = try await VPNManager.getStatus(for: vpn)

                if let menuItem = statusItemManager.statusItem?.menu?.items.first(
                    where: { ($0.representedObject as? VPNConnection)?.name == vpn.name }
                ) {
                    await updateMenuItem(menuItem, for: vpn)
                }

                if status == .connected || status == .connecting {
                    isAnyVPNConnected = true
                }
            } catch {
                print("Error updating status for VPN \(vpn.name): \(error)")
            }
        }

        statusItemManager.updateStatus(isConnected: isAnyVPNConnected)
    }
    
    private func saveLastUsedVPN(_ name: String) {
        UserDefaults.standard.set(name, forKey: Self.lastUsedVPNKey)
    }
    
    private func loadLastUsedVPN() -> String? {
        UserDefaults.standard.string(forKey: Self.lastUsedVPNKey)
    }
}
