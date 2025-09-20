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

    private var lastIsConnected: Bool = false
    private var iconStyleObserver: NSObjectProtocol?
    private let iconStyleDefaultsKey = "StatusIconStyle"
    private let iconStyleDidChangeName = Notification.Name("StatusIconStyleDidChange")

    init() {
        createStatusItem()
        iconStyleObserver = NotificationCenter.default.addObserver(
            forName: iconStyleDidChangeName, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.applyCurrentIcon(isConnected: self.lastIsConnected)
            }
        }
    }

    deinit {
        if let obs = iconStyleObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        applyCurrentIcon(isConnected: false)
    }

    func updateIcon(isConnected: Bool) {
        lastIsConnected = isConnected
        applyCurrentIcon(isConnected: isConnected)
    }

    private func selectedStyle() -> String {
        UserDefaults.standard.string(forKey: iconStyleDefaultsKey) ?? "bolt"
    }

    private func symbolName(isConnected: Bool) -> String {
        switch selectedStyle() {
        case "bolt":
            return isConnected ? "bolt.horizontal.fill" : "bolt.horizontal"
        case "boltCircle":
            return isConnected ? "bolt.horizontal.circle.fill" : "bolt.horizontal.circle"
        case "network":
            return isConnected ? "network.badge.shield.half.filled" : "network"
        default:
            return isConnected ? "bolt.horizontal.fill" : "bolt.horizontal"
        }
    }

    private func symbolConfiguration() -> NSImage.SymbolConfiguration {
        let style = selectedStyle()
        let pointSize: CGFloat = (style == "bolt") ? 13 : 15
        return NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
    }

    private func currentIconImage(isConnected: Bool) -> NSImage? {
        let name = symbolName(isConnected: isConnected)
        let desc = isConnected ? "VPN Connected" : "VPN Disconnected"
        let config = symbolConfiguration()
        let image = NSImage(systemSymbolName: name, accessibilityDescription: desc)?.withSymbolConfiguration(config)
        image?.isTemplate = true
        return image
    }

    private func applyCurrentIcon(isConnected: Bool) {
        let image = currentIconImage(isConnected: isConnected)
        statusItem?.button?.image = image
        statusItem?.button?.imageScaling = .scaleProportionallyDown
        statusItem?.button?.imagePosition = .imageOnly
    }
}
