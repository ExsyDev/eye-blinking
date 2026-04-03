import Foundation
import AppKit
import os.log

/// Manages periodic blink reminders with a floating hint.
/// Pauses automatically during breaks and when user is idle.
@MainActor
final class BlinkReminderService: ObservableObject {
    // MARK: - Published State

    @Published private(set) var isActive: Bool = false
    @Published private(set) var shouldShowHint: Bool = false

    // MARK: - Private

    private let settings: AppSettings
    private var reminderTimer: Timer?
    private var hintDismissTimer: Timer?
    private var isPausedForBreak: Bool = false
    private var isPausedForIdle: Bool = false

    private let hintDurationSeconds: TimeInterval = 1.5

    init(settings: AppSettings) {
        self.settings = settings
        Logger.blinkReminder.info("BlinkReminderService initialized")
    }

    // MARK: - Public API

    /// Start the blink reminder cycle.
    func start() {
        guard !isActive else {
            Logger.blinkReminder.debug("start() called but already active, ignoring")
            return
        }

        isActive = true
        scheduleNextReminder()
        Logger.blinkReminder.info("Blink reminder started with interval: \(self.settings.blinkIntervalSeconds)s")
    }

    /// Stop all reminders.
    func stop() {
        Logger.blinkReminder.info("Blink reminder stopping")
        isActive = false
        isPausedForBreak = false
        isPausedForIdle = false
        invalidateAllTimers()
        shouldShowHint = false
    }

    /// Pause reminders during a break.
    func pauseForBreak() {
        guard isActive, !isPausedForBreak else { return }
        isPausedForBreak = true
        invalidateReminderTimer()
        shouldShowHint = false
        Logger.blinkReminder.info("Blink reminder paused for break")
    }

    /// Resume reminders after a break ends.
    func resumeAfterBreak() {
        guard isPausedForBreak else { return }
        isPausedForBreak = false
        if isActive && !isPausedForIdle {
            scheduleNextReminder()
        }
        Logger.blinkReminder.info("Blink reminder resumed after break")
    }

    /// Pause reminders when user is idle.
    func pauseForIdle() {
        guard isActive, !isPausedForIdle else { return }
        isPausedForIdle = true
        invalidateReminderTimer()
        shouldShowHint = false
        Logger.blinkReminder.debug("Blink reminder paused for idle")
    }

    /// Resume reminders when user returns from idle.
    func resumeAfterIdle() {
        guard isPausedForIdle else { return }
        isPausedForIdle = false
        if isActive && !isPausedForBreak {
            scheduleNextReminder()
        }
        Logger.blinkReminder.debug("Blink reminder resumed after idle")
    }

    // MARK: - Reminder Logic

    private func scheduleNextReminder() {
        invalidateReminderTimer()
        let interval = TimeInterval(settings.blinkIntervalSeconds)

        reminderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.triggerReminder()
            }
        }
        Logger.blinkReminder.debug("Next blink reminder scheduled in \(interval)s")
    }

    private func triggerReminder() {
        guard isActive, !isPausedForBreak, !isPausedForIdle else {
            Logger.blinkReminder.debug("Reminder triggered but inactive/paused, skipping")
            return
        }

        Logger.blinkReminder.info("Blink reminder triggered")
        shouldShowHint = true

        if settings.isBlinkSoundEnabled {
            playBlinkSound()
        }

        // Auto-dismiss hint after duration
        hintDismissTimer?.invalidate()
        hintDismissTimer = Timer.scheduledTimer(withTimeInterval: hintDurationSeconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.dismissHint()
            }
        }
    }

    private func dismissHint() {
        shouldShowHint = false
        Logger.blinkReminder.debug("Blink hint dismissed")

        // Schedule next reminder
        if isActive && !isPausedForBreak && !isPausedForIdle {
            scheduleNextReminder()
        }
    }

    // MARK: - Timer Management

    private func invalidateReminderTimer() {
        reminderTimer?.invalidate()
        reminderTimer = nil
    }

    private func invalidateAllTimers() {
        invalidateReminderTimer()
        hintDismissTimer?.invalidate()
        hintDismissTimer = nil
    }

    // MARK: - Sound

    private func playBlinkSound() {
        // Use a subtle system sound for blink reminders
        if let sound = NSSound(named: "Tink") {
            sound.play()
        }
        Logger.blinkReminder.debug("Blink sound played")
    }
}
