import Foundation
import SwiftData

/// A single day's statistics entry, persisted with SwiftData.
@Model
final class StatisticsEntry {
    /// The date this entry represents (normalized to start of day).
    var date: Date

    /// Number of breaks taken (completed).
    var breaksTaken: Int

    /// Number of breaks skipped.
    var breaksSkipped: Int

    /// Total active screen time in seconds for this day.
    var screenTimeSeconds: Int

    /// Timestamp of last update.
    var lastUpdated: Date

    init(
        date: Date = Calendar.current.startOfDay(for: .now),
        breaksTaken: Int = 0,
        breaksSkipped: Int = 0,
        screenTimeSeconds: Int = 0
    ) {
        self.date = date
        self.breaksTaken = breaksTaken
        self.breaksSkipped = breaksSkipped
        self.screenTimeSeconds = screenTimeSeconds
        self.lastUpdated = .now
    }

    /// Compliance ratio: breaks taken / total breaks (taken + skipped).
    var complianceRate: Double {
        let total = breaksTaken + breaksSkipped
        guard total > 0 else { return 0 }
        return Double(breaksTaken) / Double(total)
    }

    /// Formatted screen time as "Xh Ym".
    var formattedScreenTime: String {
        let hours = screenTimeSeconds / 3600
        let minutes = (screenTimeSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
