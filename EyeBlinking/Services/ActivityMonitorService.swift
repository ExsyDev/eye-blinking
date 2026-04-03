import Foundation
import AppKit
import os.log

/// Monitors user activity via CGEventSource idle time and screen sleep/wake.
/// Notifies other services when user becomes idle or returns.
@MainActor
final class ActivityMonitorService: ObservableObject {
    // MARK: - Published State

    @Published private(set) var isUserIdle: Bool = false
    @Published private(set) var isScreenAsleep: Bool = false

    // MARK: - Callbacks

    /// Called when user becomes idle (exceeds threshold).
    var onUserBecameIdle: (() -> Void)?

    /// Called when user returns from idle.
    var onUserBecameActive: (() -> Void)?

    /// Called when user returns from a long absence (should reset break cycle).
    var onLongAbsenceReturn: (() -> Void)?

    // MARK: - Private

    private let settings: AppSettings
    private var pollingTimer: Timer?
    private var idleStartTime: Date?
    private let pollingIntervalSeconds: TimeInterval = 30.0
    private let longAbsenceThresholdMinutes: Int = 10

    private var screenSleepObserver: Any?
    private var screenWakeObserver: Any?

    init(settings: AppSettings) {
        self.settings = settings
        Logger.activityMonitor.info("ActivityMonitorService initialized")
    }

    // MARK: - Public API

    /// Start monitoring user activity.
    func start() {
        startPolling()
        observeScreenSleepWake()
        Logger.activityMonitor.info("Activity monitoring started, polling every \(self.pollingIntervalSeconds)s, idle threshold: \(self.settings.idleThresholdMinutes)m")
    }

    /// Stop monitoring.
    func stop() {
        stopPolling()
        removeScreenObservers()
        isUserIdle = false
        isScreenAsleep = false
        idleStartTime = nil
        Logger.activityMonitor.info("Activity monitoring stopped")
    }

    /// Current system idle time in seconds.
    var systemIdleTimeSeconds: TimeInterval {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
    }

    // MARK: - Polling

    private func startPolling() {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkIdleState()
            }
        }
        // Also check immediately
        checkIdleState()
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private func checkIdleState() {
        let idleSeconds = systemIdleTimeSeconds
        let thresholdSeconds = TimeInterval(settings.idleThresholdMinutes * 60)

        Logger.activityMonitor.debug("Idle check: \(idleSeconds, privacy: .public)s idle, threshold: \(thresholdSeconds)s")

        if idleSeconds >= thresholdSeconds {
            if !isUserIdle {
                // User just became idle
                isUserIdle = true
                idleStartTime = Date().addingTimeInterval(-idleSeconds)
                Logger.activityMonitor.info("User became idle (idle for \(idleSeconds)s)")
                onUserBecameIdle?()
            }
        } else {
            if isUserIdle {
                // User just returned from idle
                let wasIdleSince = idleStartTime ?? .now
                let idleDuration = Date().timeIntervalSince(wasIdleSince)
                let longAbsenceThreshold = TimeInterval(longAbsenceThresholdMinutes * 60)

                isUserIdle = false
                idleStartTime = nil

                Logger.activityMonitor.info("User became active after \(idleDuration)s idle")

                if idleDuration >= longAbsenceThreshold {
                    Logger.activityMonitor.info("Long absence detected (\(idleDuration)s), triggering cycle reset")
                    onLongAbsenceReturn?()
                } else {
                    onUserBecameActive?()
                }
            }
        }
    }

    // MARK: - Screen Sleep/Wake

    private func observeScreenSleepWake() {
        let workspace = NSWorkspace.shared
        let notificationCenter = workspace.notificationCenter

        screenSleepObserver = notificationCenter.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenSleep()
            }
        }

        screenWakeObserver = notificationCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenWake()
            }
        }

        Logger.activityMonitor.info("Screen sleep/wake observers registered")
    }

    private func handleScreenSleep() {
        Logger.activityMonitor.info("Screen went to sleep")
        isScreenAsleep = true
        if !isUserIdle {
            isUserIdle = true
            idleStartTime = .now
            onUserBecameIdle?()
        }
    }

    private func handleScreenWake() {
        Logger.activityMonitor.info("Screen woke up")
        isScreenAsleep = false
        // Let the next polling cycle handle the return-from-idle logic
        // so we can accurately measure idle duration
    }

    private func removeScreenObservers() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        if let observer = screenSleepObserver {
            notificationCenter.removeObserver(observer)
        }
        if let observer = screenWakeObserver {
            notificationCenter.removeObserver(observer)
        }
        screenSleepObserver = nil
        screenWakeObserver = nil
        Logger.activityMonitor.info("Screen sleep/wake observers removed")
    }
}
