import Foundation

@MainActor
final class CodingStatsStore {
    private enum Constants {
        static let storageKey = "bugpet.native.coding-stats.v1"
        static let retainedDays = 366 * 5
        static let maxElapsed: TimeInterval = 10
    }

    private struct DailyStats: Codable {
        var focusedSeconds: TimeInterval
        var codingSeconds: TimeInterval
    }

    private struct StoredStats: Codable {
        var days: [String: DailyStats]
        var totalCodingSeconds: TimeInterval
    }

    private let defaults: UserDefaults
    private let calendar = Calendar.autoupdatingCurrent
    private let formatter: DateFormatter
    private var stored: StoredStats
    private var lastTickAt = Date()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"

        if let data = defaults.data(forKey: Constants.storageKey),
           let decoded = try? JSONDecoder().decode(StoredStats.self, from: data) {
            stored = decoded
        } else {
            stored = StoredStats(days: [:], totalCodingSeconds: 0)
        }

        trimHistory(referenceDate: .now)
    }

    func recordSample(isCodingContext: Bool, isFocused: Bool, now: Date) {
        let elapsed = max(0, min(now.timeIntervalSince(lastTickAt), Constants.maxElapsed))
        lastTickAt = now

        guard elapsed > 0, isCodingContext else {
            return
        }

        let key = dayKey(for: now)
        var day = stored.days[key] ?? DailyStats(focusedSeconds: 0, codingSeconds: 0)
        day.codingSeconds += elapsed
        if isFocused {
            day.focusedSeconds += elapsed
        }

        stored.days[key] = day
        stored.totalCodingSeconds += elapsed
        trimHistory(referenceDate: now)
        persist()
    }

    func summary(now: Date) -> CodingStatsSummary {
        let startOfToday = calendar.startOfDay(for: now)
        let todayKey = dayKey(for: startOfToday)
        let todayStats = stored.days[todayKey] ?? DailyStats(focusedSeconds: 0, codingSeconds: 0)
        let currentMonthCodingSeconds = stored.days.reduce(into: 0.0) { partialResult, entry in
            guard let date = formatter.date(from: entry.key),
                  calendar.isDate(date, equalTo: now, toGranularity: .month) else {
                return
            }
            partialResult += entry.value.codingSeconds
        }

        let contributionDays = stored.days.compactMap { key, stats -> ContributionDay? in
            guard let date = formatter.date(from: key) else {
                return nil
            }

            return ContributionDay(
                date: date,
                focusedMinutes: Int(stats.focusedSeconds / 60)
            )
        }
        .sorted { $0.date < $1.date }

        let years = Set(contributionDays.map { calendar.component(.year, from: $0.date) } + [calendar.component(.year, from: now)])

        return CodingStatsSummary(
            contributionDays: contributionDays,
            availableYears: years.sorted(),
            todayCodingSeconds: todayStats.codingSeconds,
            currentMonthCodingSeconds: currentMonthCodingSeconds,
            totalCodingSeconds: stored.totalCodingSeconds
        )
    }

    private func dayKey(for date: Date) -> String {
        formatter.string(from: date)
    }

    private func trimHistory(referenceDate: Date) {
        guard let cutoffDate = calendar.date(byAdding: .day, value: -Constants.retainedDays, to: referenceDate) else {
            return
        }

        stored.days = stored.days.filter { key, _ in
            guard let date = formatter.date(from: key) else {
                return false
            }

            return date >= cutoffDate
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(stored)
            defaults.set(data, forKey: Constants.storageKey)
        } catch {
            NSLog("Failed to persist coding stats: \(error.localizedDescription)")
        }
    }
}
