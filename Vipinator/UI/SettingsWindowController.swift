//
//  SettingsWindowController.swift
//  Vipinator
//
//  Created by Artem Chebotok on 9/16/25.
//

import AppKit

final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()
    private var didElevateOnce = false
    private var titleObserver: NSObjectProtocol?

    private init() {
        let contentVC: NSViewController
        if let cls = NSClassFromString("Vipinator.SettingsSplitViewController") as? NSViewController.Type {
            contentVC = cls.init()
        } else {
            contentVC = SettingsTabViewController()
        }
        let win = NSWindow(contentViewController: contentVC)
        win.title = "Settings"
        win.styleMask = NSWindow.StyleMask([.titled, .closable, .miniaturizable])

        win.titleVisibility = .visible
        win.titlebarAppearsTransparent = true
        win.toolbarStyle = .preference

        // Keep a constant title ("Settings") regardless of tab changes
        titleObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didUpdateNotification,
            object: win,
            queue: .main
        ) { [weak win] _ in
            win?.title = "Settings"
        }

        if let titlebar = win.standardWindowButton(.closeButton)?.superview,
           let close = win.standardWindowButton(.closeButton),
           let mini  = win.standardWindowButton(.miniaturizeButton),
           let zoom  = win.standardWindowButton(.zoomButton) {

            let union1 = close.frame.union(mini.frame)
            let unionAll = union1.union(zoom.frame)
            let padX: CGFloat = 8
            let padY: CGFloat = 6
            let bgFrame = NSRect(x: unionAll.origin.x - padX,
                                 y: unionAll.origin.y - padY,
                                 width: unionAll.size.width + padX * 2,
                                 height: unionAll.size.height + padY * 2)

            let glass = NSVisualEffectView(frame: bgFrame)
            glass.material = .headerView
            glass.blendingMode = .withinWindow
            glass.state = .active
            glass.wantsLayer = true
            glass.layer?.cornerRadius = glass.frame.height / 2.0
            glass.layer?.masksToBounds = true
            glass.autoresizingMask = [.minYMargin, .maxXMargin]

            titlebar.addSubview(glass, positioned: .below, relativeTo: close)
        }

        win.isReleasedWhenClosed = false
        let fixedSize = NSSize(width: 520, height: 360)
        win.setContentSize(fixedSize)
        win.minSize = fixedSize
        win.maxSize = fixedSize
        win.center()
        super.init(window: win)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use SettingsWindowController.shared")
    }

    func show() {
        guard let w = window else { return }

        if !didElevateOnce {
            w.level = .floating
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            didElevateOnce = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                w.level = .normal
            }
        } else {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    deinit {
        if let obs = titleObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}
