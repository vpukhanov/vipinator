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
        
        for vpn in vpnConnections {
            menu.addItem(NSMenuItem(title: vpn.name, action: #selector(vpnItemClicked(_:)), keyEquivalent: ""))
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }

    @objc func vpnItemClicked(_ sender: NSMenuItem) {
        print("VPN clicked: \(sender.title)")
        // TODO: logic to connect/disconnect the VPN
    }
}
