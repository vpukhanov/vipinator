//
//  VipinatorApp.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 07.07.2024.
//

import SwiftUI

@main
struct VipinatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
