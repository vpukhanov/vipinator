import SwiftUI
import ServiceManagement

struct SettingsViews: View {

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }

            AppearanceSettingsView()
                .tabItem { Label("Appearance", systemImage: "wand.and.sparkles") }

            AboutSettingsView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .tabViewStyle(.automatic)
        .background(Color.clear)
        .overlay(alignment: .bottom) {
            Color.gray.opacity(0.12)
                .frame(height: 1)
        }
        .frame(minWidth: 520, idealWidth: 520, maxWidth: 520,
               minHeight: 360, idealHeight: 360, maxHeight: 360)
    }
}

private struct GeneralSettingsView: View {
    @State private var openAtLogin = SMAppService.mainApp.status == .enabled
    @State private var hotkeyDisplay = HotkeyManager.shared.currentDisplayString()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsCard {
                SettingsRow(title: "Open at Login") { width in
                    Toggle("", isOn: $openAtLogin)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .frame(width: width, alignment: .trailing)
                        .onChange(of: openAtLogin) { _, newValue in
                            updateOpenAtLogin(newValue)
                        }
                }

                SettingsDivider()

                Text("Launch Vipinator in the menu bar when you start your device")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            SettingsCard {
                SettingsRow(title: "Toggle VPN Hotkey") { width in
                    HotkeyRecorderView(displayText: $hotkeyDisplay) { keyCode, modifiers in
                        HotkeyManager.shared.saveAndRegister(keyCode: keyCode, modifiers: modifiers)
                        hotkeyDisplay = HotkeyManager.shared.currentDisplayString()
                    }
                    .frame(width: width, alignment: .trailing)
                }

                SettingsDivider()

                Text("Toggle the last VPN you connected to with a global keyboard shortcut")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20)
        .padding(.top, 0)
        .padding(.bottom, 0)
    }

    @MainActor
    private func updateOpenAtLogin(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            openAtLogin.toggle()
        }
    }

}


// MARK: - Shared Building Blocks

private struct SettingsCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color.clear : Color.clear
    }
}

private struct SettingsRow<Trailing: View>: View {
    let title: String
    let trailingWidthRatio: CGFloat
    let minHeight: CGFloat
    var trailing: (CGFloat) -> Trailing

    init(title: String,
         trailingWidthRatio: CGFloat = 0.30,
         minHeight: CGFloat = 36,
         @ViewBuilder trailing: @escaping (CGFloat) -> Trailing) {
        self.title = title
        self.trailingWidthRatio = trailingWidthRatio
        self.minHeight = minHeight
        self.trailing = trailing
    }

    var body: some View {
        GeometryReader { proxy in
            let trailingWidth = proxy.size.width * trailingWidthRatio
            HStack(alignment: .bottom, spacing: 12) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                trailing(trailingWidth)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
        }
        .frame(height: max(minHeight, 36))
    }
}

private struct SettingsDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }

    private var dividerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }
}

private struct AppearanceSettingsView: View {
    @AppStorage(StatusIconStyle.defaultsKey) private var iconStyleRaw = StatusIconStyle.bolt.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsCard {
                VStack(alignment: .leading, spacing: 12) {
                    SettingsRow(title: "Menu Bar Icon",
                                trailingWidthRatio: 0.01,
                                minHeight: 28) { width in
                        Color.clear.frame(width: width)
                    }

                    HStack(spacing: 16) {
                        Spacer(minLength: 0)
                        ForEach(StatusIconStyle.allCases) { style in
                            AppearanceOption(style: style,
                                             isSelected: iconStyleRaw == style.rawValue)
                                .onTapGesture { iconStyleRaw = style.rawValue }
                        }
                        Spacer(minLength: 0)
                    }

                    SettingsDivider()

                    Text("Choose the appearance of the icon in the menu bar")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20)
        .padding(.top, 0)
        .padding(.bottom, 0)
    }
}

private struct AppearanceOption: View {
    let style: StatusIconStyle
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            glassSurface

            Image(systemName: style.previewSymbolName)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(symbolColor)
                .shadow(color: symbolShadow, radius: 2, x: 0, y: 1)
        }
        .frame(width: 92, height: 92)
        .shadow(color: tileShadow, radius: 10, x: 0, y: 5)
    }

    private var glassSurface: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return shape
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: backgroundGradient),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                shape
                    .fill(highlightFill)
                    .blendMode(.screen)
                    .opacity(isSelected ? 0.30 : 0.20)
            )
            .overlay(
                shape.strokeBorder(innerStrokeColor, lineWidth: 0.8)
            )
            .overlay(
                shape.strokeBorder(borderGradient, lineWidth: isSelected ? 2 : 1.2)
            )
    }

    private var backgroundGradient: [Color] {
        if colorScheme == .dark {
            let top = Color.white.opacity(isSelected ? 0.18 : 0.12)
            let bottom = Color.black.opacity(isSelected ? 0.55 : 0.45)
            return [top, bottom]
        }
        let top = Color.white.opacity(isSelected ? 0.96 : 0.92)
        let bottom = Color(white: 0.90).opacity(isSelected ? 0.4 : 0.32)
        return [top, bottom]
    }

    private var borderGradient: LinearGradient {
        let colors: [Color]
        if isSelected {
            colors = [Color.accentColor.opacity(0.85), Color.accentColor.opacity(0.52)]
        } else if colorScheme == .dark {
            colors = [Color.white.opacity(0.26), Color.white.opacity(0.10)]
        } else {
            colors = [Color.black.opacity(0.18), Color.black.opacity(0.08)]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    private var symbolColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(isSelected ? 0.95 : 0.85)
        }
        return Color.primary.opacity(isSelected ? 0.95 : 0.88)
    }

    private var symbolShadow: Color {
        colorScheme == .dark ? Color.black.opacity(0.40) : Color.black.opacity(0.18)
    }

    private var tileShadow: Color {
        colorScheme == .dark ? Color.black.opacity(0.52) : Color.black.opacity(0.20)
    }

    private var highlightFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.18)
    }

    private var innerStrokeColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(isSelected ? 0.28 : 0.18)
        }
        return Color.white.opacity(isSelected ? 0.35 : 0.20)
    }
}

private struct AboutSettingsView: View {
    @Environment(\.openURL) private var openURL
    private var titleText: String {
        let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Vipinator"
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        return "\(name) \(version)"
    }

    private var copyright: String {
        "© 2025 Vyacheslav Pukhanov. Artem Chebotok. MIT License"
    }

    var body: some View {
        VStack(spacing: 12) {
            AppIconView(iconName: iconAssetName)

            Text(titleText)
                .font(.system(size: 22, weight: .bold))

            Button(action: openProjectPage) {
                Label("Open on GitHub", systemImage: "hand.tap.fill")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(LiquidGlassButtonStyle())

            Text(copyright)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 24)
    }
}

private struct AppIconView: View {
    let iconName: String

    var body: some View {
        Image(iconName)
            .resizable()
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .drawingGroup()
            .frame(width: 96, height: 96)
    }
}

private extension AboutSettingsView {
    func openProjectPage() {
        guard let url = URL(string: "https://github.com/vpukhanov/vipinator/tree/a01beee6b679590b0a4efaa082a148089b982ba8") else { return }
        openURL(url)
    }

    var iconAssetName: String {
        if let explicit = Bundle.main.object(forInfoDictionaryKey: "CFBundleIconName") as? String,
           let trimmed = explicit.nonEmpty {
            return trimmed.replacingOccurrences(of: ".icns", with: "")
        }

        if let fallback = Bundle.main.object(forInfoDictionaryKey: "CFBundleIconFile") as? String,
           let trimmed = fallback.nonEmpty {
            return trimmed.replacingOccurrences(of: ".icns", with: "")
        }

        return "AppIcon"
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        LiquidGlassButton(configuration: configuration)
    }

    private struct LiquidGlassButton: View {
        @Environment(\.colorScheme) private var colorScheme
        let configuration: ButtonStyle.Configuration

        var body: some View {
            configuration.label
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 18)
                .background(background)
                .overlay(border)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.easeInOut(duration: 0.16), value: configuration.isPressed)
        }

        private var foregroundColor: Color {
            colorScheme == .dark ? Color.white.opacity(0.9) : Color.primary
        }

        private var background: some View {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12))
                        .blendMode(.screen)
                        .opacity(configuration.isPressed ? 0.2 : 0.35)
                )
        }

        private var border: some View {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.12)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: configuration.isPressed ? 1.0 : 1.2
                )
        }

        private var gradientColors: [Color] {
            if colorScheme == .dark {
                return configuration.isPressed
                    ? [Color.white.opacity(0.32), Color.white.opacity(0.08)]
                    : [Color.white.opacity(0.25), Color.white.opacity(0.06)]
            } else {
                return configuration.isPressed
                    ? [Color.white.opacity(0.7), Color.white.opacity(0.35)]
                    : [Color.white.opacity(0.6), Color.white.opacity(0.24)]
            }
        }

        private var shadowColor: Color {
            colorScheme == .dark
                ? Color.black.opacity(configuration.isPressed ? 0.35 : 0.45)
                : Color.black.opacity(configuration.isPressed ? 0.2 : 0.26)
        }

        private var shadowRadius: CGFloat { configuration.isPressed ? 4 : 6 }
        private var shadowOffset: CGFloat { configuration.isPressed ? 2 : 4 }
    }
}
