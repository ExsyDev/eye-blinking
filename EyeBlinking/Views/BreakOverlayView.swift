import SwiftUI
import os.log

/// Fullscreen dark overlay shown during a break.
/// Displays a countdown timer, progress dots, motivational text, and a skip button.
struct BreakOverlayView: View {
    let totalSeconds: Int
    let secondsRemaining: Int
    let onSkip: () -> Void

    @State private var appeared = false

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - secondsRemaining) / Double(totalSeconds)
    }

    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(appeared ? 0.85 : 0.0)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Eye icon
                Image(systemName: "eye")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.8))
                    .scaleEffect(appeared ? 1.0 : 0.5)

                // Motivational text
                Text(String(localized: "Look at something 20 feet away"))
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)

                // Countdown
                Text(formattedCountdown)
                    .font(.system(size: 72, weight: .light, design: .monospaced))
                    .foregroundStyle(.white)

                // Progress dots
                progressDots

                Spacer()

                // Skip button
                Button {
                    Logger.ui.info("User tapped Skip button on overlay")
                    onSkip()
                } label: {
                    Text(String(localized: "Skip (Esc)"))
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 48)
            }
            .opacity(appeared ? 1.0 : 0.0)
        }
        .onAppear {
            Logger.ui.info("BreakOverlayView appeared, totalSeconds=\(self.totalSeconds)")
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }

    // MARK: - Countdown

    private var formattedCountdown: String {
        let secs = max(0, secondsRemaining)
        return String(format: "%02d", secs)
    }

    // MARK: - Progress Dots

    @ViewBuilder
    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSeconds, id: \.self) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: dotSize, height: dotSize)
            }
        }
        .padding(.horizontal, 32)
    }

    private var dotSize: CGFloat {
        totalSeconds > 30 ? 6 : 8
    }

    private func dotColor(for index: Int) -> Color {
        let elapsed = totalSeconds - secondsRemaining
        if index < elapsed {
            return .green.opacity(0.8)
        } else if index == elapsed {
            return .white
        } else {
            return .white.opacity(0.2)
        }
    }
}

// MARK: - Overlay Window Controller

/// Manages showing/hiding BreakOverlayPanels on all screens.
@MainActor
final class BreakOverlayController: ObservableObject {
    private var panels: [BreakOverlayPanel] = []
    private var skipObserver: Any?

    /// Called when user requests to skip the break (Esc or Skip button).
    var onSkip: (() -> Void)?

    /// Show overlay on all screens.
    func show(totalSeconds: Int, secondsRemaining: Int) {
        Logger.ui.info("BreakOverlayController.show() totalSeconds=\(totalSeconds), secondsRemaining=\(secondsRemaining), screens=\(NSScreen.screens.count)")
        dismiss()

        skipObserver = NotificationCenter.default.addObserver(
            forName: .breakOverlaySkipRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                Logger.ui.info("Skip requested via Esc key notification")
                self?.onSkip?()
            }
        }

        for screen in NSScreen.screens {
            let panel = BreakOverlayPanel(for: screen)

            let overlayView = BreakOverlayView(
                totalSeconds: totalSeconds,
                secondsRemaining: secondsRemaining,
                onSkip: { [weak self] in
                    self?.onSkip?()
                }
            )

            let hostingView = NSHostingView(rootView: overlayView)
            hostingView.frame = panel.contentView?.bounds ?? screen.frame
            hostingView.autoresizingMask = [.width, .height]
            panel.contentView?.addSubview(hostingView)

            panel.orderFrontRegardless()
            panel.makeKey()
            panels.append(panel)

            Logger.ui.debug("Panel shown on screen: \(screen.localizedName, privacy: .public)")
        }
    }

    /// Update the countdown on all panels.
    func updateCountdown(totalSeconds: Int, secondsRemaining: Int) {
        // Recreate hosting views with updated state
        for panel in panels {
            let overlayView = BreakOverlayView(
                totalSeconds: totalSeconds,
                secondsRemaining: secondsRemaining,
                onSkip: { [weak self] in
                    self?.onSkip?()
                }
            )

            if let contentView = panel.contentView {
                contentView.subviews.forEach { $0.removeFromSuperview() }
                let hostingView = NSHostingView(rootView: overlayView)
                hostingView.frame = contentView.bounds
                hostingView.autoresizingMask = [.width, .height]
                contentView.addSubview(hostingView)
            }
        }
    }

    /// Dismiss all overlay panels.
    func dismiss() {
        Logger.ui.info("BreakOverlayController.dismiss() closing \(self.panels.count) panels")

        if let observer = skipObserver {
            NotificationCenter.default.removeObserver(observer)
            skipObserver = nil
        }

        for panel in panels {
            panel.orderOut(nil)
            panel.close()
        }
        panels.removeAll()
    }
}
