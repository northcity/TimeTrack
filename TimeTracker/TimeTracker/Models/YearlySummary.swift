//
//  YearlySummary.swift
//  TimeTracker
//
//  年度累计账本（F-22/23）
//  年度汇总 + 月度趋势 + 年度对比
//

import Foundation

/// 年度汇总数据
struct YearlySummary: Identifiable {
    let id = UUID()
    let year: Int
    let monthlySummaries: [MonthlySummary]

    // MARK: - Computed Properties

    /// 年份显示名
    var displayName: String {
        "\(year)年"
    }

    /// 本年每个分类的总时间
    var totalTimePerCategory: [TimeCategory: TimeInterval] {
        var result: [TimeCategory: TimeInterval] = [:]
        for cat in TimeCategory.allCases {
            result[cat] = monthlySummaries.reduce(0) {
                $0 + ($1.totalTimePerCategory[cat] ?? 0)
            }
        }
        return result
    }

    /// 本年总记录时间
    var totalTrackedTime: TimeInterval {
        monthlySummaries.reduce(0) { $0 + $1.totalTrackedTime }
    }

    /// 本年记录天数
    var recordedDays: Int {
        monthlySummaries.reduce(0) { $0 + $1.recordedDays }
    }

    /// 本年总天数（已过天数）
    var totalDaysInYear: Int {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        if year == currentYear {
            return calendar.ordinality(of: .day, in: .year, for: now) ?? 365
        } else if year < currentYear {
            let isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
            return isLeap ? 366 : 365
        } else {
            return 0
        }
    }

    /// 记录完成率
    var recordCompletionRate: Double {
        guard totalDaysInYear > 0 else { return 0 }
        return Double(recordedDays) / Double(totalDaysInYear)
    }

    /// 平均每日记录时间（仅记录日）
    var averageDailyTime: TimeInterval {
        guard recordedDays > 0 else { return 0 }
        return totalTrackedTime / Double(recordedDays)
    }

    /// 各分类占比
    func ratio(for category: TimeCategory) -> Double {
        guard totalTrackedTime > 0 else { return 0 }
        return (totalTimePerCategory[category] ?? 0) / totalTrackedTime
    }

    /// 月度趋势数据项（Charts 用）
    struct MonthlyTrendItem: Identifiable {
        let id = UUID()
        let month: Int
        let category: TimeCategory
        let hours: Double
    }

    /// 月度趋势数据（各月分类时间）
    var monthlyTrend: [MonthlyTrendItem] {
        var trend: [MonthlyTrendItem] = []
        for summary in monthlySummaries {
            for cat in TimeCategory.allCases {
                let hours = (summary.totalTimePerCategory[cat] ?? 0) / 3600
                if hours > 0 || summary.totalTrackedTime > 0 {
                    trend.append(MonthlyTrendItem(month: summary.month, category: cat, hours: hours))
                }
            }
        }
        return trend
    }

    /// 月度质量评分数据项
    struct MonthlyQualityItem: Identifiable {
        let id = UUID()
        let month: Int
        let score: Double
    }

    /// 月度总时间趋势
    var monthlyTotalHours: [(month: Int, hours: Double)] {
        monthlySummaries.map { (month: $0.month, hours: $0.totalTrackedTime / 3600) }
    }

    /// 月度质量评分趋势（每月平均日评分）
    var monthlyQualityScores: [MonthlyQualityItem] {
        monthlySummaries.compactMap { summary in
            let validDays = summary.dailySummaries.filter { $0.totalTrackedTime > 600 }
            guard !validDays.isEmpty else { return nil }
            let avgScore = validDays.reduce(0.0) { $0 + $1.qualityScore.totalScore } / Double(validDays.count)
            return MonthlyQualityItem(month: summary.month, score: avgScore)
        }
    }

    /// 深度工作年度累计
    var totalDeepWorkCount: Int {
        monthlySummaries.reduce(0) { total, monthly in
            total + monthly.dailySummaries.reduce(0) { $0 + $1.deepWorkCount }
        }
    }

    /// 深度工作年度总时长
    var totalDeepWorkDuration: TimeInterval {
        monthlySummaries.reduce(0) { total, monthly in
            total + monthly.dailySummaries.reduce(0) { $0 + $1.deepWorkDuration }
        }
    }

    /// 最高效的月份
    var bestMonth: MonthlySummary? {
        monthlySummaries
            .filter { $0.totalTrackedTime > 3600 }
            .max(by: {
                let r0 = $0.ratio(for: .output) + $0.ratio(for: .input)
                let r1 = $1.ratio(for: .output) + $1.ratio(for: .input)
                return r0 < r1
            })
    }

    /// 记录最多的月份
    var mostActiveMonth: MonthlySummary? {
        monthlySummaries.max(by: { $0.totalTrackedTime < $1.totalTrackedTime })
    }

    /// 格式化总时间
    var formattedTotalTime: String {
        formatInterval(totalTrackedTime)
    }

    /// 格式化某分类时间
    func formattedTime(for category: TimeCategory) -> String {
        formatInterval(totalTimePerCategory[category] ?? 0)
    }

    /// 小时数
    func hours(for category: TimeCategory) -> String {
        let time = totalTimePerCategory[category] ?? 0
        return String(format: "%.0f", time / 3600)
    }

    /// 总小时数
    var totalHours: String {
        String(format: "%.0f", totalTrackedTime / 3600)
    }

    // MARK: - 年度洞察

    var insights: [String] {
        var tips: [String] = []

        let outputRatio = ratio(for: .output)
        let inputRatio = ratio(for: .input)
        let consumptionRatio = ratio(for: .consumption)

        // 产出洞察
        if outputRatio >= 0.15 {
            tips.append("年度输出占比 \(Int(outputRatio * 100))%，保持高效产出！")
        } else if outputRatio < 0.10 && totalTrackedTime > 0 {
            tips.append("年度输出占比仅 \(Int(outputRatio * 100))%，建议每日固定创作时间")
        }

        // 消耗洞察
        if consumptionRatio > 0.25 && totalTrackedTime > 0 {
            tips.append("年度消耗占比 \(Int(consumptionRatio * 100))%，超过理想值 25%")
        }

        // 输入洞察
        if inputRatio >= 0.20 {
            tips.append("年度输入充足（\(Int(inputRatio * 100))%），知识积累扎实")
        }

        // 记录习惯
        let completionPercent = Int(recordCompletionRate * 100)
        if recordCompletionRate >= 0.8 {
            tips.append("全年记录覆盖 \(completionPercent)%，坚持记录令人敬佩！")
        } else if recordCompletionRate < 0.5 && totalDaysInYear > 30 {
            tips.append("全年记录覆盖 \(completionPercent)%，试试每天至少记录一次")
        }

        // 深度工作
        if totalDeepWorkCount >= 100 {
            tips.append("全年深度工作 \(totalDeepWorkCount) 次，\(formatInterval(totalDeepWorkDuration))，专注力出众！")
        } else if totalDeepWorkCount > 0 {
            tips.append("全年深度工作 \(totalDeepWorkCount) 次，共 \(formatInterval(totalDeepWorkDuration))")
        }

        // 最佳月份
        if let best = bestMonth {
            tips.append("最高效月份：\(best.shortDisplayName)（产出+输入占比最高）")
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

// MARK: - 年度对比
struct YearlyComparison {
    let current: YearlySummary
    let previous: YearlySummary?

    /// 某分类在去年的占比变化
    func ratioChange(for category: TimeCategory) -> Double? {
        guard let prev = previous, prev.totalTrackedTime > 0 else { return nil }
        return current.ratio(for: category) - prev.ratio(for: category)
    }

    /// 总记录时间变化
    var totalTimeChangePercent: Double? {
        guard let prev = previous, prev.totalTrackedTime > 0 else { return nil }
        return (current.totalTrackedTime - prev.totalTrackedTime) / prev.totalTrackedTime
    }

    /// 一句话总结
    var summary: String {
        guard let prev = previous, prev.totalTrackedTime > 3600 else {
            return "\(current.year)年已记录 \(current.formattedTotalTime)"
        }

        let change = totalTimeChangePercent ?? 0
        let direction = change >= 0 ? "增加" : "减少"
        let percent = Int(abs(change) * 100)
        return "较去年\(direction) \(percent)%，共计 \(current.formattedTotalTime)"
    }
}

// MARK: - Factory
extension YearlySummary {
    /// 从 TimeEntry 数组生成年汇总
    static func from(entries: [TimeEntry], year: Int) -> YearlySummary {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        // 确定要统计的月份范围
        let lastMonth = (year == currentYear) ? currentMonth : 12

        var monthlySummaries: [MonthlySummary] = []
        for month in 1...lastMonth {
            let monthEntries = entries.filter { entry in
                let components = calendar.dateComponents([.year, .month], from: entry.startTime)
                return components.year == year && components.month == month
            }
            monthlySummaries.append(MonthlySummary.from(entries: monthEntries, year: year, month: month))
        }

        return YearlySummary(
            year: year,
            monthlySummaries: monthlySummaries
        )
    }
}
