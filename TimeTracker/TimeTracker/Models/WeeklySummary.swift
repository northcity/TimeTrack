//
//  WeeklySummary.swift
//  TimeTracker
//
//  柳比歇夫时间统计法 - 每周汇总（计算生成）
//

import Foundation

/// 每周汇总数据
struct WeeklySummary: Identifiable {
    let id = UUID()
    let weekStartDate: Date
    let dailySummaries: [DailySummary]

    // MARK: - Computed Properties

    /// 本周每个分类的总时间
    var totalTimePerCategory: [TimeCategory: TimeInterval] {
        var result: [TimeCategory: TimeInterval] = [:]
        for cat in TimeCategory.allCases {
            result[cat] = dailySummaries.reduce(0) {
                $0 + ($1.totalTimePerCategory[cat] ?? 0)
            }
        }
        return result
    }

    /// 本周总记录时间
    var totalTrackedTime: TimeInterval {
        dailySummaries.reduce(0) { $0 + $1.totalTrackedTime }
    }

    /// 本周总空白时间
    var totalEmptyTime: TimeInterval {
        dailySummaries.reduce(0) { $0 + $1.emptyTime }
    }

    /// 本周平均输出评分
    var averageOutputScore: Double {
        let scores = dailySummaries.map { $0.outputScore }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
    }

    /// 每日输出评分趋势
    var dailyOutputScores: [(date: Date, score: Double)] {
        dailySummaries.map { ($0.date, $0.outputScore) }
    }

    /// 格式化周总时间
    var formattedTotalTime: String {
        formatInterval(totalTrackedTime)
    }

    /// 格式化某分类时间
    func formattedTime(for category: TimeCategory) -> String {
        formatInterval(totalTimePerCategory[category] ?? 0)
    }

    /// 周洞察
    var insights: [String] {
        var tips: [String] = []
        if averageOutputScore > 0.5 {
            tips.append("本周高效时间占比优秀（\(Int(averageOutputScore * 100))%）")
        } else if averageOutputScore < 0.3 {
            tips.append("本周高效时间占比偏低，建议增加输入/输出类活动")
        }

        let consumptionTotal = totalTimePerCategory[.consumption] ?? 0
        if consumptionTotal > 15 * 3600 {
            tips.append("本周消耗类时间较多（\(formatInterval(consumptionTotal))）")
        }

        let outputTotal = totalTimePerCategory[.output] ?? 0
        if outputTotal > 10 * 3600 {
            tips.append("本周创作/输出时间充足，保持节奏！")
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

// MARK: - Factory
extension WeeklySummary {
    /// 从 TimeEntry 数组生成周汇总
    static func from(entries: [TimeEntry], weekStartDate: Date) -> WeeklySummary {
        let calendar = Calendar.current
        var dailies: [DailySummary] = []
        for dayOffset in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) {
                dailies.append(DailySummary.from(entries: entries, date: day))
            }
        }
        return WeeklySummary(
            weekStartDate: weekStartDate,
            dailySummaries: dailies
        )
    }
}
