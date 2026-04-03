import AppKit
import os.log

/// A borderless NSPanel at .screenSaver level that covers all screens for break overlay.
/// Handles Esc key to dismiss and prevents user interaction with other windows.
final class BreakOverlayPanel: NSPanel {
    init(for screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        isReleasedWhenClosed = false
        hidesOnDeactivate = false

        Logger.ui.info("BreakOverlayPanel created for screen: \(screen.localizedName, privacy: .public) frame: \(screen.frame.debugDescription, privacy: .public)")
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Handle Esc key to skip the break.
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Esc key
            Logger.ui.info("Esc pressed on BreakOverlayPanel, posting skip notification")
            NotificationCenter.default.post(name: .breakOverlaySkipRequested, object: nil)
        } else {
            super.keyDown(with: event)
        }
    }
}

// MARK: - Notification

extension Notification.Name {
    static let breakOverlaySkipRequested = Notification.Name("breakOverlaySkipRequested")
}
