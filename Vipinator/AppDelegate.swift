//
//  AppDelegate.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 07.07.2024.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var vpnConnections: [VPNConnection] = []

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createStatusItem()
        loadVPNConnections()
        setupMenu()
        updateInitialStatusItemIcon()
    }

    func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "network.slash", accessibilityDescription: "VPN")
            button.image?.isTemplate = true
        }
    }

    func loadVPNConnections() {
        vpnConnections = VPNManager.getAvailableVPNs()
        print("Loaded \(vpnConnections.count) network connections")
    }

    func setupMenu() {
        let menu = NSMenu()
        menu.delegate = self
        statusItem?.menu = menu
    }

    func rebuildMenu() {
        guard let menu = statusItem?.menu else { return }
        
        menu.removeAllItems()
        
        for (index, vpn) in vpnConnections.enumerated() {
            let shortcut = index < 9 ? "\(index + 1)" : (index == 9 ? "0" : "")
            let menuItem = NSMenuItem(title: vpn.name, action: #selector(vpnItemClicked(_:)), keyEquivalent: shortcut)
            
            if !shortcut.isEmpty {
                menuItem.keyEquivalentModifierMask = .command
            }
            
            menuItem.representedObject = vpn
            menu.addItem(menuItem)
            
            // Set initial state as disabled
            menuItem.isEnabled = false
            
            // Fetch status asynchronously
            VPNManager.getStatusAsync(for: vpn) { [weak self] status in
                guard let self = self else { return }
                self.vpnConnections[index].status = status
                self.updateMenuItem(menuItem, with: status)
                self.updateStatusItemIcon()
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }
    
    func updateMenuItem(_ menuItem: NSMenuItem, with status: VPNStatus) {
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

    @objc func vpnItemClicked(_ sender: NSMenuItem) {
        guard let vpn = sender.representedObject as? VPNConnection else { return }
        
        // Fetch the current status before taking action
        VPNManager.getStatusAsync(for: vpn) { [weak self] currentStatus in
            guard let self = self else { return }
            
            switch currentStatus {
            case .connected:
                self.disconnectVPN(vpn)
            case .disconnected:
                self.connectVPN(vpn)
            case .connecting, .disconnecting, .invalid:
                print("VPN is in transition or invalid state: \(vpn.name)")
            }
        }
    }
    
    func connectVPN(_ vpn: VPNConnection) {
        print("Attempting to connect to VPN: \(vpn.name)")
        updateVPNStatus(vpn, newStatus: .connecting)
        
        VPNManager.connect(to: vpn) { [weak self] success in
            guard let self = self else { return }
            if success {
                print("Successfully connected to VPN: \(vpn.name)")
                self.updateVPNStatus(vpn, newStatus: .connected)
            } else {
                print("Failed to connect to VPN: \(vpn.name)")
                // Fetch the current status instead of assuming it's disconnected
                VPNManager.getStatusAsync(for: vpn) { status in
                    self.updateVPNStatus(vpn, newStatus: status)
                }
            }
        }
    }
    
    func disconnectVPN(_ vpn: VPNConnection) {
        print("Attempting to disconnect from VPN: \(vpn.name)")
        updateVPNStatus(vpn, newStatus: .disconnecting)
        
        VPNManager.disconnect(from: vpn) { [weak self] success in
            guard let self = self else { return }
            if success {
                print("Successfully disconnected from VPN: \(vpn.name)")
                self.updateVPNStatus(vpn, newStatus: .disconnected)
            } else {
                print("Failed to disconnect from VPN: \(vpn.name)")
                // Fetch the current status instead of assuming it's connected
                VPNManager.getStatusAsync(for: vpn) { status in
                    self.updateVPNStatus(vpn, newStatus: status)
                }
            }
        }
    }

    func updateVPNStatus(_ vpn: VPNConnection, newStatus: VPNStatus) {
        if let index = vpnConnections.firstIndex(where: { $0.name == vpn.name }) {
            vpnConnections[index].status = newStatus
            if let menu = statusItem?.menu, let item = menu.items.first(where: { ($0.representedObject as? VPNConnection)?.name == vpn.name }) {
                updateMenuItem(item, with: newStatus)
            }
        }
        print("VPN \(vpn.name) status updated to: \(newStatus)")
        updateStatusItemIcon()
    }
    
    func updateInitialStatusItemIcon() {
        let group = DispatchGroup()
        
        for (index, vpn) in vpnConnections.enumerated() {
            group.enter()
            VPNManager.getStatusAsync(for: vpn) { [weak self] status in
                guard let self = self else { return }
                self.vpnConnections[index].status = status
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.updateStatusItemIcon()
        }
    }
    
    func updateStatusItemIcon() {
        let isAnyVPNConnectedOrConnecting = vpnConnections.contains { $0.status == .connected || $0.status == .connecting }
        let imageName = isAnyVPNConnectedOrConnecting ? "network" : "network.slash"
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: "VPN")
            button.image?.isTemplate = true
        }
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        loadVPNConnections()
        rebuildMenu()
    }
}
