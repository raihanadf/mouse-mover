import SwiftUI

/// Debug view for testing idle detection accuracy
struct DebugView: View {
    @StateObject private var monitor = IdleDebugMonitor()
    @State private var testStartTime: Date?
    @State private var expectedIdleTime: TimeInterval = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Idle Detection Debug")
                .font(.title)
                .fontWeight(.bold)

            Divider()

            // Current readings
            Group {
                Text("Current Readings")
                    .font(.headline)

                StatRow(label: "System Idle Time", value: "\(String(format: "%.2f", self.monitor.systemIdleTime))s")
                StatRow(label: "Calculated Idle Time", value: "\(String(format: "%.2f", self.monitor.calculatedIdleTime))s")
                StatRow(label: "Last Update", value: self.monitor.lastUpdateTime)
            }

            Divider()

            // Accuracy test
            Group {
                Text("Accuracy Test")
                    .font(.headline)

                if let startTime = testStartTime {
                    let elapsed = Date().timeIntervalSince(startTime)
                    StatRow(label: "Test Duration", value: "\(String(format: "%.1f", elapsed))s")
                    StatRow(label: "Expected Idle", value: "\(String(format: "%.1f", self.expectedIdleTime))s")
                    StatRow(label: "Difference", value: "\(String(format: "%.2f", abs(elapsed - self.monitor.systemIdleTime)))s")

                    Button("Stop Test") {
                        self.testStartTime = nil
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Start 30s Accuracy Test") {
                        self.testStartTime = Date()
                        self.expectedIdleTime = 30
                    }
                    .buttonStyle(.bordered)
                }
            }

            Divider()

            // Edge case info
            Group {
                Text("Edge Case Handling")
                    .font(.headline)

                StatRow(label: "System State", value: self.monitor.systemState)
                StatRow(label: "Last Wake Time", value: self.monitor.lastWakeTime ?? "N/A")
                StatRow(label: "Consecutive Errors", value: "\(self.monitor.errorCount)")
            }

            Spacer()

            Button("Close") {
                // Dismiss handled by parent
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(self.label)
                .foregroundColor(.secondary)
            Spacer()
            Text(self.value)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
}

/// Monitor for debugging idle detection
@MainActor
class IdleDebugMonitor: ObservableObject {
    @Published var systemIdleTime: TimeInterval = 0
    @Published var calculatedIdleTime: TimeInterval = 0
    @Published var lastUpdateTime: String = "Never"
    @Published var systemState: String = "Unknown"
    @Published var lastWakeTime: String?
    @Published var errorCount: Int = 0

    private let idleMonitor = IdleMonitor()
    private var timer: Timer?
    private var lastMousePosition: CGPoint?
    private var mouseStillTime: TimeInterval = 0

    init() {
        self.startMonitoring()
    }

    deinit {
        timer?.invalidate()
    }

    private func startMonitoring() {
        // Monitor system idle time
        Task {
            for await idleTime in await self.idleMonitor.idleTimeStream() {
                await MainActor.run {
                    self.systemIdleTime = idleTime
                    self.lastUpdateTime = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
                }
            }
        }

        // Calculate our own idle time based on mouse position
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCalculatedIdleTime()
        }
    }

    private func updateCalculatedIdleTime() {
        guard let currentPos = getCurrentMousePosition() else { return }

        if let lastPos = lastMousePosition {
            let distance = hypot(currentPos.x - lastPos.x, currentPos.y - lastPos.y)
            if distance < 5 {
                self.mouseStillTime += 1
            } else {
                self.mouseStillTime = 0
            }
        }

        self.lastMousePosition = currentPos
        self.calculatedIdleTime = self.mouseStillTime
    }

    private func getCurrentMousePosition() -> CGPoint? {
        let event = CGEvent(source: nil)
        return event?.location
    }
}
