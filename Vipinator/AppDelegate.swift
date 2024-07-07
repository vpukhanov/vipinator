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
        
        for vpn in vpnConnections where vpn.status != .invalid {
            let menuItem = NSMenuItem(title: vpn.name, action: #selector(vpnItemClicked(_:)), keyEquivalent: "")
            menuItem.representedObject = vpn
            
            // Add a status indicator
            switch vpn.status {
            case .connected:
                menuItem.state = .on
            case .connecting, .disconnecting:
                menuItem.state = .mixed
            case .disconnected, .invalid:
                menuItem.state = .off
            }
            
            menu.addItem(menuItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc func vpnItemClicked(_ sender: NSMenuItem) {
        guard let vpn = sender.representedObject as? VPNConnection else { return }
        print("VPN clicked: \(vpn.name), Current status: \(vpn.status.rawValue)")
        // TODO: logic to connect/disconnect the VPN
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        loadVPNConnections()
        rebuildMenu()
    }
}
