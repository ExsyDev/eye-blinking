import os.log
import Foundation

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.dimkg.EyeBlinking"

    /// General app lifecycle events
    static let app = Logger(subsystem: subsystem, category: "app")

    /// Break timer service events
    static let breakTimer = Logger(subsystem: subsystem, category: "breakTimer")

    /// Blink reminder service events
    static let blinkReminder = Logger(subsystem: subsystem, category: "blinkReminder")

    /// Activity monitoring events
    static let activityMonitor = Logger(subsystem: subsystem, category: "activityMonitor")

    /// Statistics and data persistence events
    static let statistics = Logger(subsystem: subsystem, category: "statistics")

    /// UI-related events
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
