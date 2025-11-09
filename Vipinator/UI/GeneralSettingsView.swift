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
            Section(header: Text("Login Item"), footer: Text("Launch Vipinator in the menu bar when you start your device")) {
                Toggle("Open at Login", isOn: $isOpenAtLogin.onChange(toggleOpenAtLogin))
            }
            
            Section(header: Text("Hotkeys"), footer: Text("Toggle the last VPN you connected to with a global keyboard shortcut")) {
                KeyboardShortcuts.Recorder("Toggle recent VPN", name: .toggleVPN)
            }
        }
        .formStyle(.grouped)
    }
    
    private func toggleOpenAtLogin() {
        do {
            if isOpenAtLogin {
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
}

