//
//  TimeWidgetLiveActivity.swift
//  TimeWidget
//
//  TimeTracker 实时活动（计时中展示）
//  灵动岛 + 锁屏 Banner 显示当前计时状态
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Attributes

struct TimeTrackerActivityAttributes: ActivityAttributes {
    /// 固定属性（计时开始时不变）
    var categoryRaw: String
    var categoryDisplayName: String
    var categoryIcon: String
    var startTime: Date

    /// 动态状态
    public struct ContentState: Codable, Hashable {
        var elapsedMinutes: Int     // 已经过分钟数（用于非实时更新场景）
        var isRunning: Bool         // 是否仍在计时
    }
}

// MARK: - Live Activity Widget

struct TimeWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimeTrackerActivityAttributes.self) { context in
            // 锁屏 / Banner 展示
            lockScreenBanner(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // 展开状态
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: context.attributes.categoryIcon)
                            .font(.caption)
                        Text(context.attributes.categoryDisplayName)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(categoryColor(context.attributes.categoryRaw))
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.startTime, style: .timer)
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                        .foregroundStyle(categoryColor(context.attributes.categoryRaw))
                        .frame(width: 70)
                        .multilineTextAlignment(.trailing)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("开始于 \(formattedTime(context.attributes.startTime))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if context.state.isRunning {
                            Label("计时中", systemImage: "record.circle")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                }
            } compactLeading: {
                // 紧凑模式 - 左侧
                HStack(spacing: 4) {
                    Image(systemName: context.attributes.categoryIcon)
                        .font(.caption2)
                        .foregroundStyle(categoryColor(context.attributes.categoryRaw))
                    Text(context.attributes.categoryDisplayName)
                        .font(.caption2.weight(.medium))
                }
            } compactTrailing: {
                // 紧凑模式 - 右侧
                Text(context.attributes.startTime, style: .timer)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(categoryColor(context.attributes.categoryRaw))
                    .frame(width: 52)
                    .multilineTextAlignment(.trailing)
            } minimal: {
                // 最小模式
                Image(systemName: context.attributes.categoryIcon)
                    .font(.caption2)
                    .foregroundStyle(categoryColor(context.attributes.categoryRaw))
            }
            .widgetURL(URL(string: "timetracker://timer"))
        }
    }

    // MARK: - 锁屏 Banner

    @ViewBuilder
    private func lockScreenBanner(context: ActivityViewContext<TimeTrackerActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            // 左侧：分类图标 + 名称
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: context.attributes.categoryIcon)
                        .font(.title3)
                    Text(context.attributes.categoryDisplayName)
                        .font(.headline)
                }
                .foregroundStyle(categoryColor(context.attributes.categoryRaw))

                Text("开始于 \(formattedTime(context.attributes.startTime))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 右侧：计时器
            VStack(alignment: .trailing, spacing: 4) {
                Text(context.attributes.startTime, style: .timer)
                    .font(.system(.title2, design: .monospaced, weight: .medium))
                    .foregroundStyle(categoryColor(context.attributes.categoryRaw))

                if context.state.isRunning {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("计时中")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding(16)
        .activityBackgroundTint(categoryColor(context.attributes.categoryRaw).opacity(0.1))
        .activitySystemActionForegroundColor(categoryColor(context.attributes.categoryRaw))
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Previews

extension TimeTrackerActivityAttributes {
    fileprivate static var previewOutput: TimeTrackerActivityAttributes {
        TimeTrackerActivityAttributes(
            categoryRaw: "output",
            categoryDisplayName: "输出",
            categoryIcon: "pencil.and.outline",
            startTime: Date().addingTimeInterval(-45 * 60)
        )
    }
}

extension TimeTrackerActivityAttributes.ContentState {
    fileprivate static var running: TimeTrackerActivityAttributes.ContentState {
        TimeTrackerActivityAttributes.ContentState(elapsedMinutes: 45, isRunning: true)
    }

    fileprivate static var stopped: TimeTrackerActivityAttributes.ContentState {
        TimeTrackerActivityAttributes.ContentState(elapsedMinutes: 90, isRunning: false)
    }
}

#Preview("Notification", as: .content, using: TimeTrackerActivityAttributes.previewOutput) {
    TimeWidgetLiveActivity()
} contentStates: {
    TimeTrackerActivityAttributes.ContentState.running
    TimeTrackerActivityAttributes.ContentState.stopped
}
