//
//  AboutView.swift
//  Vipinator
//

import SwiftUI
import AppKit

struct AboutView: View {
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Vipinator"
    }
    
    private var version: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        return "Version \(shortVersion) (\(buildVersion))"
    }
    
    private var copyright: String {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? ""
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            
            Text(appName)
                .font(.system(size: 22, weight: .bold))
            
            Text(version)
                .foregroundStyle(.secondary)
            
            Link("With major contributions by \(Text("Artem Chebotok").underline())", destination: URL(string: "https://github.com/aachebotok")!)
                .foregroundStyle(.secondary)
            
            Text(copyright)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

