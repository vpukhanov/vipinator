//
//  GeneralSettingsView.swift
//  Vipinator
//

import SwiftUI
import AppKit
import ServiceManagement
import KeyboardShortcuts

struct GeneralSettingsView: View {
    @State private var isOpenAtLogin: Bool = SMAppService.mainApp.status == .enabled
    
    var body: some View {
        Form {
            Section {
                Toggle("Open at Login", isOn: $isOpenAtLogin)
                    .onChange(of: isOpenAtLogin) { oldValue, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            NSSound.beep()
                            isOpenAtLogin = SMAppService.mainApp.status == .enabled
                            NSLog("OpenAtLogin toggle error: \(error.localizedDescription)")
                        }
                    }
                
                Text("Launch Vipinator in the menu bar when you start your device")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                HStack {
                    Text("Toggle VPN Hotkey")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .toggleVPN)
                }
                
                Text("Toggle the last VPN you connected to with a global keyboard shortcut")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

