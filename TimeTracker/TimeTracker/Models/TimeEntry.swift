//
//  TimeEntry.swift
//  TimeTracker
//
//  柳比歇夫时间统计法 - 核心时间记录模型
//

import Foundation
import SwiftData

@Model
final class TimeEntry {
    // MARK: - 核心属性
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var categoryRaw: String
    var subCategory: String?
    var tags: [String]
    var notes: String?
    var sourceRaw: String
    var createdAt: Date

    // MARK: - 未来扩展字段
    var isDeepWork: Bool
    var qualityScore: Double? // 0.0 ~ 1.0, 未来行为评分

    // MARK: - Computed Properties
    var category: TimeCategory {
        get { TimeCategory(rawValue: categoryRaw) ?? .maintenance }
        set { categoryRaw = newValue.rawValue }
    }

    var source: EntrySource {
        get { EntrySource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    /// 时长（秒）
    var duration: TimeInterval {
        guard let end = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return end.timeIntervalSince(startTime)
    }

    /// 格式化时长
    var formattedDuration: String {
        let totalMinutes = Int(duration) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// 是否正在计时中
    var isRunning: Bool {
        endTime == nil
    }

    // MARK: - Initializer
    init(
        startTime: Date,
        endTime: Date? = nil,
        category: TimeCategory,
        subCategory: String? = nil,
        tags: [String] = [],
        notes: String? = nil,
        source: EntrySource = .manual,
        isDeepWork: Bool = false,
        qualityScore: Double? = nil
    ) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.categoryRaw = category.rawValue
        self.subCategory = subCategory
        self.tags = tags
        self.notes = notes
        self.sourceRaw = source.rawValue
        self.createdAt = Date()
        self.isDeepWork = isDeepWork
        self.qualityScore = qualityScore
    }
}

// MARK: - Convenience Extensions
extension TimeEntry {
    /// 停止计时
    func stop() {
        if endTime == nil {
            endTime = Date()
        }
    }

    /// 日期是否在指定日期内
    func isOn(date: Date) -> Bool {
        Calendar.current.isDate(startTime, inSameDayAs: date)
    }

    /// 时间块在某天的开始分钟偏移（用于日历视图定位）
    func startMinuteOfDay() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: startTime)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    /// 时间块在某天的结束分钟偏移
    func endMinuteOfDay() -> Int {
        let end = endTime ?? Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: end)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
