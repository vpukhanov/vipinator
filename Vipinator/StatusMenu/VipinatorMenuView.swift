import SwiftUI

struct VipinatorMenuView: View {
    @EnvironmentObject private var viewModel: VPNMenuViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView("Loading VPNs…")
                    .controlSize(.mini)
                    .padding(MenuRowMetrics.loadingPadding)
            } else if viewModel.connections.isEmpty {
                Text("No VPN connections found")
                    .foregroundStyle(.secondary)
                    .padding(MenuRowMetrics.loadingPadding)
            } else {
                ForEach(Array(viewModel.connections.enumerated()), id: \.element.id) { index, connection in
                    Toggle(isOn: isOnBinding(for: connection)) {
                        MenuRowContent(
                            shortcut: shortcutDisplay(for: index)
                        ) {
                            Text(connection.name)
                        }
                    }
                    .disabled(isMenuActionDisabled(for: connection.status))
                    .applyShortcut(shortcut(for: index))
                }
            }

            Divider()
                .padding(.vertical, MenuRowMetrics.dividerPadding)

            SettingsLink {
                MenuRowContent(
                    indentation: viewModel.isAnyConnectionActive ? MenuRowMetrics.activeServiceIndent : 0,
                    shortcut: MenuRowMetrics.commandShortcutDisplay(for: ",")
                ) {
                    Text("Settings…")
                }
            }
            .keyboardShortcut(",", modifiers: .command)

            Button {
                terminateApp()
            } label: {
                MenuRowContent(
                    indentation: viewModel.isAnyConnectionActive ? MenuRowMetrics.activeServiceIndent : 0,
                    shortcut: MenuRowMetrics.commandShortcutDisplay(for: "q")
                ) {
                    Text("Quit")
                }
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .controlSize(.mini)
        .padding(.vertical, MenuRowMetrics.containerVerticalPadding)
        .task {
            if viewModel.connections.isEmpty {
                await viewModel.refreshConnections()
            } else {
                await viewModel.refreshStatuses()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .vpnHotkeyPressed)) { _ in
            Task { await viewModel.toggleLastUsed() }
        }
    }

    private func shortcut(for index: Int) -> KeyboardShortcut? {
        guard index < MenuRowMetrics.hotkeyCharacters.count else { return nil }
        return KeyboardShortcut(KeyEquivalent(MenuRowMetrics.hotkeyCharacters[index]), modifiers: .command)
    }

    private func shortcutDisplay(for index: Int) -> String? {
        guard index < MenuRowMetrics.hotkeyCharacters.count else { return nil }
        return MenuRowMetrics.commandShortcutDisplay(for: MenuRowMetrics.hotkeyCharacters[index])
    }

    private func isMenuActionDisabled(for status: VPNStatus) -> Bool {
        switch status {
        case .connecting, .disconnecting, .invalid:
            return true
        case .connected, .disconnected:
            return false
        }
    }

    private func isOnBinding(for connection: VPNConnection) -> Binding<Bool> {
        Binding(
            get: { connection.status == .connected || connection.status == .connecting },
            set: { newValue in
                let isCurrentlyConnected = connection.status == .connected || connection.status == .connecting
                guard newValue != isCurrentlyConnected else { return }
                Task { await viewModel.toggle(connection) }
            }
        )
    }
}

struct StatusIconLabel: View {
    @EnvironmentObject private var viewModel: VPNMenuViewModel
    @AppStorage(StatusIconStyle.defaultsKey) private var iconStyleRaw = StatusIconStyle.bolt.rawValue

    private var style: StatusIconStyle { StatusIconStyle(rawValue: iconStyleRaw) ?? .bolt }

    var body: some View {
        Image(systemName: style.symbolName(isConnected: viewModel.isAnyConnectionActive))
            .symbolRenderingMode(.monochrome)
            .font(.system(size: style.menuBarPointSize, weight: .regular))
            .accessibilityLabel(viewModel.isAnyConnectionActive ? "VPN Connected" : "VPN Disconnected")
    }
}

private struct MenuRowContent<Title: View>: View {
    let indentation: CGFloat
    let shortcut: String?
    @ViewBuilder private let title: () -> Title

    init(
        indentation: CGFloat = 0,
        shortcut: String? = nil,
        @ViewBuilder title: @escaping () -> Title
    ) {
        self.indentation = indentation
        self.shortcut = shortcut
        self.title = title
    }

    var body: some View {
        HStack(spacing: MenuRowMetrics.contentSpacing) {
            title()
                .font(MenuRowMetrics.rowFont)
                .padding(.leading, indentation)

            Spacer(minLength: MenuRowMetrics.shortcutSpacing)

            if let shortcut {
                Text(shortcut)
                    .font(MenuRowMetrics.shortcutFont)
                    .foregroundStyle(MenuRowMetrics.shortcutColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, MenuRowMetrics.rowVerticalPadding)
        .padding(.horizontal, MenuRowMetrics.rowHorizontalPadding)
        .contentShape(Rectangle())
    }
}

private enum MenuRowMetrics {
    static let contentSpacing: CGFloat = 2
    static let rowVerticalPadding: CGFloat = 1
    static let rowHorizontalPadding: CGFloat = 2
    static let dividerPadding: CGFloat = 2
    static let containerVerticalPadding: CGFloat = 2
    static let rowFontSize: CGFloat = 12
    static let loadingPadding: CGFloat = 6
    static let shortcutSpacing: CGFloat = 4
    static let shortcutColor: Color = .primary

    static let hotkeyCharacters: [Character] = [
        "1", "2", "3", "4", "5", "6", "7", "8", "9"
    ]

    static var rowFont: Font { .system(size: rowFontSize) }
    static var shortcutFont: Font { .system(size: rowFontSize - 1, weight: .medium, design: .monospaced) }

    static let activeServiceIndent: CGFloat = {
        #if canImport(AppKit)
        let font = NSFont.menuFont(ofSize: rowFontSize)
        let spaceWidth = (" " as NSString).size(withAttributes: [.font: font]).width
        return spaceWidth * 4.5
        #else
        return 4.5 * 4
        #endif
    }()

    static func commandShortcutDisplay(for key: Character) -> String {
        commandShortcutDisplay(for: String(key))
    }

    static func commandShortcutDisplay(for key: String) -> String {
        "\(commandSymbol)\(key.uppercased())"
    }

    private static let commandSymbol = "⌘"
}

private struct OptionalShortcutModifier: ViewModifier {
    let shortcut: KeyboardShortcut?

    func body(content: Content) -> some View {
        if let shortcut {
            content.keyboardShortcut(shortcut)
        } else {
            content
        }
    }
}

private extension View {
    func applyShortcut(_ shortcut: KeyboardShortcut?) -> some View {
        modifier(OptionalShortcutModifier(shortcut: shortcut))
    }
}

private func terminateApp() {
    exit(EXIT_SUCCESS)
}
