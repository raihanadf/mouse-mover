import AppKit
import CoreGraphics
import Foundation

/// Screen information for multi-monitor support
struct ScreenInfo {
    let frame: CGRect
    let visibleFrame: CGRect
    let displayID: CGDirectDisplayID

    var width: CGFloat {
        self.frame.width
    }

    var height: CGFloat {
        self.frame.height
    }
}

/// Controls mouse cursor movement with multi-monitor and full-screen app support
actor MouseController {
    private var isMoving = false
    private var lastScreenIndex: Int?

    // Movement settings
    private let moveDuration: TimeInterval = 0.5
    private let stepsPerMove = 20
    private let padding: CGFloat = 20

    /// Get all connected screens
    private func getAllScreens() -> [ScreenInfo] {
        var screens: [ScreenInfo] = []

        let displayCount = NSScreen.screens.count
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: displayCount)
        var actualCount: UInt32 = 0

        let error = CGGetActiveDisplayList(UInt32(displayCount), &displayIDs, &actualCount)

        guard error == .success else {
            // Fallback to NSScreen
            return NSScreen.screens.enumerated().map { index, screen in
                ScreenInfo(
                    frame: screen.frame,
                    visibleFrame: screen.visibleFrame,
                    displayID: CGDirectDisplayID(index)
                )
            }
        }

        for i in 0 ..< Int(actualCount) {
            let displayID = displayIDs[i]
            let bounds = CGDisplayBounds(displayID)

            // Get visible frame (excluding menu bar/dock)
            let screen = NSScreen.screens.first { nsScreen in
                nsScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber ==
                    NSNumber(value: UInt32(displayID))
            }

            screens.append(ScreenInfo(
                frame: bounds,
                visibleFrame: screen?.visibleFrame ?? bounds,
                displayID: displayID
            ))
        }

        return screens.isEmpty ? [self.getMainScreenInfo()] : screens
    }

    /// Get main screen info
    private func getMainScreenInfo() -> ScreenInfo {
        let frame = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let visibleFrame = NSScreen.main?.visibleFrame ?? frame
        return ScreenInfo(frame: frame, visibleFrame: visibleFrame, displayID: 0)
    }

    /// Check if there's a full-screen app running on the current screen
    private func hasFullScreenAppOnScreen(_ screen: ScreenInfo) -> Bool {
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }

        for window in windowList {
            guard let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = bounds["X"],
                  let y = bounds["Y"],
                  let width = bounds["Width"],
                  let height = bounds["Height"],
                  let layer = window[kCGWindowLayer as String] as? Int,
                  layer == 0 // Normal window layer
            else { continue }

            let windowFrame = CGRect(x: x, y: y, width: width, height: height)

            // Check if window covers the entire screen (full-screen)
            let intersection = windowFrame.intersection(screen.frame)
            let coverage = intersection.width * intersection.height
            let screenArea = screen.frame.width * screen.frame.height

            if coverage > screenArea * 0.95 {
                return true
            }
        }

        return false
    }

    /// Find which screen contains a point
    private func screenContaining(point: CGPoint) -> ScreenInfo? {
        let screens = self.getAllScreens()
        return screens.first { screen in
            screen.frame.contains(point)
        }
    }

    /// Perform a smooth move to a random position
    func jiggle() {
        guard !self.isMoving else {
            print("[MouseController] Already moving, skipping")
            return
        }

        guard let currentPos = getCurrentMousePosition() else {
            print("[MouseController] Could not get current mouse position")
            return
        }

        // Get current screen
        guard let currentScreen = screenContaining(point: currentPos) else {
            print("[MouseController] Could not determine current screen")
            return
        }

        // Check if full-screen app is running
        let hasFullScreen = self.hasFullScreenAppOnScreen(currentScreen)
        if hasFullScreen {
            print("[MouseController] Full-screen app detected, using conservative movement")
        }

        // Pick target screen (prefer staying on current, but can move to others)
        let targetScreen = self.pickTargetScreen(current: currentScreen, currentPos: currentPos)

        // Calculate target position
        let targetPos = self.calculateTargetPosition(
            on: targetScreen,
            currentPos: currentPos,
            hasFullScreen: hasFullScreen
        )

        self.isMoving = true
        print("[MouseController] Moving from (\(Int(currentPos.x)), \(Int(currentPos.y))) to (\(Int(targetPos.x)), \(Int(targetPos.y))) on screen \(targetScreen.displayID)")

        // Animate the movement
        Task {
            await self.animateMovement(from: currentPos, to: targetPos)
            self.isMoving = false
            print("[MouseController] Arrived at (\(Int(targetPos.x)), \(Int(targetPos.y)))")
        }
    }

    /// Pick a target screen for movement
    private func pickTargetScreen(current: ScreenInfo, currentPos _: CGPoint) -> ScreenInfo {
        let screens = self.getAllScreens()

        // 70% chance to stay on current screen, 30% to switch
        if screens.count > 1, Int.random(in: 0 ..< 10) < 3 {
            let otherScreens = screens.filter { $0.displayID != current.displayID }
            if let randomScreen = otherScreens.randomElement() {
                self.lastScreenIndex = screens.firstIndex(where: { $0.displayID == randomScreen.displayID })
                return randomScreen
            }
        }

        return current
    }

    /// Calculate a valid target position on a screen
    private func calculateTargetPosition(on screen: ScreenInfo, currentPos: CGPoint, hasFullScreen: Bool) -> CGPoint {
        let usableFrame = hasFullScreen ? screen.visibleFrame.insetBy(dx: self.padding, dy: self.padding) : screen.frame.insetBy(dx: self.padding, dy: self.padding)

        // If full-screen, use smaller movements (stay closer to current position)
        if hasFullScreen {
            let maxDistance: CGFloat = 200
            let angle = Double.random(in: 0 ... (2 * .pi))
            let distance = CGFloat.random(in: 50 ... maxDistance)

            var targetX = currentPos.x + CGFloat(cos(angle)) * distance
            var targetY = currentPos.y + CGFloat(sin(angle)) * distance

            // Clamp to screen bounds
            targetX = max(usableFrame.minX, min(usableFrame.maxX, targetX))
            targetY = max(usableFrame.minY, min(usableFrame.maxY, targetY))

            return CGPoint(x: targetX, y: targetY)
        }

        // Normal movement - random position anywhere on screen
        return CGPoint(
            x: CGFloat.random(in: usableFrame.minX ... usableFrame.maxX),
            y: CGFloat.random(in: usableFrame.minY ... usableFrame.maxY)
        )
    }

    /// Animate mouse movement from start to end position
    private func animateMovement(from start: CGPoint, to end: CGPoint) async {
        let stepDuration = self.moveDuration / Double(self.stepsPerMove)

        for step in 0 ... self.stepsPerMove {
            let progress = Double(step) / Double(self.stepsPerMove)
            let easedProgress = self.easeInOut(progress)

            let currentX = start.x + (end.x - start.x) * CGFloat(easedProgress)
            let currentY = start.y + (end.y - start.y) * CGFloat(easedProgress)

            self.moveMouse(to: CGPoint(x: currentX, y: currentY))

            try? await Task.sleep(for: .seconds(stepDuration))
        }
    }

    /// Ease-in-out curve for smooth acceleration/deceleration
    private func easeInOut(_ t: Double) -> Double {
        t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
    }

    /// Get current mouse position
    private func getCurrentMousePosition() -> CGPoint? {
        let event = CGEvent(source: nil)
        return event?.location
    }

    /// Move mouse to specific position immediately
    private func moveMouse(to point: CGPoint) {
        CGWarpMouseCursorPosition(point)
    }
}
