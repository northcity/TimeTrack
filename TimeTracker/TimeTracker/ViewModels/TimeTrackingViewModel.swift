//
//  TimeTrackingViewModel.swift
//  TimeTracker
//
//  主时间追踪 ViewModel
//

import Foundation
import SwiftData
import SwiftUI
import Observation
import WidgetKit
import ActivityKit

@Observable
final class TimeTrackingViewModel {
    var modelContext: ModelContext?

    // MARK: - Timer State
    var activeEntry: TimeEntry?
    var selectedCategory: TimeCategory = .output
    var elapsedTime: TimeInterval = 0
    private var timer: Timer?

    // MARK: - UI State
    var selectedDate: Date = Date()
    var showingAddEntry: Bool = false
    var showingBackfill: Bool = false
    var backfillPresetStart: Date?
    var backfillPresetEnd: Date?

    // MARK: - 连续记录 Streak
    var currentStreak: Int = 0

    // MARK: - 初始化
    func setup(context: ModelContext) {
        self.modelContext = context
        loadActiveEntry()
        calculateStreak()
        autoDetectDeepWork()
        syncWidgetData()
    }

    // MARK: - 计时控制

    /// 开始计时
    func startTracking(category: TimeCategory, source: EntrySource = .manual) {
        guard let context = modelContext else { return }

        // 如果有正在进行的记录，先停止
        if let active = activeEntry {
            active.stop()
        }

        let entry = TimeEntry(
            startTime: Date(),
            category: category,
            source: source
        )
        context.insert(entry)
        activeEntry = entry
        startTimer()
        save()
        syncWidgetData()
        startLiveActivity(category: category)
    }

    /// 停止计时
    func stopTracking(notes: String? = nil) {
        guard let entry = activeEntry else { return }
        entry.stop()
        if let notes = notes, !notes.isEmpty {
            entry.notes = notes
        }
        // 自动检测深度工作
        if entry.category.isProductive && entry.duration >= 90 * 60 {
            entry.isDeepWork = true
        }
        activeEntry = nil
        stopTimer()
        save()
        calculateStreak()
        syncWidgetData()
        stopLiveActivity()
    }

    /// 快速记录（一键开始指定分类）
    func quickStart(category: TimeCategory) {
        startTracking(category: category, source: .quick)
    }

    // MARK: - 补记录

    /// 添加补记录
    func addBackfillEntry(
        startTime: Date,
        endTime: Date,
        category: TimeCategory,
        notes: String? = nil,
        tags: [String] = []
    ) {
        guard let context = modelContext else { return }
        let entry = TimeEntry(
            startTime: startTime,
            endTime: endTime,
            category: category,
            tags: tags,
            notes: notes,
            source: .backfill,
            isDeepWork: category.isProductive && endTime.timeIntervalSince(startTime) >= 90 * 60
        )
        context.insert(entry)
        save()
        calculateStreak()
    }

    // MARK: - 数据查询

    /// 获取某天的所有记录
    func entries(for date: Date) -> [TimeEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate<TimeEntry> {
                $0.startTime >= startOfDay && $0.startTime < endOfDay
            },
            sortBy: [SortDescriptor(\.startTime)]
        )

        do {
            return try modelContext?.fetch(descriptor) ?? []
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    /// 获取某一周的所有记录
    func entries(forWeekOf date: Date) -> [TimeEntry] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return []
        }

        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate<TimeEntry> {
                $0.startTime >= weekStart && $0.startTime < weekEnd
            },
            sortBy: [SortDescriptor(\.startTime)]
        )

        do {
            return try modelContext?.fetch(descriptor) ?? []
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    /// 获取日汇总
    func dailySummary(for date: Date) -> DailySummary {
        let dayEntries = entries(for: date)
        return DailySummary.from(entries: dayEntries, date: date)
    }

    /// 获取周汇总
    func weeklySummary(for date: Date) -> WeeklySummary {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
        let weekEntries = entries(forWeekOf: date)
        return WeeklySummary.from(entries: weekEntries, weekStartDate: weekStart)
    }

    /// 获取指定日期范围内的记录（CSV 导出用）
    func fetchEntries(from startDate: Date, to endDate: Date) -> [TimeEntry] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        guard let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) else {
            return []
        }

        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate<TimeEntry> {
                $0.startTime >= start && $0.startTime < end
            },
            sortBy: [SortDescriptor(\.startTime)]
        )

        do {
            return try modelContext?.fetch(descriptor) ?? []
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    /// 查找空白时间段（用于补记录提示）
    func findGaps(on date: Date, minGapMinutes: Int = 30) -> [(start: Date, end: Date)] {
        let dayEntries = entries(for: date).filter { !$0.isRunning }
        guard !dayEntries.isEmpty else { return [] }

        let calendar = Calendar.current
        var gaps: [(start: Date, end: Date)] = []
        let sortedEntries = dayEntries.sorted { $0.startTime < $1.startTime }

        // 检查条目之间的间隙
        for i in 0..<(sortedEntries.count - 1) {
            let currentEnd = sortedEntries[i].endTime ?? sortedEntries[i].startTime
            let nextStart = sortedEntries[i + 1].startTime
            let gapDuration = nextStart.timeIntervalSince(currentEnd)
            if gapDuration >= Double(minGapMinutes * 60) {
                gaps.append((start: currentEnd, end: nextStart))
            }
        }

        // 检查最后一条记录到当前时间（或一天结束）的间隙
        if let lastEnd = sortedEntries.last?.endTime {
            let now = calendar.isDateInToday(date) ? Date() : calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
            let gap = now.timeIntervalSince(lastEnd)
            if gap >= Double(minGapMinutes * 60) {
                gaps.append((start: lastEnd, end: now))
            }
        }

        return gaps
    }

    /// 删除记录
    func deleteEntry(_ entry: TimeEntry) {
        modelContext?.delete(entry)
        save()
    }

    /// 更新记录（F-04 编辑功能）
    func updateEntry(
        _ entry: TimeEntry,
        startTime: Date,
        endTime: Date?,
        category: TimeCategory,
        subCategory: String?,
        notes: String?,
        tags: [String],
        isDeepWork: Bool
    ) {
        entry.startTime = startTime
        entry.endTime = endTime
        entry.category = category
        entry.subCategory = subCategory
        entry.notes = notes
        entry.tags = tags
        entry.isDeepWork = isDeepWork
        save()
    }

    // MARK: - 时间块拖动编辑（F-09）

    /// 移动时间块（拖动整体）— 保持时长不变，修改起止时间
    func moveEntry(_ entry: TimeEntry, toStartTime newStart: Date) {
        guard let end = entry.endTime else { return }
        let duration = end.timeIntervalSince(entry.startTime)
        let newEnd = newStart.addingTimeInterval(duration)
        entry.startTime = newStart
        entry.endTime = newEnd
        save()
    }

    /// 调整时间块起始时间（拖动顶部边缘）
    func resizeEntryStart(_ entry: TimeEntry, toStartTime newStart: Date) {
        guard let end = entry.endTime else { return }
        // 最小时长 5 分钟
        let minDuration: TimeInterval = 5 * 60
        if end.timeIntervalSince(newStart) >= minDuration {
            entry.startTime = newStart
            save()
        }
    }

    /// 调整时间块结束时间（拖动底部边缘）
    func resizeEntryEnd(_ entry: TimeEntry, toEndTime newEnd: Date) {
        // 最小时长 5 分钟
        let minDuration: TimeInterval = 5 * 60
        if newEnd.timeIntervalSince(entry.startTime) >= minDuration {
            entry.endTime = newEnd
            save()
        }
    }

    // MARK: - 月度汇总（F-21）

    /// 获取某月的所有记录
    func entries(forMonth year: Int, month: Int) -> [TimeEntry] {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: DateComponents(year: year, month: month)),
              let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return []
        }

        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate<TimeEntry> {
                $0.startTime >= monthStart && $0.startTime < nextMonth
            },
            sortBy: [SortDescriptor(\.startTime)]
        )

        do {
            return try modelContext?.fetch(descriptor) ?? []
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    /// 获取月汇总
    func monthlySummary(year: Int, month: Int) -> MonthlySummary {
        let monthEntries = entries(forMonth: year, month: month)
        return MonthlySummary.from(entries: monthEntries, year: year, month: month)
    }

    /// 获取月度对比
    func monthlyComparison(year: Int, month: Int) -> MonthlyComparison {
        let current = monthlySummary(year: year, month: month)
        let calendar = Calendar.current
        guard let currentDate = calendar.date(from: DateComponents(year: year, month: month)),
              let prevDate = calendar.date(byAdding: .month, value: -1, to: currentDate) else {
            return MonthlyComparison(current: current, previous: nil)
        }
        let prevYear = calendar.component(.year, from: prevDate)
        let prevMonth = calendar.component(.month, from: prevDate)
        let previous = monthlySummary(year: prevYear, month: prevMonth)
        return MonthlyComparison(current: current, previous: previous.totalTrackedTime > 0 ? previous : nil)
    }

    // MARK: - 年度汇总（F-22/23）

    /// 获取某年的所有记录
    func entries(forYear year: Int) -> [TimeEntry] {
        let calendar = Calendar.current
        guard let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let yearEnd = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            return []
        }

        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate<TimeEntry> {
                $0.startTime >= yearStart && $0.startTime < yearEnd
            },
            sortBy: [SortDescriptor(\.startTime)]
        )

        do {
            return try modelContext?.fetch(descriptor) ?? []
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    /// 获取年汇总
    func yearlySummary(year: Int) -> YearlySummary {
        let yearEntries = entries(forYear: year)
        return YearlySummary.from(entries: yearEntries, year: year)
    }

    /// 获取年度对比
    func yearlyComparison(year: Int) -> YearlyComparison {
        let current = yearlySummary(year: year)
        let previous = yearlySummary(year: year - 1)
        return YearlyComparison(
            current: current,
            previous: previous.totalTrackedTime > 0 ? previous : nil
        )
    }

    // MARK: - 连续记录 Streak（P2）

    /// 计算连续记录天数
    func calculateStreak() {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        // 从今天开始往回查
        for _ in 0..<365 {
            let dayEntries = entries(for: checkDate).filter { !$0.isRunning }
            let totalTime = dayEntries.reduce(0.0) { $0 + $1.duration }
            if totalTime > 600 { // 至少 10 分钟算有记录
                streak += 1
            } else {
                // 如果今天还没记录但有活跃计时,不中断streak
                if calendar.isDateInToday(checkDate), activeEntry != nil {
                    streak += 1
                } else if streak > 0 {
                    break
                } else {
                    break
                }
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        currentStreak = streak
    }

    // MARK: - 深度工作自动检测（F-24）

    /// 自动标记深度工作
    func autoDetectDeepWork() {
        let calendar = Calendar.current
        // 检测最近 7 天
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dayEntries = entries(for: date)
            for entry in dayEntries {
                if entry.category.isProductive && entry.duration >= 90 * 60 && !entry.isDeepWork {
                    entry.isDeepWork = true
                }
            }
        }
        save()
    }

    // MARK: - 消耗预算提醒（F-41）

    /// 今日消耗预算状态
    var todayConsumptionStatus: ConsumptionBudgetStatus {
        let summary = dailySummary(for: Date())
        let budget = ScoringConfig.default.dailyConsumptionBudget
        let used = summary.consumptionTime
        let ratio = budget > 0 ? used / budget : 0

        if ratio >= 1.0 {
            return .exceeded(used: used, budget: budget)
        } else if ratio >= 0.8 {
            return .warning(used: used, budget: budget, remaining: budget - used)
        } else {
            return .normal(used: used, budget: budget, remaining: budget - used)
        }
    }

    // MARK: - 补记录（带预设时间）

    /// 添加带预设时间段的补记录
    func startBackfill(start: Date, end: Date) {
        backfillPresetStart = start
        backfillPresetEnd = end
        showingBackfill = true
    }

    // MARK: - Private

    private func loadActiveEntry() {
        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate<TimeEntry> { $0.endTime == nil },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        do {
            if let active = try modelContext?.fetch(descriptor).first {
                activeEntry = active
                startTimer()
            }
        } catch {
            print("Load active entry error: \(error)")
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsedTime()
            }
        }
        updateElapsedTime()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        elapsedTime = 0
    }

    private func updateElapsedTime() {
        if let active = activeEntry {
            elapsedTime = Date().timeIntervalSince(active.startTime)
        }
    }

    private func save() {
        do {
            try modelContext?.save()
        } catch {
            print("Save error: \(error)")
        }
    }

    // MARK: - Widget 数据同步（F-29/30/31）

    /// 同步数据到 Widget
    func syncWidgetData() {
        let summary = dailySummary(for: Date())
        var shared = WidgetSharedData()

        // 计时状态
        shared.isTimerRunning = activeEntry != nil
        shared.activeCategory = activeEntry?.categoryRaw
        shared.activeStartTime = activeEntry?.startTime

        // 今日数据
        for cat in TimeCategory.allCases {
            shared.todayCategoryTimes[cat.rawValue] = summary.totalTimePerCategory[cat] ?? 0
        }
        shared.todayTotalTime = summary.totalTrackedTime
        shared.todayQualityScore = summary.qualityScore.totalScore
        shared.todayDeepWorkCount = summary.deepWorkCount
        shared.todayConsumptionTime = summary.consumptionTime
        shared.consumptionBudget = ScoringConfig.default.dailyConsumptionBudget
        shared.currentStreak = currentStreak
        shared.lastUpdated = Date()

        shared.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Live Activity 管理（F-29）

    /// 开始实时活动（灵动岛 + 锁屏 Banner）
    private func startLiveActivity(category: TimeCategory) {
        // 先结束旧的 Live Activity
        stopLiveActivity()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = TimeTrackerActivityAttributes(
            categoryRaw: category.rawValue,
            categoryDisplayName: category.displayName,
            categoryIcon: category.icon,
            startTime: Date()
        )
        let state = TimeTrackerActivityAttributes.ContentState(
            elapsedMinutes: 0,
            isRunning: true
        )

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("Live Activity start error: \(error)")
        }
    }

    /// 停止所有实时活动
    private func stopLiveActivity() {
        let finalState = TimeTrackerActivityAttributes.ContentState(
            elapsedMinutes: 0,
            isRunning: false
        )
        for activity in Activity<TimeTrackerActivityAttributes>.activities {
            Task {
                await activity.end(
                    .init(state: finalState, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }
        }
    }
}

// MARK: - 消耗预算状态
enum ConsumptionBudgetStatus {
    case normal(used: TimeInterval, budget: TimeInterval, remaining: TimeInterval)
    case warning(used: TimeInterval, budget: TimeInterval, remaining: TimeInterval)
    case exceeded(used: TimeInterval, budget: TimeInterval)

    var isOverBudget: Bool {
        if case .exceeded = self { return true }
        return false
    }

    var isWarning: Bool {
        if case .warning = self { return true }
        return false
    }

    var message: String {
        switch self {
        case .normal(_, _, let remaining):
            return "消耗预算剩余 \(remaining.shortFormatted)"
        case .warning(_, _, let remaining):
            return "⚠️ 消耗预算仅剩 \(remaining.shortFormatted)"
        case .exceeded(let used, let budget):
            let over = used - budget
            return "🚨 消耗已超预算 \(over.shortFormatted)"
        }
    }
}
