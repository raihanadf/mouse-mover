import XCTest
@testable import MouseJiggler

/// Tests for IdleMonitor idle detection accuracy
final class IdleMonitorTests: XCTestCase {
    var idleMonitor: IdleMonitor!

    override func setUp() {
        super.setUp()
        self.idleMonitor = IdleMonitor()
    }

    override func tearDown() {
        self.idleMonitor = nil
        super.tearDown()
    }

    /// Test that idle time can be read from system
    func testIdleTimeReading() async {
        let idleTime = await idleMonitor.getIdleTime()

        // Idle time should be non-negative
        XCTAssertGreaterThanOrEqual(idleTime, 0, "Idle time should be non-negative")

        // Idle time should be reasonable (less than 1 hour)
        XCTAssertLessThan(idleTime, 3600, "Idle time should be less than 1 hour")
    }

    /// Test that idle time updates over time
    func testIdleTimeUpdates() async {
        let initialTime = await idleMonitor.getIdleTime()

        // Wait 2 seconds
        try? await Task.sleep(for: .seconds(2))

        let laterTime = await idleMonitor.getIdleTime()

        // Later time should be greater (or equal if user interacted)
        XCTAssertGreaterThanOrEqual(laterTime, initialTime, "Idle time should increase or stay same")
    }

    /// Test accuracy verification within tolerance
    func testAccuracyVerification() async {
        // Get current idle time
        let currentIdle = await idleMonitor.getIdleTime()

        // Verify with large tolerance should pass
        let isAccurate = await idleMonitor.verifyIdleTimeAccuracy(
            expectedIdleTime: currentIdle,
            tolerance: 1.0
        )

        XCTAssertTrue(isAccurate, "Idle time should be accurate within 1 second tolerance")
    }

    /// Test sleep/wake state handling
    func testSleepWakeHandling() async {
        // Initially should be awake
        let initialState = await idleMonitor.systemState
        XCTAssertEqual(initialState, .awake, "Initial state should be awake")

        // Simulate sleep
        await self.idleMonitor.handleSystemWillSleep()
        let sleepState = await idleMonitor.systemState
        XCTAssertEqual(sleepState, .sleeping, "State should be sleeping after handleSystemWillSleep")

        // Simulate wake
        await self.idleMonitor.handleSystemDidWake()
        let wakeState = await idleMonitor.systemState
        XCTAssertEqual(wakeState, .waking, "State should be waking after handleSystemDidWake")

        // Idle time should be reset after wake
        let idleAfterWake = await idleMonitor.getIdleTime()
        XCTAssertEqual(idleAfterWake, 0, "Idle time should be 0 immediately after wake")
    }

    /// Test idle time stream produces values
    func testIdleTimeStream() async {
        var receivedValues: [TimeInterval] = []

        // Collect values for 3 seconds
        let task = Task {
            for await idleTime in await self.idleMonitor.idleTimeStream() {
                receivedValues.append(idleTime)
                if receivedValues.count >= 3 {
                    break
                }
            }
        }

        // Wait for collection
        try? await task.value

        // Should have received at least 3 values
        XCTAssertGreaterThanOrEqual(receivedValues.count, 3, "Should receive multiple idle time updates")

        // All values should be non-negative
        for value in receivedValues {
            XCTAssertGreaterThanOrEqual(value, 0, "All idle times should be non-negative")
        }
    }

    /// Test that idle time doesn't jump unexpectedly
    func testIdleTimeConsistency() async {
        var previousTime: TimeInterval = 0
        var jumpDetected = false

        // Monitor for 5 seconds
        let task = Task {
            var count = 0
            for await idleTime in await self.idleMonitor.idleTimeStream() {
                // Check for backward jumps (should never happen)
                if idleTime < previousTime - 1.0 {
                    jumpDetected = true
                }
                previousTime = idleTime
                count += 1
                if count >= 5 {
                    break
                }
            }
        }

        try? await task.value

        XCTAssertFalse(jumpDetected, "Idle time should never jump backward significantly")
    }
}
