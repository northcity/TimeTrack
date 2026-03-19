//
//  TimeTrackerIntents.swift
//  TimeTracker
//
//  App Intents - 快速记录（Siri / Shortcuts 支持）
//  MVP 阶段为脚手架，后续完善
//

import AppIntents
import SwiftData

// MARK: - 开始计时 Intent
struct StartTrackingIntent: AppIntent {
    static var title: LocalizedStringResource = "开始计时"
    static var description: IntentDescription = "快速开始一个时间追踪"

    @Parameter(title: "分类")
    var categoryName: String

    static var parameterSummary: some ParameterSummary {
        Summary("开始 \(\.$categoryName) 计时")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // TODO: MVP 后期实现 - 需要共享 ModelContainer
        // 当前仅返回确认
        return .result(dialog: "已开始 \(categoryName) 计时")
    }
}

// MARK: - 停止计时 Intent
struct StopTrackingIntent: AppIntent {
    static var title: LocalizedStringResource = "停止计时"
    static var description: IntentDescription = "停止当前进行中的计时"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // TODO: MVP 后期实现
        return .result(dialog: "已停止计时")
    }
}

// MARK: - App Shortcuts Provider
struct TimeTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTrackingIntent(),
            phrases: [
                "用\(.applicationName)开始计时",
                "开始\(.applicationName)追踪"
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
    }
}
