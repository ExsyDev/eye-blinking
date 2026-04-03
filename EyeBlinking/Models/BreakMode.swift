import Foundation

/// How the break reminder is displayed to the user.
enum BreakMode: String, CaseIterable, Identifiable {
    case fullscreenOverlay = "fullscreenOverlay"
    case notification = "notification"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullscreenOverlay:
            return String(localized: "Fullscreen Overlay")
        case .notification:
            return String(localized: "System Notification")
        }
    }
}
