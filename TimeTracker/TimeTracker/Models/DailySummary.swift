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

    // MARK: - 深度工作检测（F-24/25）

    /// 深度工作记录（同分类连续 >= 90分钟 的输入/输出记录）
    var deepWorkEntries: [TimeEntry] {
        entries.filter { entry in
            entry.category.isProductive && entry.duration >= 90 * 60
        }
    }

    /// 深度工作次数
    var deepWorkCount: Int {
        deepWorkEntries.count
    }

    /// 深度工作总时长
    var deepWorkDuration: TimeInterval {
        deepWorkEntries.reduce(0) { $0 + $1.duration }
    }

    /// 格式化深度工作时长
    var formattedDeepWorkDuration: String {
        formatInterval(deepWorkDuration)
    }

    // MARK: - 时间质量评分（F-26/27）

    /// 日质量评分
    var qualityScore: QualityScoreResult {
        RuleBasedScoringEngine().score(summary: self)
    }

    // MARK: - 消耗预算（F-41）

    /// 消耗时间
    var consumptionTime: TimeInterval {
        totalTimePerCategory[.consumption] ?? 0
    }

    /// 消耗是否超预算（默认 3 小时）
    var isConsumptionOverBudget: Bool {
        consumptionTime > ScoringConfig.default.dailyConsumptionBudget
    }

    /// 消耗预算剩余
    var consumptionBudgetRemaining: TimeInterval {
        max(0, ScoringConfig.default.dailyConsumptionBudget - consumptionTime)
    }

    /// 洞察提示（未来可接入 AI）
    var insights: [String] {
        var tips: [String] = []
        if outputScore < 0.3 {
            tips.append("今日高效时间偏低，试试减少消耗类活动")
        }
        if consumptionTime > 3 * 3600 {
            tips.append("消耗类时间超过3小时，注意控制")
        }
        if emptyTime > 6 * 3600 {
            tips.append("有较多空白时间未记录，可以补记录")
        }
        if pureOutputRatio > 0.4 {
            tips.append("今日输出占比优秀！保持深度工作")
        }
        if deepWorkCount >= 2 {
            tips.append("今日深度工作 \(deepWorkCount) 次，合计 \(formattedDeepWorkDuration)，非常专注！")
        } else if deepWorkCount == 1 {
            tips.append("今日完成 1 次深度工作（\(formattedDeepWorkDuration)），继续保持")
        }
        if isConsumptionOverBudget {
            tips.append("⚠️ 消耗时间已超出每日预算（3小时）")
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
