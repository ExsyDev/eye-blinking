# Research

Updated: 2026-04-01 12:00
Status: active

## Active Summary (input for /aif-plan)
<!-- aif:active-summary:start -->
Topic: macOS menubar app for eye health — blink reminders + 20-20-20 rule
Goal: Build a native SwiftUI menubar app (macOS 14+) that reminds user to take 20-sec breaks every 20 min (looking 20ft away) and to blink periodically. For personal use initially, potential App Store release later.

Constraints:
- macOS 14+ (Sonoma) minimum
- SwiftUI + AppKit (NSPanel for fullscreen overlay)
- Swift 5.9+
- Localization: Russian + English via String Catalogs (.xcstrings), auto-detect from system locale
- App Store compatible architecture (sandboxing considerations)

Decisions:
- **Break reminder mode**: Fullscreen dark overlay (default), configurable to overlay panel or system notification
- **Break overlay**: NSPanel at .screenSaver level, covers all screens, Esc to dismiss, Skip button, 20-sec countdown with progress dots
- **Blink reminder**: Floating hint in screen corner (1.5 sec, fade in/out), toggleable on/off in settings
- **Sound**: Both break and blink reminders have sound, each independently toggleable in settings
- **Activity detection**: CGEventSource idle time polling (every 30 sec) + NSWorkspace screen sleep/wake observers. Pause timers when idle > threshold. Reset 20-min cycle on return from long absence.
- **Statistics**: Track breaks taken/skipped, screen time, streaks. SwiftData for persistence. Mini bar chart for weekly view.
- **Settings storage**: @AppStorage (UserDefaults) for preferences
- **Launch at login**: ServiceManagement framework
- **Project structure**: MenuBarExtra-based app, Services layer (BreakTimer, BlinkReminder, ActivityMonitor), Views layer (MenuBarView, SettingsView, BreakOverlayView, BlinkHintView)

Open questions:
- App icon design
- Specific sound files (system sounds vs custom)
- Whether to sandbox fully from the start (needed for App Store) or add later

Success signals:
- App lives in menubar, minimal resource usage
- Fullscreen overlay reliably covers all screens and spaces
- Timers pause correctly when user is away
- Statistics persist across app restarts
- Smooth animations on overlay appear/dismiss

Next step: /aif-plan to create implementation plan

<!-- aif:active-summary:end -->

## Sessions
<!-- aif:sessions:start -->
### 2026-04-01 12:00 — Initial exploration and specification

What changed:
- Evaluated tech options (SwiftUI native vs Electron vs Python) — chose SwiftUI MenuBarExtra
- Defined all core features: 20-20-20 break timer, blink reminder, activity monitor, statistics, settings
- Decided on fullscreen overlay (NSPanel .screenSaver level) as default break mode with 3 options
- Chose floating hint for blink reminders
- Sound notifications for both features, independently toggleable
- SwiftData for statistics, @AppStorage for settings
- String Catalogs for RU/EN localization
- macOS 14+ target

Key notes:
- NSPanel with .screenSaver level + .canJoinAllSpaces for reliable fullscreen coverage
- CGEventSourceSecondsSinceLastEventType for idle detection
- Reset 20-min cycle after user returns from idle (they already rested)
- ServiceManagement framework for launch at login (modern replacement for LSSharedFileList)

Links (paths):
- Project root: /Users/dimkg./code/eye-blinking
<!-- aif:sessions:end -->
