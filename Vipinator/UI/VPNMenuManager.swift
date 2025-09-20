//
//  VPNMenuManager.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 07.07.2024.
//

import Cocoa

@MainActor
class VPNMenuManager: NSObject, NSMenuDelegate {
    private let statusItemManager: VPNStatusItemManager
    private var vpnConnections: [VPNConnection] = []
    private var hotkeyObserver: NSObjectProtocol?
    private let lastStore = LastUsedVPNStore.shared

    init(statusItemManager: VPNStatusItemManager) {
        self.statusItemManager = statusItemManager
        super.init()
        setupMenu()
        hotkeyObserver = NotificationCenter.default.addObserver(
            forName: .vpnHotkeyPressed, object: nil, queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.toggleLastUsedVPN()
            }
        }
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.delegate = self
        statusItemManager.statusItem?.menu = menu
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

        let settingsItem = NSMenuItem(title: "Settings…",
                                      action: #selector(openSettings),
                                      keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem(title: "Quit",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
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
            do {
                let currentStatus = try await VPNManager.getStatus(for: vpn)
                switch currentStatus {
                case .connected:
                    await disconnectVPN(vpn)
                case .disconnected:
                    await connectVPN(vpn)
                case .connecting, .disconnecting, .invalid:
                    break
                }
            } catch {
                print("Error getting VPN status: \(error)")
            }
        }
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    private func updateMenuItem(_ menuItem: NSMenuItem, for vpn: VPNConnection) async {
        do {
            let status = try await VPNManager.getStatus(for: vpn)
            await MainActor.run {
                switch status {
                case .connected:
                    menuItem.state = .on
                    menuItem.isEnabled = true
                case .disconnected:
                    menuItem.state = .off
                    menuItem.isEnabled = true
                case .connecting, .disconnecting:
                    menuItem.state = .mixed
                    menuItem.isEnabled = false
                case .invalid:
                    menuItem.state = .off
                    menuItem.isEnabled = false
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
        let targetName = lastStore.load() ?? vpnConnections.first?.name
        guard let name = targetName,
              let vpn = vpnConnections.first(where: { $0.name == name }) else { return }
        do {
            let status = try await VPNManager.getStatus(for: vpn)
            switch status {
            case .connected, .connecting:
                await disconnectVPN(vpn)
            case .disconnected, .invalid, .disconnecting:
                await connectVPN(vpn)
            }
        } catch {
            print("Hotkey toggle failed: \(error)")
        }
    }

    private func connectVPN(_ vpn: VPNConnection) async {
        do {
            let success = try await VPNManager.connect(to: vpn)
            if success {
                lastStore.save(vpn.name)
            }
            if !success { print("Failed to connect to VPN: \(vpn.name)") }
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

        statusItemManager.updateIcon(isConnected: isAnyVPNConnected)
    }
    func lastUsedVPNName() -> String? {
        lastStore.load()
    }

    deinit {
        if let o = hotkeyObserver { NotificationCenter.default.removeObserver(o) }
    }
}
