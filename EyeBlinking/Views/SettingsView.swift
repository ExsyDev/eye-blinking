import SwiftUI
import ServiceManagement
import os.log

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        TabView {
            GeneralTab(settings: settings)
                .tabItem {
                    Label(String(localized: "General"), systemImage: "gear")
                }

            BlinkTab(settings: settings)
                .tabItem {
                    Label(String(localized: "Blink"), systemImage: "eye")
                }

            SoundTab(settings: settings)
                .tabItem {
                    Label(String(localized: "Sound"), systemImage: "speaker.wave.2")
                }

            AboutTab()
                .tabItem {
                    Label(String(localized: "About"), systemImage: "info.circle")
                }
        }
        .frame(width: 420, height: 300)
    }
}

// MARK: - General Tab

private struct GeneralTab: View {
    @ObservedObject var settings: AppSettings
    @State private var launchAtLoginError: String?

    var body: some View {
        Form {
            Section {
                Picker(String(localized: "Break mode"), selection: $settings.breakMode) {
                    ForEach(BreakMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                Stepper(
                    value: $settings.breakIntervalMinutes,
                    in: 5...60,
                    step: 5
                ) {
                    HStack {
                        Text(String(localized: "Break every"))
                        Spacer()
                        Text("\(settings.breakIntervalMinutes) min")
                            .foregroundStyle(.secondary)
                    }
                }

                Stepper(
                    value: $settings.breakDurationSeconds,
                    in: 10...60,
                    step: 5
                ) {
                    HStack {
                        Text(String(localized: "Break duration"))
                        Spacer()
                        Text("\(settings.breakDurationSeconds) sec")
                            .foregroundStyle(.secondary)
                    }
                }

                Stepper(
                    value: $settings.idleThresholdMinutes,
                    in: 1...15,
                    step: 1
                ) {
                    HStack {
                        Text(String(localized: "Idle threshold"))
                        Spacer()
                        Text("\(settings.idleThresholdMinutes) min")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Toggle(String(localized: "Launch at login"), isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { _, newValue in
                        updateLaunchAtLogin(newValue)
                    }

                if let error = launchAtLoginError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                Logger.app.info("Launch at login registered")
            } else {
                try SMAppService.mainApp.unregister()
                Logger.app.info("Launch at login unregistered")
            }
            launchAtLoginError = nil
        } catch {
            Logger.app.error("Failed to update launch at login: \(error.localizedDescription)")
            launchAtLoginError = error.localizedDescription
        }
    }
}

// MARK: - Blink Tab

private struct BlinkTab: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle(String(localized: "Enable blink reminders"), isOn: $settings.isBlinkReminderEnabled)

                Stepper(
                    value: $settings.blinkIntervalSeconds,
                    in: 5...60,
                    step: 5
                ) {
                    HStack {
                        Text(String(localized: "Remind every"))
                        Spacer()
                        Text("\(settings.blinkIntervalSeconds) sec")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!settings.isBlinkReminderEnabled)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Sound Tab

private struct SoundTab: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle(String(localized: "Break reminder sound"), isOn: $settings.isBreakSoundEnabled)
                Toggle(String(localized: "Blink reminder sound"), isOn: $settings.isBlinkSoundEnabled)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About Tab

private struct AboutTab: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Eye Blinking")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(String(localized: "Protect your eyes with regular breaks and blink reminders."))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
