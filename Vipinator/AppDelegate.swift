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
        setupMenu()
    }

    func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "network", accessibilityDescription: "VPN")
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
            let menuItem = NSMenuItem(title: vpn.name, action: #selector(vpnItemClicked(_:)), keyEquivalent: "")
            menuItem.representedObject = vpn
            menu.addItem(menuItem)
            
            // Set initial state as disabled
            menuItem.isEnabled = false
            
            // Fetch status asynchronously
            VPNManager.getStatusAsync(for: vpn) { [weak self] status in
                guard let self = self else { return }
                self.vpnConnections[index].status = status
                self.updateMenuItem(menuItem, with: status)
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
        case .connecting, .disconnecting:
            menuItem.state = .mixed
            menuItem.isEnabled = true
        case .disconnected:
            menuItem.state = .off
            menuItem.isEnabled = true
        case .invalid:
            menuItem.state = .off
            menuItem.isEnabled = false
        }
    }

    @objc func vpnItemClicked(_ sender: NSMenuItem) {
        guard let vpn = sender.representedObject as? VPNConnection else { return }
        if vpn.status == .invalid {
            print("VPN is invalid and cannot be activated: \(vpn.name)")
        } else {
            print("VPN clicked: \(vpn.name), Current status: \(vpn.status.rawValue)")
            // TODO: logic to connect/disconnect the VPN
        }
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        loadVPNConnections()
        rebuildMenu()
    }
}
