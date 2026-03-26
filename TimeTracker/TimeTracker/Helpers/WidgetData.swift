//
//  WidgetData.swift
//  TimeTracker
//
//  Widget 共享数据模型
//  通过 App Group UserDefaults 在主 App 和 Widget 之间同步数据
//

import Foundation

/// App Group 标识符
let appGroupIdentifier = "group.com.test.huxi.TimeTracker"

/// Widget 共享数据（写入 App Group UserDefaults）
struct WidgetSharedData: Codable {
    /// 当前是否在计时
    var isTimerRunning: Bool = false
    /// 当前计时分类
    var activeCategory: String?
    /// 当前计时开始时间
    var activeStartTime: Date?
    /// 今日各分类时间（秒）
    var todayCategoryTimes: [String: TimeInterval] = [:]
    /// 今日总记录时间（秒）
    var todayTotalTime: TimeInterval = 0
    /// 今日质量评分
    var todayQualityScore: Double = 0
    /// 今日深度工作次数
    var todayDeepWorkCount: Int = 0
    /// 连续记录天数
    var currentStreak: Int = 0
    /// 今日消耗时间（秒）
    var todayConsumptionTime: TimeInterval = 0
    /// 消耗预算（秒）
    var consumptionBudget: TimeInterval = 3 * 3600
    /// 最后更新时间
    var lastUpdated: Date = Date()

    // MARK: - 便捷访问

    /// 今日输出占比
    var outputRatio: Double {
        guard todayTotalTime > 0 else { return 0 }
        let outputTime = todayCategoryTimes["output"] ?? 0
        return outputTime / todayTotalTime
    }

    /// 今日输入占比
    var inputRatio: Double {
        guard todayTotalTime > 0 else { return 0 }
        let inputTime = todayCategoryTimes["input"] ?? 0
        return inputTime / todayTotalTime
    }

    /// 今日消耗占比
    var consumptionRatio: Double {
        guard todayTotalTime > 0 else { return 0 }
        let consumptionTime = todayCategoryTimes["consumption"] ?? 0
        return consumptionTime / todayTotalTime
    }

    /// 产出时间（输入 + 输出）
    var productiveTime: TimeInterval {
        (todayCategoryTimes["input"] ?? 0) + (todayCategoryTimes["output"] ?? 0)
    }

    /// 产出占比
    var productiveRatio: Double {
        guard todayTotalTime > 0 else { return 0 }
        return productiveTime / todayTotalTime
    }

    /// 消耗预算剩余
    var consumptionBudgetRemaining: TimeInterval {
        max(0, consumptionBudget - todayConsumptionTime)
    }

    /// 消耗是否超预算
    var isConsumptionOverBudget: Bool {
        todayConsumptionTime > consumptionBudget
    }

    /// 格式化分类时间
    func formattedTime(for categoryRaw: String) -> String {
        let time = todayCategoryTimes[categoryRaw] ?? 0
        return formatInterval(time)
    }

    /// 格式化总时间
    var formattedTotalTime: String {
        formatInterval(todayTotalTime)
    }

    private func formatInterval(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - UserDefaults 读写

extension WidgetSharedData {
    private static let userDefaultsKey = "widgetSharedData"

    /// 保存到 App Group UserDefaults
    func save() {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: Self.userDefaultsKey)
        }
    }

    /// 从 App Group UserDefaults 读取
    static func load() -> WidgetSharedData {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: userDefaultsKey),
              let shared = try? JSONDecoder().decode(WidgetSharedData.self, from: data) else {
            return WidgetSharedData()
        }
        return shared
    }
}
