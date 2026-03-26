//
//  TimeWidgetControl.swift
//  TimeWidget
//
//  TimeTracker 控制中心 Widget
//  快速查看计时状态
//

import AppIntents
import SwiftUI
import WidgetKit

struct TimeWidgetControl: ControlWidget {
    static let kind: String = "com.test.huxi.TimeTracker.TimeWidget"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenTimeTrackerIntent()) {
                let data = WidgetSharedData.load()
                if data.isTimerRunning {
                    let cat = WidgetCategory.from(rawValue: data.activeCategory)
                    Label("\(cat.displayName)计时中", systemImage: cat.icon)
                } else {
                    Label("打开 TimeTracker", systemImage: "timer")
                }
            }
        }
        .displayName("时间追踪")
        .description("快速打开 TimeTracker")
    }
}

// MARK: - 打开 App Intent

struct OpenTimeTrackerIntent: AppIntent {
    static var title: LocalizedStringResource = "打开 TimeTracker"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
