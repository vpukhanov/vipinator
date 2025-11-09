//
//  GeneralSettingsView.swift
//  Vipinator
//

import SwiftUI
import AppKit
import ServiceManagement

struct GeneralSettingsView: View {
    @State private var isOpenAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @State private var hotkeyDisplayString: String = HotkeyManager.shared.currentDisplayString()
    
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
                    HotkeyRecorderView(displayString: $hotkeyDisplayString)
                        .frame(width: 150, height: 28)
                }
                
                Text("Toggle the last VPN you connected to with a global keyboard shortcut")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            HotkeyManager.shared.ensureDefaultRegistered()
            hotkeyDisplayString = HotkeyManager.shared.currentDisplayString()
        }
    }
}

