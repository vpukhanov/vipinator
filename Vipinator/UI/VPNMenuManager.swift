//
//  VPNMenuManager.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 07.07.2024.
//

import Cocoa
import ServiceManagement

@MainActor
class VPNMenuManager: NSObject, NSMenuDelegate {
    private let statusItemManager: VPNStatusItemManager
    private var vpnConnections: [VPNConnection] = []
    private var launchAtLoginMenuItem: NSMenuItem?

    init(statusItemManager: VPNStatusItemManager) {
        self.statusItemManager = statusItemManager
        super.init()
        setupMenu()
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
            let menuItem = NSMenuItem(title: vpn.name, action: #selector(vpnItemClicked(_:)), keyEquivalent: shortcut)

            if !shortcut.isEmpty {
                menuItem.keyEquivalentModifierMask = .command
            }

            menuItem.target = self
            menuItem.representedObject = vpn
            menu.addItem(menuItem)

            Task {
                await updateMenuItem(menuItem, for: vpn)
            }
        }

        menu.addItem(.separator())

        launchAtLoginMenuItem = NSMenuItem(
            title: "Start at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: "")
        launchAtLoginMenuItem?.target = self
        launchAtLoginMenuItem?.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchAtLoginMenuItem!)

        let aboutItem = NSMenuItem(title: "About Vipinator", action: #selector(showAboutPanel), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    func menuWillOpen(_: NSMenu) {
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

    @objc private func toggleLaunchAtLogin() {
        Task {
            do {
                let shouldEnable = SMAppService.mainApp.status != .enabled

                try await Task.detached {
                    if shouldEnable {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                }.value

                await MainActor.run {
                    launchAtLoginMenuItem?.state = SMAppService.mainApp.status == .enabled ? .on : .off
                }
            } catch {
                print("Failed to toggle launch at login: \(error)")
            }
        }
    }

    @objc private func showAboutPanel() {
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
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

    private func connectVPN(_ vpn: VPNConnection) async {
        do {
            let success = try await VPNManager.connect(to: vpn)
            if !success {
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
            if !success {
                print("Failed to disconnect from VPN: \(vpn.name)")
            }
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
}
