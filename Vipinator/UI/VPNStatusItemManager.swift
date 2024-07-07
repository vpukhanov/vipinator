//
//  VPNStatusItemManager.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 07.07.2024.
//

import Cocoa

@MainActor
class VPNStatusItemManager {
    private(set) var statusItem: NSStatusItem?

    init() {
        createStatusItem()
    }

    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bolt.horizontal", accessibilityDescription: "VPN Disconnected")
            button.image?.isTemplate = true
        }
    }

    func updateIcon(isConnected: Bool) {
        let imageName = isConnected ? "bolt.horizontal.fill" : "bolt.horizontal"
        let accessibilityDescription = isConnected ? "VPN Connected" : "VPN Disconnected"

        statusItem?.button?.image = NSImage(systemSymbolName: imageName, accessibilityDescription: accessibilityDescription)
        statusItem?.button?.image?.isTemplate = true
    }
}
