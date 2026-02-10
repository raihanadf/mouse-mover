import Foundation

/// App settings managed via UserDefaults
@MainActor
final class Settings: ObservableObject {
    static let shared = Settings()

    private let defaults = UserDefaults.standard

    // MARK: - Published Settings

    @Published var idleThresholdMinutes: Double {
        didSet { self.defaults.set(self.idleThresholdMinutes, forKey: Keys.idleThresholdMinutes) }
    }

    @Published var moveIntervalSeconds: Double {
        didSet { self.defaults.set(self.moveIntervalSeconds, forKey: Keys.moveIntervalSeconds) }
    }

    @Published var launchAtLogin: Bool {
        didSet { self.defaults.set(self.launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @Published var showNotifications: Bool {
        didSet { self.defaults.set(self.showNotifications, forKey: Keys.showNotifications) }
    }

    @Published var enableKeyboardShortcut: Bool {
        didSet { self.defaults.set(self.enableKeyboardShortcut, forKey: Keys.enableKeyboardShortcut) }
    }

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let idleThresholdMinutes = "idleThresholdMinutes"
        static let moveIntervalSeconds = "moveIntervalSeconds"
        static let launchAtLogin = "launchAtLogin"
        static let showNotifications = "showNotifications"
        static let enableKeyboardShortcut = "enableKeyboardShortcut"
    }

    // MARK: - Computed Properties

    var idleThresholdSeconds: TimeInterval {
        self.idleThresholdMinutes * 60
    }

    // MARK: - Initialization

    private init() {
        let defaults: [String: Any] = [
            Keys.idleThresholdMinutes: 0.5, // 30 seconds
            Keys.moveIntervalSeconds: 10.0,
            Keys.launchAtLogin: false,
            Keys.showNotifications: true,
            Keys.enableKeyboardShortcut: true,
        ]
        self.defaults.register(defaults: defaults)

        self.idleThresholdMinutes = self.defaults.double(forKey: Keys.idleThresholdMinutes)
        self.moveIntervalSeconds = self.defaults.double(forKey: Keys.moveIntervalSeconds)
        self.launchAtLogin = self.defaults.bool(forKey: Keys.launchAtLogin)
        self.showNotifications = self.defaults.bool(forKey: Keys.showNotifications)
        self.enableKeyboardShortcut = self.defaults.bool(forKey: Keys.enableKeyboardShortcut)
    }

    // MARK: - Reset

    func resetToDefaults() {
        self.idleThresholdMinutes = 0.5
        self.moveIntervalSeconds = 10.0
        self.launchAtLogin = false
        self.showNotifications = true
        self.enableKeyboardShortcut = true
    }
}
