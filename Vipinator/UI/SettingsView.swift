//
//  SettingsView.swift
//  Vipinator
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            PersonalizationView()
                .tabItem {
                    Label("Appearance", systemImage: "wand.and.sparkles")
                }
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
    }
}

