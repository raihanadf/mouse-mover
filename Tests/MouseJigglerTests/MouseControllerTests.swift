import CoreGraphics
import XCTest
@testable import MouseJiggler

/// Tests for MouseController
final class MouseControllerTests: XCTestCase {
    var mouseController: MouseController!

    override func setUp() {
        super.setUp()
        self.mouseController = MouseController()
    }

    override func tearDown() {
        self.mouseController = nil
        super.tearDown()
    }

    /// Test that jiggle completes without crashing
    func testJiggleExecution() async {
        // Store original position
        let originalPos = self.getCurrentMousePosition()

        // Perform jiggle
        await self.mouseController.jiggle()

        // Wait for animation to complete
        try? await Task.sleep(for: .seconds(1))

        // Get new position
        let newPos = self.getCurrentMousePosition()

        // Position should have changed
        XCTAssertNotEqual(originalPos, newPos, "Mouse position should change after jiggle")
    }

    /// Test that jiggle stays within screen bounds
    func testJiggleWithinBounds() async {
        guard let screenBounds = NSScreen.main?.frame else {
            XCTSkip("Could not get screen bounds")
            return
        }

        // Perform multiple jiggles
        for _ in 0 ..< 5 {
            await self.mouseController.jiggle()
            try? await Task.sleep(for: .seconds(0.6))

            guard let pos = getCurrentMousePosition() else {
                XCTFail("Could not get mouse position")
                return
            }

            // Check bounds
            XCTAssertGreaterThanOrEqual(pos.x, 0, "X should be >= 0")
            XCTAssertLessThanOrEqual(pos.x, screenBounds.width, "X should be <= screen width")
            XCTAssertGreaterThanOrEqual(pos.y, 0, "Y should be >= 0")
            XCTAssertLessThanOrEqual(pos.y, screenBounds.height, "Y should be <= screen height")
        }
    }

    /// Test concurrent jiggle requests are handled
    func testConcurrentJiggles() async {
        // Start multiple jiggles concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 3 {
                group.addTask {
                    await self.mouseController.jiggle()
                }
            }
        }

        // Should complete without crashing
        XCTAssertTrue(true, "Concurrent jiggles should complete")
    }

    private func getCurrentMousePosition() -> CGPoint? {
        let event = CGEvent(source: nil)
        return event?.location
    }
}
