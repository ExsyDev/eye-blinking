import Foundation

/// Current state of the break timer cycle.
enum TimerState: Equatable {
    /// Timer is counting down to the next break.
    case running(secondsRemaining: Int)

    /// Timer is paused (user-initiated or idle detection).
    case paused(secondsRemaining: Int)

    /// A break is currently active with countdown.
    case onBreak(secondsRemaining: Int)

    /// Timer is fully stopped / disabled.
    case stopped

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    var isPaused: Bool {
        if case .paused = self { return true }
        return false
    }

    var isOnBreak: Bool {
        if case .onBreak = self { return true }
        return false
    }

    var secondsRemaining: Int? {
        switch self {
        case .running(let s), .paused(let s), .onBreak(let s):
            return s
        case .stopped:
            return nil
        }
    }

    /// Formatted remaining time as "MM:SS".
    var formattedTime: String {
        guard let seconds = secondsRemaining else { return "--:--" }
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
