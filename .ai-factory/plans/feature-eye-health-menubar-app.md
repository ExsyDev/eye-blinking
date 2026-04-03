# Implementation Plan: Eye Health Menubar App

Branch: feature/eye-health-menubar-app
Created: 2026-04-01

## Settings
- Testing: no
- Logging: verbose
- Docs: yes

## Research Context
Source: .ai-factory/RESEARCH.md (Active Summary)

Goal: Build a native SwiftUI menubar app (macOS 14+) that reminds user to take 20-sec breaks every 20 min (looking 20ft away) and to blink periodically.

Constraints:
- macOS 14+ (Sonoma) minimum
- SwiftUI + AppKit (NSPanel for fullscreen overlay)
- Swift 5.9+
- Localization: Russian + English via String Catalogs (.xcstrings)
- App Store compatible architecture

Decisions:
- Fullscreen dark overlay (NSPanel at .screenSaver level) as default break mode
- Floating hint in screen corner for blink reminders (1.5 sec, fade in/out)
- Sound for both reminders, independently toggleable
- CGEventSource idle time polling (every 30 sec) + NSWorkspace screen sleep/wake
- SwiftData for statistics, @AppStorage for preferences
- ServiceManagement for launch at login

Open questions:
- App icon design
- Specific sound files (system sounds vs custom)
- Sandbox from start vs later

## Commit Plan
- **Commit 1** (after tasks 1-2): `feat: scaffold project structure and data models`
- **Commit 2** (after tasks 3-5): `feat: implement core services (break timer, blink reminder, activity monitor)`
- **Commit 3** (after tasks 6-9): `feat: add all UI views (menubar, settings, overlay, hint)`
- **Commit 4** (after tasks 10-11): `feat: add statistics service and weekly chart view`
- **Commit 5** (after tasks 12-13): `feat: wire up components and add RU/EN localization`

## Tasks

### Phase 1: Project Setup
- [x] Task 1: Create Xcode project structure with SwiftUI MenuBarExtra
  - Set up macOS 14+ app with MenuBarExtra scene, LSUIElement, folder structure
  - Configure os.Logger with category extensions
  - Files: EyeBlinking/App/EyeBlinkingApp.swift, EyeBlinking/Utilities/Logger+Extensions.swift

- [x] Task 2: Define data models and types (depends on 1)
  - AppSettings (@AppStorage wrapper), BreakMode enum, TimerState enum, StatisticsEntry (@Model)
  - Files: EyeBlinking/Models/AppSettings.swift, EyeBlinking/Models/BreakMode.swift, EyeBlinking/Models/TimerState.swift, EyeBlinking/Models/StatisticsEntry.swift

<!-- Commit checkpoint: tasks 1-2 -->

### Phase 2: Core Services
- [x] Task 3: Implement BreakTimerService (depends on 1, 2)
  - 20-min countdown, break trigger, pause/resume, sound, track taken/skipped
  - Files: EyeBlinking/Services/BreakTimerService.swift

- [x] Task 4: Implement BlinkReminderService (depends on 1, 2)
  - Configurable interval, 1.5s hint trigger, sound, pause during breaks
  - Files: EyeBlinking/Services/BlinkReminderService.swift

- [x] Task 5: Implement ActivityMonitorService (depends on 1, 2)
  - CGEventSource polling, screen sleep/wake, idle detection, timer pause/reset
  - Files: EyeBlinking/Services/ActivityMonitorService.swift

<!-- Commit checkpoint: tasks 3-5 -->

### Phase 3: User Interface
- [x] Task 6: Create MenuBarView (depends on 2, 3, 4)
  - Timer status, toggle controls, take/skip break, today's stats, settings/quit
  - Files: EyeBlinking/Views/MenuBarView.swift

- [x] Task 7: Create SettingsView (depends on 2)
  - General/Blink/Sound tabs, launch at login (ServiceManagement), about
  - Files: EyeBlinking/Views/SettingsView.swift

- [x] Task 8: Create BreakOverlayView with NSPanel (depends on 3)
  - NSPanel .screenSaver level, all screens, 20s countdown, progress dots, skip/esc, animations
  - Files: EyeBlinking/Views/BreakOverlayView.swift, EyeBlinking/Views/BreakOverlayPanel.swift

- [x] Task 9: Create BlinkHintView (depends on 4)
  - Floating corner hint, 1.5s display, fade in/out, non-interactive
  - Files: EyeBlinking/Views/BlinkHintView.swift

<!-- Commit checkpoint: tasks 6-9 -->

### Phase 4: Statistics
- [x] Task 10: Implement StatisticsService with SwiftData (depends on 1, 2)
  - ModelContainer setup, event recording, daily aggregation, streak calculation
  - Files: EyeBlinking/Services/StatisticsService.swift

- [x] Task 11: Create StatisticsView with weekly chart (depends on 10)
  - Today's summary, Swift Charts weekly bar chart, green/red color coding
  - Files: EyeBlinking/Views/StatisticsView.swift

<!-- Commit checkpoint: tasks 10-11 -->

### Phase 5: Integration & Localization
- [x] Task 12: Wire up services and integrate all components (depends on 3-10)
  - Initialize services in App, environmentObject injection, inter-service wiring, lifecycle
  - Files: EyeBlinking/App/EyeBlinkingApp.swift

- [x] Task 13: Set up String Catalogs for RU/EN localization (depends on 6-9, 11)
  - .xcstrings with English + Russian, all user-facing strings, pluralization
  - Files: EyeBlinking/Resources/Localizable.xcstrings

<!-- Commit checkpoint: tasks 12-13 -->
