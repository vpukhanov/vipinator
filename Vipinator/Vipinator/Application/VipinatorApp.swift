import SwiftUI

@main
struct VipinatorApp: App {
    @StateObject private var menuViewModel = VPNMenuViewModel()

    var body: some Scene {
        MenuBarExtra {
            VipinatorMenuView()
                .environmentObject(menuViewModel)
        } label: {
            StatusIconLabel()
                .environmentObject(menuViewModel)
        }

        Settings {
            SettingsViews()
                .environmentObject(menuViewModel)
        }
    }
}
