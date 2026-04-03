import Foundation
import SwiftData
import os.log

/// Manages statistics persistence with SwiftData.
/// Records break events, tracks screen time, and provides aggregated data for display.
@MainActor
final class StatisticsService: ObservableObject {
    // MARK: - Published State

    @Published private(set) var todayEntry: StatisticsEntry?
    @Published private(set) var weeklyEntries: [StatisticsEntry] = []
    @Published private(set) var currentStreak: Int = 0

    // MARK: - Private

    let modelContainer: ModelContainer
    private var modelContext: ModelContext
    private var screenTimeTimer: Timer?

    init() {
        Logger.statistics.info("StatisticsService initializing ModelContainer")

        do {
            let schema = Schema([StatisticsEntry.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = ModelContext(modelContainer)
            Logger.statistics.info("ModelContainer initialized successfully")
        } catch {
            Logger.statistics.error("Failed to initialize ModelContainer: \(error.localizedDescription)")
            fatalError("Failed to create ModelContainer: \(error)")
        }

        loadTodayEntry()
        loadWeeklyEntries()
        calculateStreak()
    }

    // MARK: - Event Recording

    /// Record that a break was taken (completed).
    func recordBreakTaken() {
        let entry = getOrCreateTodayEntry()
        entry.breaksTaken += 1
        entry.lastUpdated = .now
        save()
        Logger.statistics.info("Break taken recorded. Today total: \(entry.breaksTaken)")
        refreshPublishedState()
    }

    /// Record that a break was skipped.
    func recordBreakSkipped() {
        let entry = getOrCreateTodayEntry()
        entry.breaksSkipped += 1
        entry.lastUpdated = .now
        save()
        Logger.statistics.info("Break skipped recorded. Today total: \(entry.breaksSkipped)")
        refreshPublishedState()
    }

    /// Add screen time seconds to today's entry.
    func addScreenTime(seconds: Int) {
        let entry = getOrCreateTodayEntry()
        entry.screenTimeSeconds += seconds
        entry.lastUpdated = .now
        save()
        Logger.statistics.debug("Screen time added: \(seconds)s. Today total: \(entry.screenTimeSeconds)s")
    }

    /// Start tracking screen time (call when user becomes active).
    func startScreenTimeTracking() {
        stopScreenTimeTracking()
        screenTimeTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.addScreenTime(seconds: 60)
            }
        }
        Logger.statistics.info("Screen time tracking started (1-min intervals)")
    }

    /// Stop tracking screen time (call when user becomes idle).
    func stopScreenTimeTracking() {
        screenTimeTimer?.invalidate()
        screenTimeTimer = nil
        Logger.statistics.debug("Screen time tracking stopped")
    }

    // MARK: - Data Loading

    private func loadTodayEntry() {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let predicate = #Predicate<StatisticsEntry> { entry in
            entry.date == startOfDay
        }
        let descriptor = FetchDescriptor<StatisticsEntry>(predicate: predicate)

        do {
            let results = try modelContext.fetch(descriptor)
            todayEntry = results.first
            Logger.statistics.info("Today's entry loaded: \(results.first != nil ? "found" : "none")")
        } catch {
            Logger.statistics.error("Failed to load today's entry: \(error.localizedDescription)")
        }
    }

    private func loadWeeklyEntries() {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: .now)) else {
            return
        }

        let predicate = #Predicate<StatisticsEntry> { entry in
            entry.date >= weekAgo
        }
        let descriptor = FetchDescriptor<StatisticsEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        do {
            weeklyEntries = try modelContext.fetch(descriptor)
            Logger.statistics.info("Weekly entries loaded: \(self.weeklyEntries.count) days")
        } catch {
            Logger.statistics.error("Failed to load weekly entries: \(error.localizedDescription)")
        }
    }

    // MARK: - Streak Calculation

    private func calculateStreak() {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: .now)

        // Check today first — if no breaks yet today, start from yesterday
        if let todayEntry, todayEntry.breaksTaken > 0 && todayEntry.complianceRate >= 0.5 {
            streak = 1
        }

        // Walk backwards through previous days
        while true {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay

            let predicate = #Predicate<StatisticsEntry> { entry in
                entry.date == previousDay
            }
            let descriptor = FetchDescriptor<StatisticsEntry>(predicate: predicate)

            do {
                let results = try modelContext.fetch(descriptor)
                guard let entry = results.first,
                      entry.breaksTaken > 0,
                      entry.complianceRate >= 0.5 else {
                    break
                }
                streak += 1
            } catch {
                Logger.statistics.error("Streak calculation error for \(previousDay): \(error.localizedDescription)")
                break
            }
        }

        currentStreak = streak
        Logger.statistics.info("Current streak calculated: \(streak) days")
    }

    // MARK: - Helpers

    private func getOrCreateTodayEntry() -> StatisticsEntry {
        if let todayEntry {
            return todayEntry
        }

        let entry = StatisticsEntry()
        modelContext.insert(entry)
        todayEntry = entry
        Logger.statistics.info("Created new StatisticsEntry for today")
        return entry
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            Logger.statistics.error("Failed to save model context: \(error.localizedDescription)")
        }
    }

    private func refreshPublishedState() {
        loadTodayEntry()
        loadWeeklyEntries()
        calculateStreak()
    }
}
