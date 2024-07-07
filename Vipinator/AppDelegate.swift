//
//  AppDelegate.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 07.07.2024.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createStatusItem()
        setupMenu()
    }

    func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "network", accessibilityDescription: "VPN")
            button.image?.isTemplate = true // This allows the icon to adapt to the system appearance (light/dark mode)
        }
    }

    func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
}
