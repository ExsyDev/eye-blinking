import SwiftUI
import os.log

struct MenuBarView: View {
    @EnvironmentObject var breakTimer: BreakTimerService
    @EnvironmentObject var blinkReminder: BlinkReminderService
    @EnvironmentObject var settings: AppSettings
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Timer Status
            timerStatusSection

            Divider()
                .padding(.vertical, 4)

            // MARK: - Controls
            controlsSection

            Divider()
                .padding(.vertical, 4)

            // MARK: - Today's Stats
            todayStatsSection

            Divider()
                .padding(.vertical, 4)

            // MARK: - Footer
            footerSection
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 260)
    }

    // MARK: - Timer Status

    @ViewBuilder
    private var timerStatusSection: some View {
        HStack {
            Image(systemName: timerIcon)
                .foregroundStyle(timerColor)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(timerStatusText)
                    .font(.headline)

                Text(breakTimer.state.formattedTime)
                    .font(.system(.title2, design: .monospaced))
                    .foregroundStyle(timerColor)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var timerIcon: String {
        switch breakTimer.state {
        case .running: return "timer"
        case .paused: return "pause.circle"
        case .onBreak: return "eye"
        case .stopped: return "stop.circle"
        }
    }

    private var timerColor: Color {
        switch breakTimer.state {
        case .running: return .green
        case .paused: return .orange
        case .onBreak: return .blue
        case .stopped: return .secondary
        }
    }

    private var timerStatusText: String {
        switch breakTimer.state {
        case .running:
            return String(localized: "Next break in")
        case .paused:
            return String(localized: "Paused")
        case .onBreak:
            return String(localized: "On break")
        case .stopped:
            return String(localized: "Timer stopped")
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var controlsSection: some View {
        // Break timer toggle
        Toggle(isOn: $settings.isBreakTimerEnabled) {
            Label(String(localized: "Break Reminders"), systemImage: "timer")
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .padding(.vertical, 2)

        // Blink reminder toggle
        Toggle(isOn: $settings.isBlinkReminderEnabled) {
            Label(String(localized: "Blink Reminders"), systemImage: "eye.trianglebadge.exclamationmark")
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .padding(.vertical, 2)

        // Take/Skip break buttons
        if breakTimer.state.isRunning || breakTimer.state.isPaused {
            HStack(spacing: 8) {
                Button {
                    Logger.ui.info("User tapped 'Take Break Now'")
                    breakTimer.takeBreakNow()
                } label: {
                    Label(String(localized: "Take Break Now"), systemImage: "eye")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                if breakTimer.state.isPaused {
                    Button {
                        Logger.ui.info("User tapped 'Resume'")
                        breakTimer.resume()
                    } label: {
                        Label(String(localized: "Resume"), systemImage: "play.fill")
                    }
                    .controlSize(.small)
                }
            }
            .padding(.vertical, 4)
        }

        if breakTimer.state.isOnBreak {
            Button {
                Logger.ui.info("User tapped 'Skip Break'")
                breakTimer.skipBreak()
            } label: {
                Label(String(localized: "Skip Break"), systemImage: "forward.fill")
            }
            .controlSize(.small)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Today's Stats

    @ViewBuilder
    private var todayStatsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "Today"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                StatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(breakTimer.breaksTakenToday)",
                    label: String(localized: "Taken"),
                    color: .green
                )

                StatItem(
                    icon: "xmark.circle.fill",
                    value: "\(breakTimer.breaksSkippedToday)",
                    label: String(localized: "Skipped"),
                    color: .red
                )
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerSection: some View {
        HStack {
            Button {
                Logger.ui.info("[FIX] Settings button tapped — activating app and opening Settings")
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            } label: {
                Label(String(localized: "Settings..."), systemImage: "gear")
            }

            Spacer()

            Button {
                Logger.ui.info("User tapped Quit")
                NSApplication.shared.terminate(nil)
            } label: {
                Label(String(localized: "Quit"), systemImage: "power")
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)

            Text(value)
                .font(.system(.body, design: .monospaced, weight: .semibold))

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
