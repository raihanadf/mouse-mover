import SwiftUI

@main
struct MouseJigglerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            EmptyView()
                .hidden()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var keyboardMonitor: Any?

    @Published var isJigglerActive = false

    nonisolated func applicationDidFinishLaunching(_: Notification) {
        Task { @MainActor in
            self.setup()
        }
    }

    private func setup() {
        // Setup menu bar
        self.setupMenuBar()

        // Setup keyboard shortcut
        self.setupKeyboardShortcut()

        // Don't show dock icon
        NSApp.setActivationPolicy(.accessory)
    }

    private func setupMenuBar() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        // Use a proper mouse cursor icon
        button.image = NSImage(systemSymbolName: "cursorarrow.click.2", accessibilityDescription: "Mouse Jiggler")
        button.action = #selector(self.togglePopover)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        // Create popover with SwiftUI view
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView().environmentObject(self))
        self.popover = popover
    }

    @objc private func togglePopover() {
        if let button = statusItem?.button {
            if self.popover?.isShown == true {
                self.popover?.performClose(nil)
            } else {
                self.popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    @objc func toggleJiggler() {
        self.isJigglerActive.toggle()

        // Post notification to controller
        NotificationCenter.default.post(name: .toggleJiggler, object: self.isJigglerActive)
    }

    func quitApp() {
        NSApp.terminate(nil)
    }

    private func setupKeyboardShortcut() {
        guard Settings.shared.enableKeyboardShortcut else { return }

        let keyMask: NSEvent.ModifierFlags = [.option, .command]

        self.keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 38, // 'J' key
               event.modifierFlags.contains(keyMask)
            {
                Task { @MainActor in
                    self?.toggleJiggler()
                }
            }
        }
    }
}

// MARK: - Menu Bar View

struct MenuBarView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @ObservedObject var settings = Settings.shared
    @ObservedObject var jiggler = JigglerController.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header with toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mouse Jiggler")
                        .font(.system(size: 16, weight: .semibold))
                    HStack(spacing: 6) {
                        Circle()
                            .fill(self.jiggler.isActive ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(self.jiggler.isActive ? "Active" : "Inactive")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Keyboard shortcut indicator
                HStack(spacing: 4) {
                    Text("⌃⌥J")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)

                    // Toggle switch
                    Toggle("", isOn: Binding(
                        get: { self.jiggler.isActive },
                        set: { _ in self.appDelegate.toggleJiggler() }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .labelsHidden()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    // Timing Section
                    Card {
                        VStack(alignment: .leading, spacing: 16) {
                            // Start Moving After
                            HStack {
                                Text("Start Moving After")
                                    .font(.system(size: 14))
                                Spacer()
                                Menu {
                                    ForEach([10, 30, 60, 120, 300, 600], id: \.self) { seconds in
                                        Button("\(seconds / 60 > 0 ? "\(seconds / 60) min" : "\(seconds) sec")") {
                                            self.settings.idleThresholdMinutes = Double(seconds) / 60.0
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("\(Int(self.settings.idleThresholdMinutes * 60)) sec")
                                            .font(.system(size: 13, weight: .medium))
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue)
                                    .cornerRadius(6)
                                }
                                .menuStyle(BorderlessButtonMenuStyle())
                            }

                            // Move Every
                            HStack {
                                Text("Move Every")
                                    .font(.system(size: 14))
                                Spacer()
                                Menu {
                                    ForEach([5, 10, 30, 60], id: \.self) { seconds in
                                        Button("\(seconds) sec") {
                                            self.settings.moveIntervalSeconds = Double(seconds)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("\(Int(self.settings.moveIntervalSeconds)) sec")
                                            .font(.system(size: 13, weight: .medium))
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue)
                                    .cornerRadius(6)
                                }
                                .menuStyle(BorderlessButtonMenuStyle())
                            }
                        }
                    }

                    // Options Section
                    Card {
                        VStack(spacing: 0) {
                            ToggleRow(title: "Show Notifications", isOn: self.$settings.showNotifications)
                            Divider().padding(.leading, 32)
                            ToggleRow(title: "Launch at Login", isOn: self.$settings.launchAtLogin)
                        }
                    }

                    // Current Status
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Status")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)

                            HStack {
                                StatItem(icon: "clock", value: self.jiggler.formattedIdleTime, label: "Idle Time")
                                Spacer()
                                StatItem(icon: "cursorarrow", value: self.jiggler.formattedLastJiggleTime, label: "Last Move")
                            }
                        }
                    }

                    Spacer(minLength: 8)

                    // Quit Button
                    Button(action: {
                        self.appDelegate.quitApp()
                    }) {
                        Text("Quit")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    // Version
                    Text("Mouse Jiggler v1.0")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(12)
            }
        }
        .frame(width: 340, height: 400)
    }
}

// MARK: - Card Component

struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        self.content
            .padding(14)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(10)
    }
}

// MARK: - Toggle Row

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(self.title)
                .font(.system(size: 14))
            Spacer()
            Toggle("", isOn: self.$isOn)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: self.icon)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(self.label)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Text(self.value)
                .font(.system(size: 13, weight: .medium))
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let toggleJiggler = Notification.Name("toggleJiggler")
}
