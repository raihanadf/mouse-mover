# 🖱️ Mouse Jiggler

A macOS app that keeps your device active by gently moving the mouse cursor when you're away. Perfect for preventing screen lock during presentations, downloads, or remote work sessions.

![macOS 13+](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange)

## ✨ Features

- 🎯 **Smart Idle Detection** - Uses system idle time + mouse position tracking for accuracy
- 🖥️ **Multi-Monitor Support** - Works across all connected displays
- 🔧 **Configurable Timing** - Adjustable idle threshold and move intervals
- 📊 **Menu Bar Mode** - Optional dock-less operation
- ⌨️ **Global Shortcut** - Toggle with `⌥⌘J` (Option+Command+J)
- 🔔 **Notifications** - Optional alerts when jiggler activates
- 🛡️ **Full-Screen Aware** - Smaller movements when full-screen apps are running

## 📦 Installation

### From Source

```bash
git clone <repo-url>
cd mouse-jiggler
./build.sh
cp -r MouseJiggler.app /Applications/
```

### Requirements

- macOS 13.0+
- Accessibility permissions (required for cursor control)

## 🚀 Usage

### First Launch

1. Open **Mouse Jiggler** from Applications
2. Grant **Accessibility Permissions** when prompted
   - System Settings → Privacy & Security → Accessibility → Enable Mouse Jiggler
3. Click **Start** to begin monitoring

### Basic Operation

1. **Start** the app by clicking the Start button
2. The app monitors your idle time (keyboard & mouse inactivity)
3. After **30 seconds** of inactivity (configurable), the jiggler activates
4. Every **10 seconds** (configurable), it moves the cursor to a new random position
5. When you return (move mouse or type), jiggling pauses automatically

### Settings

Access settings via the gear icon or menu bar:

| Setting | Default | Range |
|---------|---------|-------|
| Idle Threshold | 30 seconds | 6s - 60m |
| Move Interval | 10 seconds | 1s - 60s |
| Menu Bar Mode | Off | On/Off |
| Launch at Login | Off | On/Off |
| Notifications | On | On/Off |
| Keyboard Shortcut | On | On/Off |

### Menu Bar Mode

Enable in Settings for dock-less operation:
- App lives in the menu bar (top right)
- Click icon for quick toggle
- Settings accessible from menu

### Keyboard Shortcut

- **⌥⌘J** (Option+Command+J) - Toggle jiggler on/off from anywhere

## 🏗️ Building from Source

```bash
# Clone repository
git clone <repo-url>
cd mouse-jiggler

# Build debug version
swift build
swift run

# Build release version
./build.sh

# Format code
make format

# Run tests
swift test
```

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Mouse Jiggler App                     │
├─────────────────────────────────────────────────────────┤
│  UI Layer (SwiftUI)                                     │
│  ├── ContentView (main interface)                       │
│  ├── SettingsView (configuration)                       │
│  └── DebugView (idle detection testing)                 │
├─────────────────────────────────────────────────────────┤
│  Core Logic                                             │
│  ├── JigglerController (state machine)                  │
│  ├── Settings (UserDefaults persistence)                │
│  └── KeyboardShortcut (global hotkey)                   │
├─────────────────────────────────────────────────────────┤
│  Services                                               │
│  ├── IdleMonitor (IOKit idle detection)                 │
│  ├── MouseController (CoreGraphics cursor control)      │
│  └── AccessibilityChecker (permission handling)         │
├─────────────────────────────────────────────────────────┤
│  macOS APIs                                             │
│  ├── IOKit (IOHIDSystem) - idle time detection          │
│  ├── CoreGraphics (CGWarpMouseCursorPosition)           │
│  └── AppKit (NSStatusBar, NSUserNotification)           │
└─────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
Sources/MouseJiggler/
├── MouseJiggler.swift          # App entry, menu bar, shortcuts
├── Views/
│   ├── ContentView.swift       # Main UI
│   ├── SettingsView.swift      # Settings panel
│   └── DebugView.swift         # Debug/testing tools
├── Controllers/
│   └── JigglerController.swift # Main logic coordinator
└── Services/
    ├── IdleMonitor.swift       # Idle detection
    ├── MouseController.swift   # Mouse movement
    ├── Settings.swift          # Persistence
    └── AccessibilityChecker.swift # Permissions
```

## 🔒 Permissions

The app requires **Accessibility permissions** to control the mouse cursor.

**Why?** macOS restricts apps from controlling the cursor for security reasons. Accessibility permissions are the legitimate way for assistive apps to do this.

**Is it safe?** Yes - the app is open source and only moves your cursor. No data is collected or transmitted.

## 🛠️ Development

### Phase Status

| Phase | Status | Description |
|-------|--------|-------------|
| 1 | ✅ | Project Setup + Basic UI |
| 2 | ✅ | Fine-tune Idle Detection |
| 3 | ✅ | Test & Refine Mouse Movement |
| 4 | ✅ | Settings & Menu Bar Mode |
| 5 | ✅ | Polish & Distribution |

### Issue Tracking

This project uses **beads** (`bd`) for issue tracking:

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd close <id>         # Complete work
```

## 📄 License

MIT License - See LICENSE file for details

## 🙏 Credits

- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) - Code formatting
- [beads](https://github.com/steveyegge/beads) - Issue tracking

---

Made with ☕️ and Swift
