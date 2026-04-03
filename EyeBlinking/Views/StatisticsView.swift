import SwiftUI
import Charts
import os.log

/// Shows today's summary and a weekly bar chart of break compliance.
struct StatisticsView: View {
    @EnvironmentObject var statisticsService: StatisticsService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Today's Summary
            todaySummarySection

            Divider()

            // MARK: - Weekly Chart
            weeklyChartSection

            // MARK: - Streak
            if statisticsService.currentStreak > 0 {
                streakSection
            }
        }
        .padding()
        .frame(width: 300)
    }

    // MARK: - Today's Summary

    @ViewBuilder
    private var todaySummarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Today"))
                .font(.headline)

            if let entry = statisticsService.todayEntry {
                HStack(spacing: 20) {
                    SummaryItem(
                        title: String(localized: "Breaks Taken"),
                        value: "\(entry.breaksTaken)",
                        color: .green
                    )

                    SummaryItem(
                        title: String(localized: "Breaks Skipped"),
                        value: "\(entry.breaksSkipped)",
                        color: .red
                    )

                    SummaryItem(
                        title: String(localized: "Screen Time"),
                        value: entry.formattedScreenTime,
                        color: .blue
                    )
                }

                // Compliance bar
                if entry.breaksTaken + entry.breaksSkipped > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Compliance"))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.gray.opacity(0.2))

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(complianceColor(entry.complianceRate))
                                    .frame(width: geometry.size.width * entry.complianceRate)
                            }
                        }
                        .frame(height: 8)

                        Text("\(Int(entry.complianceRate * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text(String(localized: "No data yet today"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Weekly Chart

    @ViewBuilder
    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "This Week"))
                .font(.headline)

            if statisticsService.weeklyEntries.isEmpty {
                Text(String(localized: "No data available"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 120)
            } else {
                Chart(statisticsService.weeklyEntries, id: \.date) { entry in
                    BarMark(
                        x: .value("Day", entry.date, unit: .day),
                        y: .value("Taken", entry.breaksTaken)
                    )
                    .foregroundStyle(.green.opacity(0.8))

                    BarMark(
                        x: .value("Day", entry.date, unit: .day),
                        y: .value("Skipped", entry.breaksSkipped)
                    )
                    .foregroundStyle(.red.opacity(0.6))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartForegroundStyleScale([
                    String(localized: "Taken"): .green.opacity(0.8),
                    String(localized: "Skipped"): .red.opacity(0.6),
                ])
                .frame(height: 120)
            }
        }
    }

    // MARK: - Streak

    @ViewBuilder
    private var streakSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text(String(localized: "\(statisticsService.currentStreak)-day streak"))
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func complianceColor(_ rate: Double) -> Color {
        if rate >= 0.8 { return .green }
        if rate >= 0.5 { return .orange }
        return .red
    }
}

// MARK: - Summary Item

private struct SummaryItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(.title3, design: .monospaced, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}
