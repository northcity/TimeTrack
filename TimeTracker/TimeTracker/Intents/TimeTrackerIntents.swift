//
//  TimeTrackerIntents.swift
//  TimeTracker
//
//  App Intents - 完整实现（F-05）
//  支持 Siri / Shortcuts 快速记录
//

import AppIntents
import SwiftData
import Foundation

// MARK: - 时间分类枚举（App Intents 用）
enum TimeCategoryAppEnum: String, AppEnum {
    case input
    case output
    case consumption
    case maintenance

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "时间分类")

    static var caseDisplayRepresentations: [TimeCategoryAppEnum: DisplayRepresentation] = [
        .input: DisplayRepresentation(title: "输入", subtitle: "学习 / 阅读"),
        .output: DisplayRepresentation(title: "输出", subtitle: "写作 / 创作"),
        .consumption: DisplayRepresentation(title: "消耗", subtitle: "娱乐 / 社交"),
        .maintenance: DisplayRepresentation(title: "维持", subtitle: "生活 / 杂务")
    ]

    var toTimeCategory: TimeCategory {
        switch self {
        case .input: return .input
        case .output: return .output
        case .consumption: return .consumption
        case .maintenance: return .maintenance
        }
    }
}

// MARK: - 共享 ModelContainer
@MainActor
enum IntentModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([TimeEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer for Intents: \(error)")
        }
    }()
}

// MARK: - 开始计时 Intent
struct StartTrackingIntent: AppIntent {
    static var title: LocalizedStringResource = "开始计时"
    static var description: IntentDescription = IntentDescription("开始一个时间追踪，选择分类后立即开始计时")

    @Parameter(title: "分类")
    var category: TimeCategoryAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("开始 \(\.$category) 计时")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = IntentModelContainer.shared
        let context = container.mainContext

        // 先停止所有正在进行的计时
        let runningDescriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate<TimeEntry> { $0.endTime == nil }
        )
        let runningEntries = try context.fetch(runningDescriptor)
        for entry in runningEntries {
            entry.endTime = Date()
        }

        // 创建新记录
        let entry = TimeEntry(
            startTime: Date(),
            category: category.toTimeCategory,
            source: .appIntent
        )
        context.insert(entry)
        try context.save()

        let catName = category.toTimeCategory.displayName
        return .result(dialog: "已开始\(catName)计时 ⏱️")
    }
}

// MARK: - 停止计时 Intent
struct StopTrackingIntent: AppIntent {
    static var title: LocalizedStringResource = "停止计时"
    static var description: IntentDescription = IntentDescription("停止当前进行中的计时")

    @Parameter(title: "备注", default: nil)
    var notes: String?

    static var parameterSummary: some ParameterSummary {
        Summary("停止当前计时")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = IntentModelContainer.shared
        let context = container.mainContext

        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate<TimeEntry> { $0.endTime == nil },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        let runningEntries = try context.fetch(descriptor)

        guard let active = runningEntries.first else {
            return .result(dialog: "当前没有进行中的计时")
        }

        active.endTime = Date()
        if let notes = notes, !notes.isEmpty {
            active.notes = notes
        }

        // 自动检测深度工作
        if active.category.isProductive && active.duration >= 90 * 60 {
            active.isDeepWork = true
        }

        try context.save()

        let duration = active.formattedDuration
        let catName = active.category.displayName
        return .result(dialog: "\(catName)计时已停止，时长 \(duration)")
    }
}

// MARK: - 查询今日状态 Intent
struct TodayStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "今日时间状态"
    static var description: IntentDescription = IntentDescription("查看今日时间记录状态和质量评分")

    static var parameterSummary: some ParameterSummary {
        Summary("查看今日状态")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = IntentModelContainer.shared
        let context = container.mainContext

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return .result(dialog: "无法获取今日数据")
        }

        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate<TimeEntry> {
                $0.startTime >= startOfDay && $0.startTime < endOfDay
            },
            sortBy: [SortDescriptor(\.startTime)]
        )
        let entries = try context.fetch(descriptor)
        let summary = DailySummary.from(entries: entries, date: Date())
        let score = summary.qualityScore

        let statusText = """
        今日已记录 \(summary.formattedTotalTime)
        质量评分：\(Int(score.totalScore))分 \(score.level.emoji)
        输出 \(summary.formattedTime(for: .output)) | 输入 \(summary.formattedTime(for: .input))
        消耗 \(summary.formattedTime(for: .consumption)) | 维持 \(summary.formattedTime(for: .maintenance))
        """

        return .result(dialog: "\(statusText)")
    }
}

// MARK: - 快速补记录 Intent
struct QuickBackfillIntent: AppIntent {
    static var title: LocalizedStringResource = "快速补记录"
    static var description: IntentDescription = IntentDescription("快速添加一段已完成的时间记录")

    @Parameter(title: "分类")
    var category: TimeCategoryAppEnum

    @Parameter(title: "时长（分钟）")
    var durationMinutes: Int

    @Parameter(title: "备注", default: nil)
    var notes: String?

    static var parameterSummary: some ParameterSummary {
        Summary("记录 \(\.$durationMinutes) 分钟的 \(\.$category)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = IntentModelContainer.shared
        let context = container.mainContext

        let endTime = Date()
        let startTime = endTime.addingTimeInterval(-Double(durationMinutes) * 60)

        let isDeepWork = category.toTimeCategory.isProductive && durationMinutes >= 90

        let entry = TimeEntry(
            startTime: startTime,
            endTime: endTime,
            category: category.toTimeCategory,
            notes: notes,
            source: .appIntent,
            isDeepWork: isDeepWork
        )
        context.insert(entry)
        try context.save()

        let catName = category.toTimeCategory.displayName
        return .result(dialog: "已记录 \(durationMinutes) 分钟\(catName)\(isDeepWork ? " 🔥" : "")")
    }
}

// MARK: - App Shortcuts Provider
struct TimeTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTrackingIntent(),
            phrases: [
                "用\(.applicationName)开始计时",
                "开始\(.applicationName)追踪",
                "用\(.applicationName)开始\(\.$category)计时"
            ],
            shortTitle: "开始计时",
            systemImageName: "timer"
        )
        AppShortcut(
            intent: StopTrackingIntent(),
            phrases: [
                "用\(.applicationName)停止计时",
                "停止\(.applicationName)追踪"
            ],
            shortTitle: "停止计时",
            systemImageName: "stop.circle"
        )
        AppShortcut(
            intent: TodayStatusIntent(),
            phrases: [
                "用\(.applicationName)查看今日状态",
                "\(.applicationName)今天怎么样"
            ],
            shortTitle: "今日状态",
            systemImageName: "chart.bar"
        )
        AppShortcut(
            intent: QuickBackfillIntent(),
            phrases: [
                "用\(.applicationName)补记录"
            ],
            shortTitle: "快速补记录",
            systemImageName: "plus.circle"
        )
    }
}
