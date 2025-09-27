import SwiftUI
import Carbon.HIToolbox

struct HotkeyRecorderView: View {
    @Binding var displayText: String
    var onCommit: (UInt32?, UInt32?) -> Void

    @State private var isRecording = false
    @State private var recorder = HotkeyEventRecorder()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let rightPadding: CGFloat = 6
            let leftPadding: CGFloat = 12
            let clearButtonSize: CGFloat = (!isRecording && displayText != "Record") ? 18 : 0
            let availableWidth = totalWidth - leftPadding - rightPadding - clearButtonSize

            ZStack(alignment: .leading) {
                Text(labelText)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.primary)
                    .frame(width: availableWidth, alignment: .center)
                    .position(x: leftPadding + availableWidth / 2, y: proxy.size.height / 2)

                if !isRecording && displayText != "Record" {
                    Button {
                        onCommit(nil, nil)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear shortcut")
                    .frame(width: clearButtonSize, height: clearButtonSize)
                    .position(x: totalWidth - rightPadding - clearButtonSize / 2,
                              y: proxy.size.height / 2)
                }
            }
        }
        .frame(height: 28)
        .background(glassBackground)
        .overlay(glassBorder)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: shadowColor, radius: isRecording ? 4 : 6, x: 0, y: isRecording ? 1 : 3)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isRecording, displayText == "Record" else { return }
            beginRecording()
        }
        .onDisappear {
            recorder.stop()
            isRecording = false
        }
        .animation(.easeInOut(duration: 0.2), value: isRecording)
    }

    private var labelText: String {
        isRecording ? "Press" : displayText
    }

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.14))
                    .blendMode(.screen)
                    .opacity(isRecording ? 0.35 : 0.25)
            )
    }

    private var glassBorder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: borderColors,
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: isRecording ? 2 : 1.2
            )
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return isRecording
                ? [Color.white.opacity(0.25), Color.white.opacity(0.10)]
                : [Color.white.opacity(0.20), Color.white.opacity(0.06)]
        } else {
            return isRecording
                ? [Color.white.opacity(0.70), Color.white.opacity(0.42)]
                : [Color.white.opacity(0.60), Color.white.opacity(0.30)]
        }
    }

    private var borderColors: [Color] {
        if isRecording {
            return [Color.accentColor.opacity(0.9), Color.accentColor.opacity(0.6)]
        }
        return [Color.white.opacity(0.45), Color.white.opacity(0.16)]
    }

    private var shadowColor: Color {
        if colorScheme == .dark {
            return Color.black.opacity(isRecording ? 0.45 : 0.5)
        }
        return Color.black.opacity(isRecording ? 0.18 : 0.24)
    }

    private func beginRecording() {
        guard !isRecording else { return }
        guard displayText == "Record" else { return }
        isRecording = true

        recorder.start(
            onCapture: { keyCode, modifiers in
                isRecording = false
                onCommit(keyCode, modifiers)
            },
            onCancel: {
                isRecording = false
            }
        )
    }
}

@MainActor
private final class HotkeyEventRecorder {
    private var localKeyMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var onCapture: ((UInt32, UInt32) -> Void)?
    private var onCancel: (() -> Void)?

    func start(onCapture: @escaping (UInt32, UInt32) -> Void, onCancel: @escaping () -> Void) {
        stop()

        self.onCapture = onCapture
        self.onCancel = onCancel

        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.handleKey(event: event)
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else { return event }
            return self.handleKey(event: event) ? nil : event
        }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            self?.cancelAsync()
        }

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            self?.cancelAsync()
            return event
        }
    }

    func stop() {
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }

        globalKeyMonitor = nil
        localKeyMonitor = nil
        globalMouseMonitor = nil
        localMouseMonitor = nil
        onCapture = nil
        onCancel = nil
    }

    @discardableResult
    private func handleKey(event: NSEvent) -> Bool {
        let keyCode = UInt32(event.keyCode)

        if keyCode == UInt32(kVK_Escape) {
            DispatchQueue.main.async { self.cancel() }
            return true
        }

        let modifiers = event.modifierFlags.carbonModifiers
        guard modifiers != 0 else {
            return true
        }

        DispatchQueue.main.async {
            self.finish(code: keyCode, modifiers: modifiers)
        }

        return true
    }

    private func cancelAsync() {
        DispatchQueue.main.async {
            self.cancel()
        }
    }

    private func finish(code: UInt32, modifiers: UInt32) {
        let callback = onCapture
        stop()
        callback?(code, modifiers)
    }

    private func cancel() {
        let handler = onCancel
        stop()
        handler?()
    }
}

private extension NSEvent.ModifierFlags {
    var carbonModifiers: UInt32 {
        let flags = intersection(.deviceIndependentFlagsMask)
        var value: UInt32 = 0
        if flags.contains(.command) { value |= UInt32(cmdKey) }
        if flags.contains(.option) { value |= UInt32(optionKey) }
        if flags.contains(.shift) { value |= UInt32(shiftKey) }
        if flags.contains(.control) { value |= UInt32(controlKey) }
        return value
    }
}
