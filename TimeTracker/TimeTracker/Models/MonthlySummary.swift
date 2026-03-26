//
//  MonthlySummary.swift
//  TimeTracker
//
//  月度时间账本（F-21）
//  按月汇总各分类时间，对比上月变化
//

import Foundation

/// 月度汇总数据
struct MonthlySummary: Identifiable {
    let id = UUID()
    let year: Int
    let month: Int
    let dailySummaries: [DailySummary]

    // MARK: - Computed Properties

    /// 月份显示名
    var displayName: String {
        "\(year)年\(month)月"
    }

    /// 月份短显示名
    var shortDisplayName: String {
        "\(month)月"
    }

    /// 本月每个分类的总时间
    var totalTimePerCategory: [TimeCategory: TimeInterval] {
        var result: [TimeCategory: TimeInterval] = [:]
        for cat in TimeCategory.allCases {
            result[cat] = dailySummaries.reduce(0) {
                $0 + ($1.totalTimePerCategory[cat] ?? 0)
            }
        }
        return result
    }

    /// 本月总记录时间
    var totalTrackedTime: TimeInterval {
        dailySummaries.reduce(0) { $0 + $1.totalTrackedTime }
    }

    /// 本月记录天数
    var recordedDays: Int {
        dailySummaries.filter { $0.totalTrackedTime > 600 }.count
    }

    /// 本月总天数
    var totalDays: Int {
        let calendar = Calendar.current
        guard let date = calendar.date(from: DateComponents(year: year, month: month)),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }

    /// 平均每日记录时间
    var averageDailyTime: TimeInterval {
        guard recordedDays > 0 else { return 0 }
        return totalTrackedTime / Double(recordedDays)
    }

    /// 各分类占比
    func ratio(for category: TimeCategory) -> Double {
        guard totalTrackedTime > 0 else { return 0 }
        return (totalTimePerCategory[category] ?? 0) / totalTrackedTime
    }

    /// 格式化总时间
    var formattedTotalTime: String {
        formatInterval(totalTrackedTime)
    }

    /// 格式化某分类时间
    func formattedTime(for category: TimeCategory) -> String {
        formatInterval(totalTimePerCategory[category] ?? 0)
    }

    /// 格式化某分类时间（小时数）
    func hours(for category: TimeCategory) -> String {
        let time = totalTimePerCategory[category] ?? 0
        let h = time / 3600
        return String(format: "%.1f", h)
    }

    /// 月度洞察
    var insights: [String] {
        var tips: [String] = []

        let outputRatio = ratio(for: .output)
        let inputRatio = ratio(for: .input)
        let consumptionRatio = ratio(for: .consumption)

        if outputRatio >= 0.15 {
            tips.append("本月输出占比 \(Int(outputRatio * 100))%，保持高效产出！")
        } else if outputRatio < 0.10 {
            tips.append("本月输出占比仅 \(Int(outputRatio * 100))%，建议增加创作时间")
        }

        if consumptionRatio > 0.25 {
            tips.append("本月消耗占比 \(Int(consumptionRatio * 100))%，超过建议阈值")
        }

        if inputRatio >= 0.20 {
            tips.append("本月输入充足（\(Int(inputRatio * 100))%），知识积累良好")
        }

        if recordedDays < totalDays / 2 {
            tips.append("本月仅记录 \(recordedDays) 天，试试每天坚持记录")
        } else if recordedDays >= totalDays - 3 {
            tips.append("本月记录 \(recordedDays) 天，记录习惯非常好！")
        }

        return tips
    }

    private func formatInterval(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - 月度变化对比
struct MonthlyComparison {
    let current: MonthlySummary
    let previous: MonthlySummary?

    /// 某分类在上月的占比变化（当前 - 上月）
    func ratioChange(for category: TimeCategory) -> Double? {
        guard let prev = previous, prev.totalTrackedTime > 0 else { return nil }
        return current.ratio(for: category) - prev.ratio(for: category)
    }

    /// 总记录时间变化百分比
    var totalTimeChangePercent: Double? {
        guard let prev = previous, prev.totalTrackedTime > 0 else { return nil }
        return (current.totalTrackedTime - prev.totalTrackedTime) / prev.totalTrackedTime
    }

    /// 一句话总结
    var summary: String {
        guard let prev = previous else {
            return "本月开始记录，共计 \(current.formattedTotalTime)"
        }

        let change = totalTimeChangePercent ?? 0
        let direction = change >= 0 ? "增加" : "减少"
        let percent = Int(abs(change) * 100)
        return "较上月\(direction) \(percent)%，总计 \(current.formattedTotalTime)"
    }
}

// MARK: - Factory
extension MonthlySummary {
    /// 从 TimeEntry 数组生成月汇总
    static func from(entries: [TimeEntry], year: Int, month: Int) -> MonthlySummary {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: DateComponents(year: year, month: month)),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else {
            return MonthlySummary(year: year, month: month, dailySummaries: [])
        }

        var dailies: [DailySummary] = []
        for day in range {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                dailies.append(DailySummary.from(entries: entries, date: date))
            }
        }

        return MonthlySummary(
            year: year,
            month: month,
            dailySummaries: dailies
        )
    }
}
