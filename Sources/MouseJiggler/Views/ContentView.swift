import SwiftUI

struct ContentView: View {
    @StateObject private var jiggler = JigglerController()
    @State private var showDebugView = false
    @State private var showPermissionAlert = false
    @State private var showSettingsView = false

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "cursorarrow.motion.lines")
                    .font(.system(size: 64))
                    .foregroundColor(self.jiggler.isActive ? .green : .gray)
                    .opacity(self.jiggler.isActive ? 1.0 : 0.5)

                Text("Mouse Jiggler")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Moves cursor to random positions")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 16)

            Divider()
                .padding(.horizontal, 32)

            // Status Section
            VStack(alignment: .leading, spacing: 16) {
                StatusRow(
                    icon: "power.circle.fill",
                    title: "Status",
                    value: self.jiggler.isActive ? "Active" : "Inactive",
                    color: self.jiggler.isActive ? .green : .red
                )

                StatusRow(
                    icon: "clock.arrow.circlepath",
                    title: "Idle Time",
                    value: self.jiggler.formattedIdleTime,
                    color: .blue
                )

                StatusRow(
                    icon: "cursorarrow",
                    title: "Last Move",
                    value: self.jiggler.formattedLastJiggleTime,
                    color: .orange
                )
            }
            .padding(.horizontal, 40)

            Spacer()

            // Main Toggle Button
            Button(action: {
                if !AccessibilityChecker.checkPermissions(), !self.jiggler.isActive {
                    self.showPermissionAlert = true
                    AccessibilityChecker.requestPermissions()
                } else {
                    self.jiggler.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: self.jiggler.isActive ? "stop.fill" : "play.fill")
                        .font(.title3)
                    Text(self.jiggler.isActive ? "Stop" : "Start")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(self.jiggler.isActive ? Color.red : Color.green)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)

            // Settings & Info
            VStack(spacing: 12) {
                Button("Settings...") {
                    self.showSettingsView = true
                }
                .font(.body)
                .buttonStyle(.link)

                Text("Idle: \(Int(Settings.shared.idleThresholdMinutes * 60))s | Interval: \(Int(Settings.shared.moveIntervalSeconds))s")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Debug") {
                    self.showDebugView = true
                }
                .font(.caption)
                .buttonStyle(.link)
                .foregroundColor(.gray)
            }
            .padding(.bottom, 16)
        }
        .frame(width: 480, height: 520)
        .sheet(isPresented: self.$showDebugView) {
            DebugView()
        }
        .sheet(isPresented: self.$showSettingsView) {
            SettingsView()
        }
        .alert("Accessibility Permissions Required", isPresented: self.$showPermissionAlert) {
            Button("Open Settings") {
                AccessibilityChecker.openAccessibilitySettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Mouse Jiggler needs accessibility permissions to control the cursor. Please enable it in System Settings.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleJiggler)) { _ in
            if AccessibilityChecker.checkPermissions() {
                self.jiggler.toggle()
            } else {
                self.showPermissionAlert = true
                AccessibilityChecker.requestPermissions()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSettings)) { _ in
            self.showSettingsView = true
        }
    }
}

struct StatusRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: self.icon)
                .foregroundColor(self.color)
                .font(.title3)
                .frame(width: 32)

            Text(self.title)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            Text(self.value)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}
