import Cocoa
import CoreGraphics

/// Checks and requests accessibility permissions
actor AccessibilityChecker {
    /// Check if accessibility permissions are granted
    static func checkPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Request accessibility permissions (shows system dialog)
    static func requestPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Open System Settings to Privacy & Security > Accessibility
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Get detailed permission status
    static func getPermissionStatus() -> PermissionStatus {
        let isTrusted = self.checkPermissions()
        return PermissionStatus(
            isGranted: isTrusted,
            canControlMouse: self.canControlMouse(),
            canMonitorInput: self.canMonitorInput()
        )
    }

    /// Test if we can actually control the mouse
    private static func canControlMouse() -> Bool {
        guard self.checkPermissions() else { return false }

        // Try to get current position (read-only test)
        let event = CGEvent(source: nil)
        return event != nil
    }

    /// Test if we can monitor input
    private static func canMonitorInput() -> Bool {
        // This requires additional permissions beyond basic accessibility
        // For now, just return the main permission status
        self.checkPermissions()
    }
}

/// Permission status details
struct PermissionStatus {
    let isGranted: Bool
    let canControlMouse: Bool
    let canMonitorInput: Bool

    var description: String {
        if self.isGranted, self.canControlMouse {
            "✅ All permissions granted"
        } else if self.isGranted {
            "⚠️ Partial permissions"
        } else {
            "❌ Permissions required"
        }
    }
}
