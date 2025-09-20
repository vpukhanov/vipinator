//
//  SettingsTabViewController.swift
//  Vipinator
//

import AppKit

final class SettingsTabViewController: NSTabViewController {
    override var title: String? {
        get { "Settings" }
        set { super.title = "Settings" }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(macOS 13.0, *) {
            tabStyle = .toolbar
        } else {
            tabStyle = .segmentedControlOnTop
        }

        let general = GeneralSettingsViewController()
        general.title = "General"

        let personalization = PersonalizationViewController()
        personalization.title = "Appearance"

        let about = AboutViewController()
        about.title = "About"

        addChild(general)
        addChild(personalization)
        addChild(about)

        if tabViewItems.indices.contains(0) { tabViewItems[0].label = "General" }
        if tabViewItems.indices.contains(1) { tabViewItems[1].label = "Appearance" }
        if tabViewItems.indices.contains(2) { tabViewItems[2].label = "About" }

        if #available(macOS 11.0, *) {
            if tabViewItems.indices.contains(0) {
                tabViewItems[0].image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Settings")
            }
            if tabViewItems.indices.contains(1) {
                tabViewItems[1].image = NSImage(systemSymbolName: "wand.and.sparkles", accessibilityDescription: "Appearance")
            }
            if tabViewItems.indices.contains(2) {
                tabViewItems[2].image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About")
            }
        }
    }
}
