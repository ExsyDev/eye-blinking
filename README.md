# EyeBlinking

A lightweight macOS menu bar app that helps protect your eyes with regular break reminders and blink notifications.

## Features

- **Break Timer** — reminds you to take breaks at configurable intervals (default: every 20 min for 20 sec)
- **Blink Reminders** — subtle periodic reminders to blink (default: every 15 sec)
- **Fullscreen Overlay** — break reminders appear as a fullscreen overlay or system notification
- **Idle Detection** — automatically pauses when you step away from the computer
- **Activity Tracking** — tracks daily break statistics (taken / skipped)
- **Launch at Login** — optional auto-start with macOS
- **Menu Bar Only** — lives in the menu bar, no Dock icon clutter

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.4+ (for building from source)

## Installation

### Download

1. Go to [Releases](https://github.com/ExsyDev/eye-blinking/releases)
2. Download `EyeBlinking.dmg`
3. Open the DMG and drag **EyeBlinking** to **Applications**
4. Right-click the app → **Open** (first launch only, to bypass Gatekeeper)

### Build from Source

```bash
git clone https://github.com/ExsyDev/eye-blinking.git
cd eye-blinking
xcodebuild -project EyeBlinking.xcodeproj -scheme EyeBlinking -configuration Release
```

Or open `EyeBlinking.xcodeproj` in Xcode and press `Cmd+R`.

## Usage

After launch, EyeBlinking appears as an eye icon in the menu bar.

### Menu Bar Controls

- **Break Reminders** — toggle break timer on/off
- **Blink Reminders** — toggle blink notifications on/off
- **Take Break Now** — start a break immediately
- **Settings** — configure intervals, break mode, sounds

### Settings

| Setting | Default | Range |
|---------|---------|-------|
| Break interval | 20 min | 5–60 min |
| Break duration | 20 sec | 10–60 sec |
| Blink reminder interval | 15 sec | 5–60 sec |
| Idle threshold | 3 min | 1–15 min |
| Break mode | Fullscreen Overlay | Overlay / Notification |

## Project Structure

```
EyeBlinking/
├── App/
│   └── EyeBlinkingApp.swift        # App entry point, service wiring
├── Models/
│   ├── AppSettings.swift           # UserDefaults-backed settings
│   ├── BreakMode.swift             # Break display mode enum
│   ├── StatisticsEntry.swift       # SwiftData model for stats
│   └── TimerState.swift            # Timer state machine
├── Services/
│   ├── ActivityMonitorService.swift # Idle/active detection
│   ├── BlinkReminderService.swift  # Periodic blink reminders
│   ├── BreakTimerService.swift     # Break countdown timer
│   └── StatisticsService.swift     # Screen time & break tracking
├── Views/
│   ├── MenuBarView.swift           # Menu bar popover UI
│   ├── SettingsView.swift          # Settings window (tabs)
│   ├── BlinkHintView.swift         # Blink reminder overlay
│   ├── BreakOverlayView.swift      # Fullscreen break overlay
│   ├── BreakOverlayPanel.swift     # NSPanel for break overlay
│   └── StatisticsView.swift        # Statistics display
├── Utilities/
│   └── Logger+Extensions.swift     # os.log categories
└── Resources/
    ├── Info.plist
    ├── EyeBlinking.entitlements
    └── Localizable.xcstrings       # Localization (en, ru)
```

## License

MIT
