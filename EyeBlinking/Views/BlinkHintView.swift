import SwiftUI
import AppKit
import os.log

/// A small floating hint view that appears in the screen corner to remind the user to blink.
/// Non-interactive, fades in and out over 1.5 seconds.
struct BlinkHintView: View {
    @State private var opacity: Double = 0.0

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "eye.trianglebadge.exclamationmark")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))

            Text(String(localized: "Blink!"))
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
        .opacity(opacity)
        .onAppear {
            Logger.ui.debug("BlinkHintView appeared, starting fade-in")
            // Fade in
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1.0
            }
            // Fade out after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 0.0
                }
            }
        }
    }
}

// MARK: - Blink Hint Window Controller

/// Manages a floating non-interactive panel for blink hints in the bottom-right corner.
@MainActor
final class BlinkHintController: ObservableObject {
    private var panel: NSPanel?

    /// Show the blink hint on the main screen.
    func show() {
        Logger.ui.info("BlinkHintController.show()")
        dismiss()

        guard let screen = NSScreen.main else {
            Logger.ui.error("BlinkHintController: no main screen available")
            return
        }

        let hintWidth: CGFloat = 160
        let hintHeight: CGFloat = 48
        let padding: CGFloat = 20

        // Position in bottom-right corner
        let originX = screen.visibleFrame.maxX - hintWidth - padding
        let originY = screen.visibleFrame.minY + padding
        let frame = NSRect(x: originX, y: originY, width: hintWidth, height: hintHeight)

        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false

        let hostingView = NSHostingView(rootView: BlinkHintView())
        hostingView.frame = NSRect(x: 0, y: 0, width: hintWidth, height: hintHeight)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView?.addSubview(hostingView)

        panel.orderFrontRegardless()
        self.panel = panel

        Logger.ui.debug("Blink hint panel shown at \(frame.debugDescription, privacy: .public)")

        // Auto-dismiss after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.dismiss()
        }
    }

    /// Dismiss the hint panel.
    func dismiss() {
        guard let panel else { return }
        Logger.ui.debug("BlinkHintController dismissing panel")
        panel.orderOut(nil)
        panel.close()
        self.panel = nil
    }
}
