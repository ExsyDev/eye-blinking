import Foundation
import AppKit
import os.log

/// Manages the 20-20-20 break timer cycle.
/// Counts down from the configured interval, triggers breaks, and tracks taken/skipped.
@MainActor
final class BreakTimerService: ObservableObject {
    // MARK: - Published State

    @Published private(set) var state: TimerState = .stopped
    @Published private(set) var breaksTakenToday: Int = 0
    @Published private(set) var breaksSkippedToday: Int = 0

    // MARK: - Callbacks

    /// Called when a break should start (overlay/notification should appear).
    var onBreakStart: (() -> Void)?

    /// Called when a break ends (completed or skipped).
    var onBreakEnd: ((Bool) -> Void)? // true = taken, false = skipped

    // MARK: - Private

    private let settings: AppSettings
    private var countdownTimer: Timer?
    private var breakTimer: Timer?

    init(settings: AppSettings) {
        self.settings = settings
        Logger.breakTimer.info("BreakTimerService initialized")
    }

    // MARK: - Public API

    /// Start the break timer cycle.
    func start() {
        guard !state.isRunning else {
            Logger.breakTimer.debug("start() called but timer already running, ignoring")
            return
        }

        let totalSeconds = settings.breakIntervalMinutes * 60
        state = .running(secondsRemaining: totalSeconds)
        startCountdownTimer()

        Logger.breakTimer.info("Break timer started: \(totalSeconds)s interval")
    }

    /// Stop the timer completely.
    func stop() {
        Logger.breakTimer.info("Break timer stopping from state: \(String(describing: self.state))")
        invalidateAllTimers()
        state = .stopped
    }

    /// Pause the countdown (e.g., user idle).
    func pause() {
        guard case .running(let remaining) = state else {
            Logger.breakTimer.debug("pause() called but not running, current state: \(String(describing: self.state))")
            return
        }

        invalidateCountdownTimer()
        state = .paused(secondsRemaining: remaining)
        Logger.breakTimer.info("Break timer paused with \(remaining)s remaining")
    }

    /// Resume from pause.
    func resume() {
        guard case .paused = state else {
            Logger.breakTimer.debug("resume() called but not paused, current state: \(String(describing: self.state))")
            return
        }

        startCountdownTimer()
        if case .paused(let remaining) = state {
            state = .running(secondsRemaining: remaining)
            Logger.breakTimer.info("Break timer resumed with \(remaining)s remaining")
        }
    }

    /// User chose to take a break now (before timer expired).
    func takeBreakNow() {
        Logger.breakTimer.info("User requested immediate break")
        invalidateCountdownTimer()
        triggerBreak()
    }

    /// User skipped the current break.
    func skipBreak() {
        Logger.breakTimer.info("User skipped break")
        invalidateBreakTimer()
        breaksSkippedToday += 1
        onBreakEnd?(false)
        restartCycle()
    }

    /// Reset the timer to full interval (e.g., after returning from long idle).
    func resetCycle() {
        Logger.breakTimer.info("Resetting break timer cycle")
        invalidateAllTimers()
        start()
    }

    /// Reset daily counters (call at midnight or app start on new day).
    func resetDailyCounters() {
        breaksTakenToday = 0
        breaksSkippedToday = 0
        Logger.breakTimer.info("Daily counters reset")
    }

    // MARK: - Break Logic

    private func triggerBreak() {
        let breakDuration = settings.breakDurationSeconds
        state = .onBreak(secondsRemaining: breakDuration)
        Logger.breakTimer.info("Break triggered: \(breakDuration)s duration")

        if settings.isBreakSoundEnabled {
            playBreakSound()
        }

        onBreakStart?()
        startBreakTimer()
    }

    private func completeBreak() {
        Logger.breakTimer.info("Break completed naturally")
        invalidateBreakTimer()
        breaksTakenToday += 1
        onBreakEnd?(true)
        restartCycle()
    }

    private func restartCycle() {
        let totalSeconds = settings.breakIntervalMinutes * 60
        state = .running(secondsRemaining: totalSeconds)
        startCountdownTimer()
        Logger.breakTimer.info("Cycle restarted: \(totalSeconds)s until next break")
    }

    // MARK: - Timer Management

    private func startCountdownTimer() {
        invalidateCountdownTimer()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickCountdown()
            }
        }
    }

    private func tickCountdown() {
        guard case .running(let remaining) = state else { return }

        let newRemaining = remaining - 1
        if newRemaining <= 0 {
            Logger.breakTimer.info("Countdown reached zero, triggering break")
            invalidateCountdownTimer()
            triggerBreak()
        } else {
            state = .running(secondsRemaining: newRemaining)
        }
    }

    private func startBreakTimer() {
        invalidateBreakTimer()
        breakTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickBreak()
            }
        }
    }

    private func tickBreak() {
        guard case .onBreak(let remaining) = state else { return }

        let newRemaining = remaining - 1
        if newRemaining <= 0 {
            completeBreak()
        } else {
            state = .onBreak(secondsRemaining: newRemaining)
        }
    }

    private func invalidateCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func invalidateBreakTimer() {
        breakTimer?.invalidate()
        breakTimer = nil
    }

    private func invalidateAllTimers() {
        invalidateCountdownTimer()
        invalidateBreakTimer()
    }

    // MARK: - Sound

    private func playBreakSound() {
        NSSound.beep()
        Logger.breakTimer.debug("Break sound played")
    }
}
