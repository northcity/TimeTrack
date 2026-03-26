//
//  DateHelper.swift
//  TimeTracker
//
//  日期工具函数
//

import Foundation

enum DateHelper {
    static let calendar = Calendar.current

    /// 获取某天开始时间
    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// 获取某周开始日期（周一）
    static func startOfWeek(_ date: Date) -> Date {
        var cal = Calendar.current
        cal.firstWeekday = 2 // 周一
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: components) ?? date
    }

    /// 日期格式化：3月19日
    static func shortDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    /// 日期格式化：2026年3月19日
    static func fullDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }

    /// 时间格式化：09:30
    static func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    /// 星期格式化：周一
    static func weekdayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    /// 获取一周的日期数组
    static func daysInWeek(of date: Date) -> [Date] {
        let weekStart = startOfWeek(date)
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart)
        }
    }

    /// 日期差天数
    static func daysBetween(_ from: Date, _ to: Date) -> Int {
        calendar.dateComponents([.day], from: startOfDay(from), to: startOfDay(to)).day ?? 0
    }

    /// 是否是今天
    static func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    /// 上一周开始日期
    static func previousWeekStart(from date: Date) -> Date {
        calendar.date(byAdding: .day, value: -7, to: startOfWeek(date)) ?? date
    }

    /// 下一周开始日期
    static func nextWeekStart(from date: Date) -> Date {
        calendar.date(byAdding: .day, value: 7, to: startOfWeek(date)) ?? date
    }

    /// 日期 + 时间格式化：3月19日 09:30
    static func shortDateTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }

    /// 年月格式化：2026年3月
    static func yearMonthString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }
}

// MARK: - TimeInterval Extension
extension TimeInterval {
    /// 格式化为 "2h 30m"
    var shortFormatted: String {
        let totalMinutes = Int(self) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// 格式化为 "02:30:00"
    var timerFormatted: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
