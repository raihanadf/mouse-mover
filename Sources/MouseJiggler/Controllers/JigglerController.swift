import Combine
import CoreGraphics
import Foundation

/// Main controller that manages the jiggler state and coordination
@MainActor
final class JigglerController: ObservableObject {
    // MARK: - Singleton

    static let shared = JigglerController()

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

    private init() {
        self.setupIdleMonitoring()
        self.setupNotifications()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleToggle),
            name: .toggleJiggler,
            object: nil
        )
    }

    @objc private func handleToggle() {
        self.toggle()
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
        guard AccessibilityChecker.checkPermissions() else {
            AccessibilityChecker.requestPermissions()
            return
        }

        self.isActive = true
        self.state = .monitoring
        self.lastMousePosition = self.getCurrentMousePosition()
        self.timeMouseHasBeenStill = 0
        self.isUserActivelyMovingMouse = false
        self.startTimer()

        if self.settings.showNotifications {
            self.showNotification(title: "Mouse Jiggler", message: "Started")
        }
        print("[Jiggler] Started")
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

        self.checkMouseActivity()

        let idleThreshold = self.settings.idleThresholdSeconds
        let moveInterval = self.settings.moveIntervalSeconds

        switch self.state {
        case .monitoring:
            if self.idleTime >= idleThreshold,
               self.timeMouseHasBeenStill >= idleThreshold,
               !self.isUserActivelyMovingMouse
            {
                print("[Jiggler] Idle threshold reached, starting movement")
                self.state = .jiggling
                if self.settings.showNotifications {
                    self.showNotification(title: "Mouse Jiggler", message: "Moving cursor - you were idle")
                }
                self.performJiggle()
            }

        case .jiggling:
            if self.idleTime < 2 {
                print("[Jiggler] User is active, pausing")
                self.state = .monitoring
                self.timeMouseHasBeenStill = self.idleTime
                if self.settings.showNotifications {
                    self.showNotification(title: "Mouse Jiggler", message: "Paused - user active")
                }
            } else {
                let timeSinceLastJiggle = Date().timeIntervalSince(self.lastJiggleTime ?? .distantPast)
                if timeSinceLastJiggle >= moveInterval {
                    self.performJiggle()
                }
            }

        case .idle:
            break
        }
    }

    private func checkMouseActivity() {
        guard let currentPos = getCurrentMousePosition() else { return }

        if let lastJiggle = lastJiggleCompletionTime,
           Date().timeIntervalSince(lastJiggle) < 1.0
        {
            self.lastMousePosition = currentPos
            return
        }

        if let lastPos = lastMousePosition {
            let distance = hypot(currentPos.x - lastPos.x, currentPos.y - lastPos.y)

            if distance > self.positionCheckThreshold {
                self.isUserActivelyMovingMouse = true
                self.timeMouseHasBeenStill = 0
            } else {
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
            self.lastMousePosition = self.getCurrentMousePosition()
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
