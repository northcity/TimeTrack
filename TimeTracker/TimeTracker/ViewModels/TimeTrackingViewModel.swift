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

    // MARK: - 初始化
    func setup(context: ModelContext) {
        self.modelContext = context
        loadActiveEntry()
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
    }

    /// 停止计时
    func stopTracking(notes: String? = nil) {
        guard let entry = activeEntry else { return }
        entry.stop()
        if let notes = notes, !notes.isEmpty {
            entry.notes = notes
        }
        activeEntry = nil
        stopTimer()
        save()
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
            source: .backfill
        )
        context.insert(entry)
        save()
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
}
