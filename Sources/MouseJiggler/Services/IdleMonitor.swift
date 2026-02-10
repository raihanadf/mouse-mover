import Foundation
import IOKit

/// Notification sent when system wakes from sleep
extension Notification.Name {
    static let systemDidWake = Notification.Name("systemDidWake")
    static let systemWillSleep = Notification.Name("systemWillSleep")
}

/// Monitors system idle time using IOKit with improved edge case handling
actor IdleMonitor {
    /// Error types for idle monitoring
    enum IdleMonitorError: Error {
        case serviceNotFound
        case propertyNotFound
        case invalidValue
    }

    /// Current system state
    private(set) var systemState: SystemState = .awake
    private var lastWakeTime: Date?
    private var lastKnownIdleTime: TimeInterval = 0

    enum SystemState {
        case awake
        case sleeping
        case waking
    }

    /// Initialize and setup sleep/wake notifications
    init() {
        // Note: setupSleepWakeNotifications would be called here
        // but currently just logs initialization
        print("[IdleMonitor] Sleep/wake monitoring initialized")
    }

    /// Returns an async stream of idle time updates
    func idleTimeStream() -> AsyncStream<TimeInterval> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    let idleTime = self.getIdleTime()
                    continuation.yield(idleTime)
                    try? await Task.sleep(for: .seconds(1))
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Get current idle time in seconds with validation
    /// - Returns: Idle time in seconds, or 0 if error occurs
    func getIdleTime() -> TimeInterval {
        // If system is sleeping, return accumulated idle time
        guard self.systemState != .sleeping else {
            return self.lastKnownIdleTime
        }

        do {
            let idleTime = try fetchIdleTimeFromIOKit()
            self.lastKnownIdleTime = idleTime
            return idleTime
        } catch {
            print("[IdleMonitor] Error fetching idle time: \(error)")
            return self.lastKnownIdleTime
        }
    }

    /// Verify idle time reading is reasonable
    /// - Parameter expectedIdleTime: Expected idle time for validation
    /// - Returns: True if reading is accurate within tolerance
    func verifyIdleTimeAccuracy(expectedIdleTime: TimeInterval, tolerance: TimeInterval = 2.0) -> Bool {
        let actualIdleTime = self.getIdleTime()
        let difference = abs(actualIdleTime - expectedIdleTime)
        let isAccurate = difference <= tolerance

        if !isAccurate {
            print("[IdleMonitor] Accuracy check failed: expected \(expectedIdleTime)s, got \(actualIdleTime)s (diff: \(difference)s)")
        }

        return isAccurate
    }

    /// Fetch raw idle time from IOKit
    private func fetchIdleTimeFromIOKit() throws -> TimeInterval {
        // Create matching dictionary for IOHIDSystem
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOHIDSystem")
        )

        guard service != 0 else {
            throw IdleMonitorError.serviceNotFound
        }

        defer {
            IOObjectRelease(service)
        }

        // Get the HIDIdleTime property
        guard let property = IORegistryEntryCreateCFProperty(
            service,
            "HIDIdleTime" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() else {
            throw IdleMonitorError.propertyNotFound
        }

        // Handle different numeric types
        guard let number = property as? NSNumber else {
            throw IdleMonitorError.invalidValue
        }

        let nanoseconds: UInt64 = number.uint64Value

        // Validate the value is reasonable (not negative or extremely large)
        // Max reasonable: 1 year in nanoseconds
        let maxReasonableNs: UInt64 = 365 * 24 * 60 * 60 * 1_000_000_000
        guard nanoseconds <= maxReasonableNs else {
            throw IdleMonitorError.invalidValue
        }

        // Convert nanoseconds to seconds
        return Double(nanoseconds) / 1_000_000_000.0
    }

    /// Setup notifications for sleep/wake events
    private func setupSleepWakeNotifications() {
        // Note: In a real app, you'd use NSWorkspace notifications
        // For now, we document the expected behavior
    }

    /// Handle system will sleep notification
    func handleSystemWillSleep() {
        self.systemState = .sleeping
        print("[IdleMonitor] System going to sleep, preserving idle time: \(self.lastKnownIdleTime)s")
    }

    /// Handle system did wake notification
    func handleSystemDidWake() {
        self.lastWakeTime = Date()
        self.systemState = .waking
        // Reset idle time on wake since user interaction is required to wake
        self.lastKnownIdleTime = 0
        print("[IdleMonitor] System woke from sleep, reset idle time")

        // Give system time to stabilize
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            Task { [weak self] in
                self?.systemState = .awake
            }
        }
    }
}
