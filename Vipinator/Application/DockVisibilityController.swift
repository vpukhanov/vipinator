#if os(macOS)
import Foundation
import ApplicationServices

enum DockVisibilityController {
    private static var activeSettingsWindows = 0
    private static var isAccessory = false

    static func configureForLaunch() {
        DispatchQueue.main.async {
            transformToAccessoryIfNeeded()
        }
    }

    static func settingsWindowDidAppear() {
        DispatchQueue.main.async {
            activeSettingsWindows += 1
            transformToForeground()
        }
    }

    static func settingsWindowDidDisappear() {
        DispatchQueue.main.async {
            guard activeSettingsWindows > 0 else { return }
            activeSettingsWindows -= 1
            guard activeSettingsWindows == 0 else { return }
            transformToAccessoryIfNeeded()
        }
    }

    private static func transformToForeground() {
        var psn = currentProcess()
        TransformProcessType(&psn, ProcessApplicationTransformState(kProcessTransformToForegroundApplication))
        isAccessory = false
    }

    private static func transformToAccessoryIfNeeded() {
        guard !isAccessory else { return }
        var psn = currentProcess()
        let status = TransformProcessType(&psn, ProcessApplicationTransformState(kProcessTransformToUIElementApplication))
        if status == noErr {
            isAccessory = true
        }
    }

    private static func currentProcess() -> ProcessSerialNumber {
        var psn = ProcessSerialNumber()
        GetCurrentProcess(&psn)
        return psn
    }
}
#endif
