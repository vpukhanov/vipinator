//
//  AppDelegate.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 07.07.2024.
//

import Cocoa
import SystemConfiguration
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var vpnConnections: [VPNConnection] = []
    var dynamicStoreCallback: SCDynamicStoreCallBack?
    var dynamicStore: SCDynamicStore?
    var launchAtLoginMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createStatusItem()
        loadVPNConnections()
        setupMenu()
        updateInitialStatusItemIcon()
        setupNetworkConfigurationObserver()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        removeNetworkConfigurationObserver()
    }

    func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bolt.horizontal", accessibilityDescription: "VPN Disconnected")
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
        
        // Add Launch at Login menu item
        launchAtLoginMenuItem = NSMenuItem(title: "Start at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginMenuItem?.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(launchAtLoginMenuItem!)
        
        // Add About and Quit menu items
        menu.addItem(NSMenuItem(title: "About Vipinator", action: #selector(showAboutPanel), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }
    
    @objc func showAboutPanel() {
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
    }
    
    @objc func toggleLaunchAtLogin() {
        let currentStatus = SMAppService.mainApp.status
        
        do {
            if currentStatus == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            launchAtLoginMenuItem?.state = isLaunchAtLoginEnabled() ? .on : .off
        } catch {
            print("Failed to toggle launch at login: \(error)")
            // Optionally, show an alert to the user about the failure
        }
    }

    func isLaunchAtLoginEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
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
        let imageName = isAnyVPNConnectedOrConnecting ? "bolt.horizontal.fill" : "bolt.horizontal"
        let accessibilityDescription = isAnyVPNConnectedOrConnecting ? "VPN Connected" : "VPN Disconnected"
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: accessibilityDescription)
            button.image?.isTemplate = true
        }
    }
    
    func setupNetworkConfigurationObserver() {
        // Create a closure that can be used as a callback
        dynamicStoreCallback = { (store: SCDynamicStore, changedKeys: CFArray, context: UnsafeMutableRawPointer?) in
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(context!).takeUnretainedValue()
            appDelegate.handleNetworkConfigurationChange()
        }

        var context = SCDynamicStoreContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        // Create the dynamic store
        dynamicStore = SCDynamicStoreCreate(
            nil,
            "VPNMonitor" as CFString,
            dynamicStoreCallback,
            &context
        )

        guard let dynamicStore = dynamicStore else {
            print("Failed to create dynamic store")
            return
        }

        // Set up the keys we want to monitor
        let keys = [
            "State:/Network/Global/IPv4" as CFString,
            "State:/Network/Global/IPv6" as CFString,
            "State:/Network/Interface" as CFString,
            "State:/Network/Service" as CFString
        ]
        SCDynamicStoreSetNotificationKeys(dynamicStore, keys as CFArray, nil)

        // Add the dynamic store to the run loop
        let runLoopSource = SCDynamicStoreCreateRunLoopSource(nil, dynamicStore, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
    }

    func removeNetworkConfigurationObserver() {
        if let dynamicStore = dynamicStore {
            let runLoopSource = SCDynamicStoreCreateRunLoopSource(nil, dynamicStore, 0)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        }
        dynamicStore = nil
    }

    func handleNetworkConfigurationChange() {
        DispatchQueue.main.async { [weak self] in
            print("Network configuration changed. Updating VPN statuses...")
            self?.updateVPNStatuses()
        }
    }
    
    func updateVPNStatuses() {
        let group = DispatchGroup()
        
        for (index, vpn) in vpnConnections.enumerated() {
            group.enter()
            VPNManager.getStatusAsync(for: vpn) { [weak self] status in
                guard let self = self else { return }
                if self.vpnConnections[index].status != status {
                    self.vpnConnections[index].status = status
                    if let menu = self.statusItem?.menu,
                       let item = menu.items.first(where: { ($0.representedObject as? VPNConnection)?.name == vpn.name }) {
                        self.updateMenuItem(item, with: status)
                    }
                    print("VPN \(vpn.name) status updated to: \(status)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.updateStatusItemIcon()
        }
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        loadVPNConnections()
        rebuildMenu()
    }
}
