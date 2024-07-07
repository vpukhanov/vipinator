//
//  AppDelegate.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 07.07.2024.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemManager: VPNStatusItemManager!
    private var menuManager: VPNMenuManager!
    private var networkObserver: NetworkConfigurationObserver!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Task { @MainActor in
            statusItemManager = VPNStatusItemManager()
            menuManager = VPNMenuManager(statusItemManager: statusItemManager)
            networkObserver = NetworkConfigurationObserver(handler: handleNetworkConfigurationChange)

            await menuManager.loadVPNConnections()
            menuManager.rebuildMenu()
            await menuManager.updateVPNStatuses()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        networkObserver.stopObserving()
    }

    private func handleNetworkConfigurationChange() {
        Task { @MainActor in
            await menuManager.updateVPNStatuses()
        }
    }
}
