//
//  NetworkConfigurationObserver.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 07.07.2024.
//

import Foundation
import SystemConfiguration

class NetworkConfigurationObserver {
    private var dynamicStore: SCDynamicStore?
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
        setupNetworkConfigurationObserver()
    }

    private func setupNetworkConfigurationObserver() {
        let callback: SCDynamicStoreCallBack = { _, _, context in
            guard let context = context else { return }
            let observer = Unmanaged<NetworkConfigurationObserver>.fromOpaque(context).takeUnretainedValue()
            observer.handler()
        }

        var context = SCDynamicStoreContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        dynamicStore = SCDynamicStoreCreate(
            nil,
            "VPNMonitor" as CFString,
            callback,
            &context
        )

        guard let dynamicStore = dynamicStore else {
            // Instead of printing, we could throw an error or use a result type.
            // For now, we'll just return early.
            return
        }

        let keys = [
            "State:/Network/Global/IPv4",
            "State:/Network/Global/IPv6",
            "State:/Network/Interface",
            "State:/Network/Service"
        ]

        SCDynamicStoreSetNotificationKeys(dynamicStore, keys as CFArray, nil)

        let runLoopSource = SCDynamicStoreCreateRunLoopSource(nil, dynamicStore, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
    }

    func stopObserving() {
        if let dynamicStore = dynamicStore {
            let runLoopSource = SCDynamicStoreCreateRunLoopSource(nil, dynamicStore, 0)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        }
        dynamicStore = nil
    }
}
