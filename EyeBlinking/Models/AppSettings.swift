import Foundation
import os.log

/// Centralized app settings backed by @AppStorage (UserDefaults).
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // MARK: - Break Timer

    @Published var breakIntervalMinutes: Int {
        didSet {
            UserDefaults.standard.set(breakIntervalMinutes, forKey: Keys.breakIntervalMinutes)
            Logger.app.info("Setting breakIntervalMinutes changed to \(self.breakIntervalMinutes)")
        }
    }

    @Published var breakDurationSeconds: Int {
        didSet {
            UserDefaults.standard.set(breakDurationSeconds, forKey: Keys.breakDurationSeconds)
            Logger.app.info("Setting breakDurationSeconds changed to \(self.breakDurationSeconds)")
        }
    }

    @Published var isBreakTimerEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBreakTimerEnabled, forKey: Keys.isBreakTimerEnabled)
            Logger.app.info("Setting isBreakTimerEnabled changed to \(self.isBreakTimerEnabled)")
        }
    }

    // MARK: - Blink Reminder

    @Published var blinkIntervalSeconds: Int {
        didSet {
            UserDefaults.standard.set(blinkIntervalSeconds, forKey: Keys.blinkIntervalSeconds)
            Logger.app.info("Setting blinkIntervalSeconds changed to \(self.blinkIntervalSeconds)")
        }
    }

    @Published var isBlinkReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBlinkReminderEnabled, forKey: Keys.isBlinkReminderEnabled)
            Logger.app.info("Setting isBlinkReminderEnabled changed to \(self.isBlinkReminderEnabled)")
        }
    }

    // MARK: - Sound

    @Published var isBreakSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBreakSoundEnabled, forKey: Keys.isBreakSoundEnabled)
            Logger.app.info("Setting isBreakSoundEnabled changed to \(self.isBreakSoundEnabled)")
        }
    }

    @Published var isBlinkSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBlinkSoundEnabled, forKey: Keys.isBlinkSoundEnabled)
            Logger.app.info("Setting isBlinkSoundEnabled changed to \(self.isBlinkSoundEnabled)")
        }
    }

    // MARK: - General

    @Published var breakMode: BreakMode {
        didSet {
            UserDefaults.standard.set(breakMode.rawValue, forKey: Keys.breakMode)
            Logger.app.info("Setting breakMode changed to \(self.breakMode.rawValue)")
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
            Logger.app.info("Setting launchAtLogin changed to \(self.launchAtLogin)")
        }
    }

    @Published var idleThresholdMinutes: Int {
        didSet {
            UserDefaults.standard.set(idleThresholdMinutes, forKey: Keys.idleThresholdMinutes)
            Logger.app.info("Setting idleThresholdMinutes changed to \(self.idleThresholdMinutes)")
        }
    }

    // MARK: - Init

    private init() {
        let defaults = UserDefaults.standard

        // Register defaults
        defaults.register(defaults: [
            Keys.breakIntervalMinutes: 20,
            Keys.breakDurationSeconds: 20,
            Keys.isBreakTimerEnabled: true,
            Keys.blinkIntervalSeconds: 15,
            Keys.isBlinkReminderEnabled: true,
            Keys.isBreakSoundEnabled: true,
            Keys.isBlinkSoundEnabled: true,
            Keys.breakMode: BreakMode.fullscreenOverlay.rawValue,
            Keys.launchAtLogin: false,
            Keys.idleThresholdMinutes: 3,
        ])

        self.breakIntervalMinutes = defaults.integer(forKey: Keys.breakIntervalMinutes)
        self.breakDurationSeconds = defaults.integer(forKey: Keys.breakDurationSeconds)
        self.isBreakTimerEnabled = defaults.bool(forKey: Keys.isBreakTimerEnabled)
        self.blinkIntervalSeconds = defaults.integer(forKey: Keys.blinkIntervalSeconds)
        self.isBlinkReminderEnabled = defaults.bool(forKey: Keys.isBlinkReminderEnabled)
        self.isBreakSoundEnabled = defaults.bool(forKey: Keys.isBreakSoundEnabled)
        self.isBlinkSoundEnabled = defaults.bool(forKey: Keys.isBlinkSoundEnabled)
        self.breakMode = BreakMode(rawValue: defaults.string(forKey: Keys.breakMode) ?? "") ?? .fullscreenOverlay
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.idleThresholdMinutes = defaults.integer(forKey: Keys.idleThresholdMinutes)

        Logger.app.info("AppSettings initialized: breakInterval=\(self.breakIntervalMinutes)m, blinkInterval=\(self.blinkIntervalSeconds)s, breakMode=\(self.breakMode.rawValue)")
    }

    // MARK: - Keys

    private enum Keys {
        static let breakIntervalMinutes = "breakIntervalMinutes"
        static let breakDurationSeconds = "breakDurationSeconds"
        static let isBreakTimerEnabled = "isBreakTimerEnabled"
        static let blinkIntervalSeconds = "blinkIntervalSeconds"
        static let isBlinkReminderEnabled = "isBlinkReminderEnabled"
        static let isBreakSoundEnabled = "isBreakSoundEnabled"
        static let isBlinkSoundEnabled = "isBlinkSoundEnabled"
        static let breakMode = "breakMode"
        static let launchAtLogin = "launchAtLogin"
        static let idleThresholdMinutes = "idleThresholdMinutes"
    }
}
