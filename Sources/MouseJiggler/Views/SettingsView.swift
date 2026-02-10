import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header with Done button
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    self.dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()
                .padding(.horizontal, 24)

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Timing Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Timing")
                            .font(.headline)
                            .foregroundColor(.primary)

                        // Idle Threshold
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Idle Threshold")
                                    .font(.body)
                                Spacer()
                                Text("\(Int(self.settings.idleThresholdMinutes * 60)) seconds")
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .monospaced))
                            }
                            Slider(
                                value: self.$settings.idleThresholdMinutes,
                                in: 0.1 ... 60,
                                step: 0.5
                            )
                            HStack {
                                Text("6s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("60m")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Move Interval
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Move Interval")
                                    .font(.body)
                                Spacer()
                                Text("\(Int(self.settings.moveIntervalSeconds)) seconds")
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .monospaced))
                            }
                            Slider(
                                value: self.$settings.moveIntervalSeconds,
                                in: 1 ... 60,
                                step: 1
                            )
                            HStack {
                                Text("1s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("60s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()

                    // Appearance Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Appearance")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Toggle("Menu Bar Mode (no dock icon)", isOn: self.$settings.isMenuBarMode)
                            .font(.body)
                            .onChange(of: self.settings.isMenuBarMode) { _ in
                                self.relaunchApp()
                            }

                        Text("App will relaunch automatically")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Behavior Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Behavior")
                            .font(.headline)
                            .foregroundColor(.primary)

                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Launch at Login", isOn: self.$settings.launchAtLogin)
                                .font(.body)

                            Toggle("Show Notifications", isOn: self.$settings.showNotifications)
                                .font(.body)

                            Toggle("Enable Keyboard Shortcut (⌥⌘J)", isOn: self.$settings.enableKeyboardShortcut)
                                .font(.body)
                        }
                    }

                    // Reset Button
                    Button("Reset to Defaults") {
                        self.settings.resetToDefaults()
                    }
                    .buttonStyle(.link)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
                }
                .padding(24)
            }
        }
        .frame(width: 480, height: 600)
    }

    private func relaunchApp() {
        // Get the path to the executable
        let appPath = Bundle.main.bundlePath

        // Create a script to relaunch after a short delay
        let script = """
        sleep 0.5
        open "\(appPath)"
        """

        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", script]
        try? task.run()

        // Terminate current instance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApplication.shared.terminate(nil)
        }
    }
}
