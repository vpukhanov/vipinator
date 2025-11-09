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

    private var showConnectedIcon: Bool = false
    private var iconStyleObserver: NSObjectProtocol?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        applyCurrentIcon()
        iconStyleObserver = NotificationCenter.default.addObserver(
            forName: .statusIconStyleDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.applyCurrentIcon()
            }
        }
    }

    deinit {
        if let obs = iconStyleObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    func updateStatus(isConnected: Bool) {
        showConnectedIcon = isConnected
        applyCurrentIcon()
    }

    private func applyCurrentIcon() {
        let symbolName = showConnectedIcon ? StatusIconStyle.current.connectedImage : StatusIconStyle.current.disconnectedImage
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 14, weight: .medium))
        statusItem?.button?.image = image
    }
}
