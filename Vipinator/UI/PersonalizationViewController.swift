//
//  PersonalizationViewController.swift
//  Vipinator
//

import AppKit

extension Notification.Name {
    static let statusIconStyleDidChange = Notification.Name("StatusIconStyleDidChange")
}

fileprivate enum StatusIconStyle: String, CaseIterable {
    case bolt, boltCircle, network

    static let defaultsKey = "StatusIconStyle"

    static var current: StatusIconStyle {
        if let raw = UserDefaults.standard.string(forKey: defaultsKey),
           let s = StatusIconStyle(rawValue: raw) { return s }
        return .bolt
    }

    static func set(_ style: StatusIconStyle) {
        UserDefaults.standard.set(style.rawValue, forKey: defaultsKey)
        NotificationCenter.default.post(name: .statusIconStyleDidChange, object: nil)
    }

    var previewSymbol: String {
        switch self {
        case .bolt:       return "bolt.horizontal"
        case .boltCircle: return "bolt.horizontal.circle"
        case .network:    return "network"
        }
    }

    func activeSymbol() -> String {
        switch self {
        case .bolt:       return "bolt.horizontal.fill"
        case .boltCircle: return "bolt.horizontal.circle.fill"
        case .network:    return "network.badge.shield.half.filled"
        }
    }
}

final class PersonalizationViewController: NSViewController {
    private let card = NSVisualEffectView()
    private let content = NSView()
    private var optionViews: [IconOptionView] = []

    private let headerLabel = NSTextField(labelWithString: "Menubar icon")
    private let separator = NSBox()

    private let subtitle = NSTextField(labelWithString: "Customize the appearance of the icon in the menubar.")

    override func loadView() { view = NSView() }

    override func viewDidLoad() {
        super.viewDidLoad()

        card.material = .contentBackground
        card.blendingMode = .behindWindow
        card.state = .active
        card.translatesAutoresizingMaskIntoConstraints = false
        card.wantsLayer = true
        card.layer?.cornerRadius = 12
        card.layer?.masksToBounds = true

        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        view.addSubview(card)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),

            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        headerLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        headerLabel.alignment = .left
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(headerLabel)

        let styles: [StatusIconStyle] = [.bolt, .boltCircle, .network]
        let grid = NSGridView(views: [
            styles.map { style in
                let option = IconOptionView(style: style, isSelected: style == StatusIconStyle.current)
                option.delegate = self
                option.translatesAutoresizingMaskIntoConstraints = false
                option.widthAnchor.constraint(equalToConstant: 92).isActive = true
                option.heightAnchor.constraint(equalToConstant: 92).isActive = true
                optionViews.append(option)
                return option
            }
        ])
        grid.rowSpacing = 12
        grid.columnSpacing = 12
        grid.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(grid)

        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(separator)

        subtitle.textColor = .secondaryLabelColor
        subtitle.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        subtitle.alignment = .left
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(subtitle)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: content.topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor),

            grid.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            grid.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            grid.leadingAnchor.constraint(greaterThanOrEqualTo: content.leadingAnchor),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor),

            separator.topAnchor.constraint(equalTo: grid.bottomAnchor, constant: 12),
            separator.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: content.trailingAnchor),

            subtitle.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 8),
            subtitle.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            subtitle.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor),
            subtitle.bottomAnchor.constraint(equalTo: content.bottomAnchor)
        ])
    }
}

private protocol IconOptionViewDelegate: AnyObject {
    func iconOptionViewDidSelect(_ view: IconOptionView, style: StatusIconStyle)
}

private final class IconOptionView: NSView {
    weak var delegate: IconOptionViewDelegate?
    private let imageView = NSImageView()
    private let background = NSView()
    private let style: StatusIconStyle
    private var idleBorderColor: NSColor = .clear
    private var isSelected: Bool { didSet { updateAppearance() } }

    init(style: StatusIconStyle, isSelected: Bool) {
        self.style = style
        self.isSelected = isSelected
        super.init(frame: .zero)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false

        background.wantsLayer = true
        background.layer = CALayer()
        background.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        background.layer?.cornerRadius = 14
        background.layer?.borderWidth = 2
        background.layer?.borderColor = NSColor.clear.cgColor
        background.translatesAutoresizingMaskIntoConstraints = false

        addSubview(background)

        imageView.image = NSImage(systemSymbolName: style.previewSymbol, accessibilityDescription: nil)
        let config = NSImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        imageView.symbolConfiguration = config
        imageView.contentTintColor = .labelColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        let click = NSClickGestureRecognizer(target: self, action: #selector(didClick))
        addGestureRecognizer(click)

        NSLayoutConstraint.activate([
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.topAnchor.constraint(equalTo: topAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor),

            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        updateAppearance()
        applyAdaptiveColors()
    }

    required init?(coder: NSCoder) { nil }

    @objc private func didClick() {
        delegate?.iconOptionViewDidSelect(self, style: style)
    }

    private func updateAppearance() {
        if isSelected {
            background.layer?.borderColor = NSColor.controlAccentColor.cgColor
            background.layer?.borderWidth = 2
        } else {
            background.layer?.borderColor = idleBorderColor.cgColor
            background.layer?.borderWidth = 1
        }
    }

    private func applyAdaptiveColors() {
        // Robust light/dark adaptation (avoid white tiles in dark theme)
        let match = effectiveAppearance.bestMatch(from: [.darkAqua, .vibrantDark, .aqua, .vibrantLight])
        let isDark = (match == .darkAqua || match == .vibrantDark)

        // Subtle capsule background and border tuned for theme
        let bgColor: NSColor = isDark ? NSColor.white.withAlphaComponent(0.03)
                                      : NSColor.black.withAlphaComponent(0.03)
        idleBorderColor = isDark ? NSColor.white.withAlphaComponent(0.08)
                                 : NSColor.black.withAlphaComponent(0.08)

        background.layer?.backgroundColor = bgColor.cgColor
        imageView.contentTintColor = .labelColor

        // Re-apply current selection border with the new idle color
        updateAppearance()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyAdaptiveColors()
    }

    func setSelected(_ selected: Bool) {
        isSelected = selected
    }
}

extension PersonalizationViewController: IconOptionViewDelegate {
    fileprivate func iconOptionViewDidSelect(_ view: IconOptionView, style: StatusIconStyle) {
        optionViews.forEach { $0.setSelected($0 === view) }
        StatusIconStyle.set(style)
    }
}
