//
//  AboutViewController.swift
//  Vipinator
//

import AppKit

final class AboutViewController: NSViewController {
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: AboutViewController.appName)
    private let versionLabel = NSTextField(labelWithString: "Version \(AboutViewController.appVersion) (\(AboutViewController.buildNumber))")
    private let supportLabel = NSTextField(labelWithString: "The innovations in this version were made by Artem Chebotok.")
    private let copyrightLabel = NSTextField(labelWithString: AboutViewController.copyright)

    override func loadView() { view = NSView() }

    override func viewDidLoad() {
        super.viewDidLoad()

        iconView.image = NSApplication.shared.applicationIconImage
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.wantsLayer = false

        [titleLabel, versionLabel, supportLabel, copyrightLabel].forEach {
            $0.alignment = .center
            $0.lineBreakMode = .byWordWrapping
            $0.maximumNumberOfLines = 2
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        titleLabel.font = .boldSystemFont(ofSize: 22)
        versionLabel.textColor = .secondaryLabelColor
        supportLabel.textColor = .secondaryLabelColor
        copyrightLabel.textColor = .secondaryLabelColor

        // Plain styling (no blue/underline), manual click handler
        supportLabel.isSelectable = false
        supportLabel.allowsEditingTextAttributes = false
        let fullText = "The innovations in this version were made by Artem Chebotok."
        let attributed = NSMutableAttributedString(string: fullText)
        attributed.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: NSRange(location: 0, length: attributed.length))
        supportLabel.attributedStringValue = attributed

        let click = NSClickGestureRecognizer(target: self, action: #selector(openAuthorLink))
        supportLabel.addGestureRecognizer(click)
        supportLabel.isEnabled = true

        let stack = NSStackView(views: [iconView, titleLabel, versionLabel, supportLabel, copyrightLabel])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 96),
            iconView.heightAnchor.constraint(equalToConstant: 96),

            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            view.trailingAnchor.constraint(greaterThanOrEqualTo: stack.trailingAnchor, constant: 20)
        ])
    }

    @objc private func openAuthorLink() {
        if let url = URL(string: "https://github.com/aachebotok") {
            NSWorkspace.shared.open(url)
        }
    }
}

private extension AboutViewController {
    static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "App"
    }
    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
    static var copyright: String {
        if let s = Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String, !s.isEmpty {
            return s
        }
        let year = Calendar.current.component(.year, from: Date())
        return "© \(year)"
    }
}
