import Combine
import CoreGraphics
import Foundation

/// Main controller that manages the jiggler state and coordination
@MainActor
final class JigglerController: ObservableObject {
    // MARK: - Published States

    @Published var isActive: Bool = false
    @Published var idleTime: TimeInterval = 0
    @Published var lastJiggleTime: Date?

    // MARK: - Constants

    private let positionCheckThreshold: CGFloat = 5 // Min pixels moved to count as activity

    // MARK: - Dependencies

    private let idleMonitor = IdleMonitor()
    private let mouseController = MouseController()
    private let settings = Settings.shared

    // MARK: - Internal State

    private var timer: Timer?
    private var state: JigglerState = .idle
    private var lastMousePosition: CGPoint?
    private var timeMouseHasBeenStill: TimeInterval = 0
    private var isUserActivelyMovingMouse = false
    private var lastJiggleCompletionTime: Date?

    enum JigglerState {
        case idle // Not active, monitoring
        case monitoring // Active, waiting for idle threshold
        case jiggling // Active and jiggling
    }

    // MARK: - Computed Properties

    var formattedIdleTime: String {
        let minutes = Int(idleTime) / 60
        let seconds = Int(idleTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedLastJiggleTime: String {
        guard let lastTime = lastJiggleTime else {
            return "Never"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastTime, relativeTo: Date())
    }

    // MARK: - Initialization

    init() {
        self.setupIdleMonitoring()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Public Methods

    func toggle() {
        if self.isActive {
            self.stop()
        } else {
            self.start()
        }
    }

    func start() {
        self.isActive = true
        self.state = .monitoring
        self.lastMousePosition = self.getCurrentMousePosition()
        self.timeMouseHasBeenStill = 0
        self.isUserActivelyMovingMouse = false
        self.startTimer()

        if self.settings.showNotifications {
            self.showNotification(title: "Mouse Jiggler", message: "Started monitoring for idle time")
        }
        print("[Jiggler] Started - monitoring for idle time")
    }

    func stop() {
        self.isActive = false
        self.state = .idle
        self.stopTimer()

        if self.settings.showNotifications {
            self.showNotification(title: "Mouse Jiggler", message: "Stopped")
        }
        print("[Jiggler] Stopped")
    }

    // MARK: - Private Methods

    private func setupIdleMonitoring() {
        Task {
            for await newIdleTime in await self.idleMonitor.idleTimeStream() {
                self.idleTime = newIdleTime
            }
        }
    }

    private func startTimer() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }

    private func tick() {
        guard self.isActive else { return }

        // Check if user is actively moving the mouse by tracking position changes
        self.checkMouseActivity()

        let idleThreshold = self.settings.idleThresholdSeconds
        let moveInterval = self.settings.moveIntervalSeconds

        switch self.state {
        case .monitoring:
            // Only start jiggling if:
            // 1. System reports idle time >= threshold
            // 2. Mouse has been still for >= threshold
            // 3. User is not actively moving mouse
            if self.idleTime >= idleThreshold,
               self.timeMouseHasBeenStill >= idleThreshold,
               !self.isUserActivelyMovingMouse
            {
                print("[Jiggler] Idle threshold reached (system: \(Int(self.idleTime))s, still: \(Int(self.timeMouseHasBeenStill))s), starting jiggle mode")
                self.state = .jiggling
                if self.settings.showNotifications {
                    self.showNotification(title: "Mouse Jiggler", message: "Cursor moving - you were idle for \(Int(idleThreshold))s")
                }
                self.performJiggle()
            }

        case .jiggling:
            // Stop jiggling if user becomes active
            // User is active if system idle time drops below 2 seconds
            // We ignore isUserActivelyMovingMouse here because our own jiggle sets it to true
            if self.idleTime < 2 {
                print("[Jiggler] User is active (system idle: \(Int(self.idleTime))s), pausing jiggle mode")
                self.state = .monitoring
                self.timeMouseHasBeenStill = self.idleTime
                if self.settings.showNotifications {
                    self.showNotification(title: "Mouse Jiggler", message: "Paused - user is active")
                }
            } else {
                // Continue jiggling if enough time has passed since last jiggle
                let timeSinceLastJiggle = Date().timeIntervalSince(self.lastJiggleTime ?? .distantPast)
                if timeSinceLastJiggle >= moveInterval {
                    self.performJiggle()
                }
            }

        case .idle:
            break
        }
    }

    /// Check if user is actively moving the mouse by comparing positions
    private func checkMouseActivity() {
        guard let currentPos = getCurrentMousePosition() else { return }

        // Ignore position checks right after we completed a jiggle (within 1 second)
        // This prevents us from detecting our own jiggle as user activity
        if let lastJiggle = lastJiggleCompletionTime,
           Date().timeIntervalSince(lastJiggle) < 1.0
        {
            self.lastMousePosition = currentPos
            return
        }

        if let lastPos = lastMousePosition {
            let distance = hypot(currentPos.x - lastPos.x, currentPos.y - lastPos.y)

            if distance > self.positionCheckThreshold {
                // Mouse moved significantly - user is active!
                self.isUserActivelyMovingMouse = true
                self.timeMouseHasBeenStill = 0
                print("[Jiggler] Detected mouse movement: \(Int(distance))px")
            } else {
                // Mouse is still
                self.isUserActivelyMovingMouse = false
                self.timeMouseHasBeenStill += 1
            }
        }

        self.lastMousePosition = currentPos
    }

    private func getCurrentMousePosition() -> CGPoint? {
        let event = CGEvent(source: nil)
        return event?.location
    }

    private func performJiggle() {
        Task {
            self.lastJiggleTime = Date()
            await self.mouseController.jiggle()
            self.lastJiggleCompletionTime = Date()
            // After jiggling, update lastMousePosition to the new position
            // so we don't detect our own movement as user activity
            self.lastMousePosition = self.getCurrentMousePosition()
            print("[Jiggler] Mouse moved at \(Date())")
        }
    }

    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = nil
        NSUserNotificationCenter.default.deliver(notification)
    }
}
