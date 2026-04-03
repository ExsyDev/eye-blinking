import SwiftUI
import Combine
import os.log

@main
struct EyeBlinkingApp: App {
    @StateObject private var appController = AppController()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appController.settings)
                .environmentObject(appController.breakTimer)
                .environmentObject(appController.blinkReminder)
                .environmentObject(appController.statisticsService)
                .task {
                    appController.startIfNeeded()
                }
        } label: {
            Label("Eye Blinking", systemImage: "eye")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appController.settings)
        }
    }
}

/// Central controller that owns all services, wires them together, and manages lifecycle.
@MainActor
final class AppController: ObservableObject {
    let settings = AppSettings.shared
    let breakTimer: BreakTimerService
    let blinkReminder: BlinkReminderService
    let activityMonitor: ActivityMonitorService
    let statisticsService = StatisticsService()
    let overlayController = BreakOverlayController()
    let blinkHintController = BlinkHintController()

    private var started = false
    private var blinkHintPollTimer: Timer?
    private var settingsPollTimer: Timer?

    init() {
        breakTimer = BreakTimerService(settings: settings)
        blinkReminder = BlinkReminderService(settings: settings)
        activityMonitor = ActivityMonitorService(settings: settings)
        Logger.app.info("AppController initialized")
    }

    /// Wire services and start — idempotent, safe to call multiple times.
    func startIfNeeded() {
        guard !started else { return }
        started = true
        Logger.app.info("AppController wiring and starting services")

        wireBreakTimer()
        wireActivityMonitor()
        wireBlinkHint()
        wireSettingsObserver()

        if settings.isBreakTimerEnabled {
            breakTimer.start()
        }
        if settings.isBlinkReminderEnabled {
            blinkReminder.start()
        }
        activityMonitor.start()
        statisticsService.startScreenTimeTracking()

        Logger.app.info("All services wired and started")
    }

    // MARK: - Wiring

    private func wireBreakTimer() {
        breakTimer.onBreakStart = { [weak self] in
            guard let self else { return }
            Logger.app.info("Break started — showing overlay, pausing blink reminders")
            self.blinkReminder.pauseForBreak()

            let duration = self.settings.breakDurationSeconds
            self.overlayController.show(totalSeconds: duration, secondsRemaining: duration)
        }

        breakTimer.onBreakEnd = { [weak self] taken in
            guard let self else { return }
            Logger.app.info("Break ended — taken: \(taken)")
            self.overlayController.dismiss()
            self.blinkReminder.resumeAfterBreak()

            if taken {
                self.statisticsService.recordBreakTaken()
            } else {
                self.statisticsService.recordBreakSkipped()
            }
        }

        overlayController.onSkip = { [weak self] in
            Logger.app.info("Overlay skip triggered")
            self?.breakTimer.skipBreak()
        }

        // Update overlay countdown as break timer ticks
        breakTimer.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self else { return }
                if case .onBreak(let remaining) = state {
                    self.overlayController.updateCountdown(
                        totalSeconds: self.settings.breakDurationSeconds,
                        secondsRemaining: remaining
                    )
                }
            }
            // Store cancellable — since AppController lives for the app lifetime, this is fine
            .store(in: &cancellables)
    }

    private func wireActivityMonitor() {
        activityMonitor.onUserBecameIdle = { [weak self] in
            guard let self else { return }
            Logger.app.info("User became idle — pausing services")
            self.breakTimer.pause()
            self.blinkReminder.pauseForIdle()
            self.statisticsService.stopScreenTimeTracking()
        }

        activityMonitor.onUserBecameActive = { [weak self] in
            guard let self else { return }
            Logger.app.info("User became active — resuming services")
            self.breakTimer.resume()
            self.blinkReminder.resumeAfterIdle()
            self.statisticsService.startScreenTimeTracking()
        }

        activityMonitor.onLongAbsenceReturn = { [weak self] in
            guard let self else { return }
            Logger.app.info("User returned from long absence — resetting cycle")
            self.breakTimer.resetCycle()
            self.blinkReminder.resumeAfterIdle()
            self.statisticsService.startScreenTimeTracking()
        }
    }

    private func wireBlinkHint() {
        blinkReminder.$shouldShowHint
            .receive(on: RunLoop.main)
            .sink { [weak self] shouldShow in
                if shouldShow {
                    self?.blinkHintController.show()
                }
            }
            .store(in: &cancellables)
    }

    private func wireSettingsObserver() {
        var lastBreakEnabled = settings.isBreakTimerEnabled
        var lastBlinkEnabled = settings.isBlinkReminderEnabled

        settings.$isBreakTimerEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                guard let self, enabled != lastBreakEnabled else { return }
                lastBreakEnabled = enabled
                if enabled {
                    Logger.app.info("Break timer enabled via settings")
                    self.breakTimer.start()
                } else {
                    Logger.app.info("Break timer disabled via settings")
                    self.breakTimer.stop()
                }
            }
            .store(in: &cancellables)

        settings.$isBlinkReminderEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                guard let self, enabled != lastBlinkEnabled else { return }
                lastBlinkEnabled = enabled
                if enabled {
                    Logger.app.info("Blink reminder enabled via settings")
                    self.blinkReminder.start()
                } else {
                    Logger.app.info("Blink reminder disabled via settings")
                    self.blinkReminder.stop()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Combine Storage

    private var cancellables = Set<AnyCancellable>()
}
