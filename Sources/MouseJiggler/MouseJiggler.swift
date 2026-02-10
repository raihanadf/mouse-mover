import SwiftUI

@main
struct MouseJigglerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Mouse Jiggler") {
                    NSApp.orderFrontStandardAboutPanel()
                }
            }
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var keyboardMonitor: Any?
    var isMenuBarMode = false

    nonisolated func applicationDidFinishLaunching(_: Notification) {
        Task { @MainActor in
            await self.setup()
        }
    }

    private func setup() async {
        self.isMenuBarMode = Settings.shared.isMenuBarMode

        // Setup menu bar icon (always available)
        self.setupMenuBarItem()

        if self.isMenuBarMode {
            // Menu bar mode: hide dock icon
            NSApp.setActivationPolicy(.accessory)
            // Hide the default window initially
            for window in NSApp.windows {
                window.orderOut(nil)
            }
        } else {
            // Regular mode: show dock icon
            NSApp.setActivationPolicy(.regular)
            // Show and focus the window
            for window in NSApp.windows {
                window.makeKeyAndOrderFront(nil)
            }
            NSApp.activate(ignoringOtherApps: true)
        }

        // Setup keyboard shortcut
        self.setupKeyboardShortcut()

        // Request notification permissions
        NSUserNotificationCenter.default.delegate = self
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        // In menu bar mode, keep running when window closes
        !self.isMenuBarMode
    }

    // MARK: - Menu Bar

    private func setupMenuBarItem() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        button.image = NSImage(systemSymbolName: "cursorarrow.motion.lines", accessibilityDescription: "Mouse Jiggler")
        button.action = #selector(self.statusItemClicked)
        button.target = self

        self.setupMenuBarMenu()
    }

    private func setupMenuBarMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Show Mouse Jiggler", action: #selector(self.showMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let toggleItem = NSMenuItem(title: "Start", action: #selector(toggleJiggler), keyEquivalent: "s")
        toggleItem.tag = 100
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(self.showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(self.quitApp), keyEquivalent: "q"))

        self.statusItem?.menu = menu
    }

    @objc private func statusItemClicked() {
        // Show menu on click
        self.statusItem?.button?.performClick(nil)
    }

    @objc private func showMainWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        for window in NSApp.windows {
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func toggleJiggler() {
        NotificationCenter.default.post(name: .toggleJiggler, object: nil)
    }

    @objc private func showSettings() {
        // First ensure window is visible
        self.showMainWindow()
        // Then show settings
        NotificationCenter.default.post(name: .showSettings, object: nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Keyboard Shortcut

    private func setupKeyboardShortcut() {
        guard Settings.shared.enableKeyboardShortcut else { return }

        let keyMask: NSEvent.ModifierFlags = [.option, .command]

        self.keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 38, // 'J' key
               event.modifierFlags.contains(keyMask)
            {
                NotificationCenter.default.post(name: .toggleJiggler, object: nil)
            }
        }
    }
}

// MARK: - NSUserNotificationCenterDelegate

extension AppDelegate: NSUserNotificationCenterDelegate {
    @available(macOS, deprecated: 11.0)
    nonisolated func userNotificationCenter(_: NSUserNotificationCenter, shouldPresent _: NSUserNotification) -> Bool {
        true
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let toggleJiggler = Notification.Name("toggleJiggler")
    static let showSettings = Notification.Name("showSettings")
}
