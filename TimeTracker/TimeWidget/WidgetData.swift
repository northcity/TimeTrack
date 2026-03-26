//
//  WidgetData.swift
//  TimeWidget
//
//  Widget 共享数据模型（与主 App 共享，保持同步）
//

import Foundation

/// App Group 标识符
let appGroupIdentifier = "group.com.test.huxi.TimeTracker"

/// Widget 共享数据（从 App Group UserDefaults 读取）
struct WidgetSharedData: Codable {
    var isTimerRunning: Bool = false
    var activeCategory: String?
    var activeStartTime: Date?
    var todayCategoryTimes: [String: TimeInterval] = [:]
    var todayTotalTime: TimeInterval = 0
    var todayQualityScore: Double = 0
    var todayDeepWorkCount: Int = 0
    var currentStreak: Int = 0
    var todayConsumptionTime: TimeInterval = 0
    var consumptionBudget: TimeInterval = 3 * 3600
    var lastUpdated: Date = Date()

    // MARK: - 便捷访问

    var outputRatio: Double {
        guard todayTotalTime > 0 else { return 0 }
        return (todayCategoryTimes["output"] ?? 0) / todayTotalTime
    }

    var inputRatio: Double {
        guard todayTotalTime > 0 else { return 0 }
        return (todayCategoryTimes["input"] ?? 0) / todayTotalTime
    }

    var consumptionRatio: Double {
        guard todayTotalTime > 0 else { return 0 }
        return (todayCategoryTimes["consumption"] ?? 0) / todayTotalTime
    }

    var productiveTime: TimeInterval {
        (todayCategoryTimes["input"] ?? 0) + (todayCategoryTimes["output"] ?? 0)
    }

    var productiveRatio: Double {
        guard todayTotalTime > 0 else { return 0 }
        return productiveTime / todayTotalTime
    }

    var consumptionBudgetRemaining: TimeInterval {
        max(0, consumptionBudget - todayConsumptionTime)
    }

    var isConsumptionOverBudget: Bool {
        todayConsumptionTime > consumptionBudget
    }

    func formattedTime(for categoryRaw: String) -> String {
        let time = todayCategoryTimes[categoryRaw] ?? 0
        return formatInterval(time)
    }

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

    func save() {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: Self.userDefaultsKey)
        }
    }

    static func load() -> WidgetSharedData {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: userDefaultsKey),
              let shared = try? JSONDecoder().decode(WidgetSharedData.self, from: data) else {
            return WidgetSharedData()
        }
        return shared
    }
}

/// 分类颜色与图标（Widget 端独立定义，不依赖主 App）
struct WidgetCategory {
    let rawValue: String
    let displayName: String
    let icon: String

    static let input = WidgetCategory(rawValue: "input", displayName: "输入", icon: "book.fill")
    static let output = WidgetCategory(rawValue: "output", displayName: "输出", icon: "pencil.and.outline")
    static let consumption = WidgetCategory(rawValue: "consumption", displayName: "消耗", icon: "sparkles.tv")
    static let maintenance = WidgetCategory(rawValue: "maintenance", displayName: "维持", icon: "house.fill")

    static let allCases: [WidgetCategory] = [.input, .output, .consumption, .maintenance]

    static func from(rawValue: String?) -> WidgetCategory {
        guard let raw = rawValue else { return .maintenance }
        switch raw {
        case "input": return .input
        case "output": return .output
        case "consumption": return .consumption
        default: return .maintenance
        }
    }
}
