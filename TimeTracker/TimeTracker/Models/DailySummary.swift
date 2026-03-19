//
//  DailySummary.swift
//  TimeTracker
//
//  柳比歇夫时间统计法 - 每日汇总（计算生成，非持久化）
//

import Foundation

/// 每日汇总数据（通过 TimeEntry 实时计算）
struct DailySummary: Identifiable {
    let id = UUID()
    let date: Date

    /// 每个分类的总时间（秒）
    let totalTimePerCategory: [TimeCategory: TimeInterval]

    /// 当天所有记录
    let entries: [TimeEntry]

    // MARK: - Computed Properties

    /// 总记录时间
    var totalTrackedTime: TimeInterval {
        totalTimePerCategory.values.reduce(0, +)
    }

    /// 空白时间（假设每天有效时间 16 小时 = 57600 秒）
    var emptyTime: TimeInterval {
        max(0, 57600 - totalTrackedTime)
    }

    /// 输出占比评分（输入+输出 占总记录时间的比例）
    var outputScore: Double {
        guard totalTrackedTime > 0 else { return 0 }
        let productiveTime = (totalTimePerCategory[.input] ?? 0)
                           + (totalTimePerCategory[.output] ?? 0)
        return productiveTime / totalTrackedTime
    }

    /// 纯输出占比（仅输出类）
    var pureOutputRatio: Double {
        guard totalTrackedTime > 0 else { return 0 }
        return (totalTimePerCategory[.output] ?? 0) / totalTrackedTime
    }

    /// 格式化总时间
    var formattedTotalTime: String {
        formatInterval(totalTrackedTime)
    }

    /// 格式化空白时间
    var formattedEmptyTime: String {
        formatInterval(emptyTime)
    }

    /// 格式化某分类时间
    func formattedTime(for category: TimeCategory) -> String {
        formatInterval(totalTimePerCategory[category] ?? 0)
    }

    /// 洞察提示（未来可接入 AI）
    var insights: [String] {
        var tips: [String] = []
        if outputScore < 0.3 {
            tips.append("今日高效时间偏低，试试减少消耗类活动")
        }
        if (totalTimePerCategory[.consumption] ?? 0) > 3 * 3600 {
            tips.append("消耗类时间超过3小时，注意控制")
        }
        if emptyTime > 6 * 3600 {
            tips.append("有较多空白时间未记录，可以补记录")
        }
        if pureOutputRatio > 0.4 {
            tips.append("今日输出占比优秀！保持深度工作")
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
extension DailySummary {
    /// 从 TimeEntry 数组生成日汇总
    static func from(entries: [TimeEntry], date: Date) -> DailySummary {
        let dayEntries = entries.filter { $0.isOn(date: date) && !$0.isRunning }
        var timePerCategory: [TimeCategory: TimeInterval] = [:]
        for cat in TimeCategory.allCases {
            timePerCategory[cat] = 0
        }
        for entry in dayEntries {
            timePerCategory[entry.category, default: 0] += entry.duration
        }
        return DailySummary(
            date: date,
            totalTimePerCategory: timePerCategory,
            entries: dayEntries
        )
    }
}
