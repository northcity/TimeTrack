//
//  TimeWidget.swift
//  TimeWidget
//
//  TimeTracker 主屏 Widget（F-29/30）
//  支持 Small / Medium / Large 三种尺寸
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct TimeTrackerProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimeTrackerEntry {
        TimeTrackerEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TimeTrackerEntry) -> Void) {
        let data = WidgetSharedData.load()
        completion(TimeTrackerEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeTrackerEntry>) -> Void) {
        let data = WidgetSharedData.load()
        let entry = TimeTrackerEntry(date: Date(), data: data)

        // 如果正在计时，每分钟刷新一次；否则每 15 分钟刷新
        let refreshInterval: TimeInterval = data.isTimerRunning ? 60 : 15 * 60
        let nextUpdate = Date().addingTimeInterval(refreshInterval)

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct TimeTrackerEntry: TimelineEntry {
    let date: Date
    let data: WidgetSharedData

    static var placeholder: TimeTrackerEntry {
        var data = WidgetSharedData()
        data.todayCategoryTimes = [
            "output": 2.0 * 3600,
            "input": 1.5 * 3600,
            "consumption": 0.5 * 3600,
            "maintenance": 3.0 * 3600
        ]
        data.todayTotalTime = 7.0 * 3600
        data.todayQualityScore = 72
        data.currentStreak = 14
        data.todayDeepWorkCount = 2
        return TimeTrackerEntry(date: Date(), data: data)
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: TimeTrackerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 计时状态
            if entry.data.isTimerRunning {
                let cat = WidgetCategory.from(rawValue: entry.data.activeCategory)
                HStack(spacing: 4) {
                    Image(systemName: cat.icon)
                        .font(.caption2)
                    Text(cat.displayName)
                        .font(.caption2.weight(.semibold))
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                }
                .foregroundStyle(categoryColor(cat.rawValue))

                if let startTime = entry.data.activeStartTime {
                    Text(startTime, style: .timer)
                        .font(.system(.title2, design: .monospaced, weight: .medium))
                        .foregroundStyle(categoryColor(cat.rawValue))
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                    Text("今日")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)

                Text(entry.data.formattedTotalTime)
                    .font(.system(.title2, design: .rounded, weight: .bold))
            }

            Spacer()

            // 质量评分
            HStack {
                Text("\(Int(entry.data.todayQualityScore))")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(scoreColor(entry.data.todayQualityScore))
                Text("分")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                // Streak
                if entry.data.currentStreak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(entry.data.currentStreak)")
                            .font(.caption2.weight(.semibold))
                    }
                }
            }

            // 产出条
            GeometryReader { geo in
                HStack(spacing: 1) {
                    ForEach(WidgetCategory.allCases, id: \.rawValue) { cat in
                        let ratio = entry.data.todayTotalTime > 0
                            ? (entry.data.todayCategoryTimes[cat.rawValue] ?? 0) / entry.data.todayTotalTime
                            : 0.25
                        Rectangle()
                            .fill(categoryColor(cat.rawValue))
                            .frame(width: max(2, geo.size.width * ratio))
                    }
                }
                .clipShape(Capsule())
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: TimeTrackerEntry

    var body: some View {
        HStack(spacing: 16) {
            // 左侧：计时状态
            VStack(alignment: .leading, spacing: 6) {
                if entry.data.isTimerRunning {
                    let cat = WidgetCategory.from(rawValue: entry.data.activeCategory)
                    HStack(spacing: 4) {
                        Image(systemName: cat.icon)
                            .font(.caption)
                        Text(cat.displayName)
                            .font(.caption.weight(.semibold))
                        Text("计时中")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(categoryColor(cat.rawValue))

                    if let startTime = entry.data.activeStartTime {
                        Text(startTime, style: .timer)
                            .font(.system(.title, design: .monospaced, weight: .medium))
                            .foregroundStyle(categoryColor(cat.rawValue))
                    }
                } else {
                    Text("今日时间")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(entry.data.formattedTotalTime)
                        .font(.system(.title, design: .rounded, weight: .bold))
                }

                Spacer()

                // 底部指标
                HStack(spacing: 12) {
                    // 评分
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(scoreColor(entry.data.todayQualityScore))
                        Text("\(Int(entry.data.todayQualityScore))")
                            .font(.caption.weight(.semibold))
                    }

                    // Streak
                    if entry.data.currentStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text("\(entry.data.currentStreak)天")
                                .font(.caption.weight(.semibold))
                        }
                    }

                    // 深度工作
                    if entry.data.todayDeepWorkCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "brain.head.profile.fill")
                                .font(.caption2)
                                .foregroundStyle(.indigo)
                            Text("\(entry.data.todayDeepWorkCount)")
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
            }

            Divider()

            // 右侧：分类时间
            VStack(alignment: .leading, spacing: 8) {
                ForEach(WidgetCategory.allCases, id: \.rawValue) { cat in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(categoryColor(cat.rawValue))
                            .frame(width: 8, height: 8)

                        Text(cat.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .leading)

                        Text(entry.data.formattedTime(for: cat.rawValue))
                            .font(.caption.weight(.medium).monospacedDigit())
                    }
                }
            }
        }
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: TimeTrackerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部：状态 + 总时间
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if entry.data.isTimerRunning {
                        let cat = WidgetCategory.from(rawValue: entry.data.activeCategory)
                        HStack(spacing: 4) {
                            Image(systemName: cat.icon)
                            Text("\(cat.displayName)计时中")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(categoryColor(cat.rawValue))

                        if let startTime = entry.data.activeStartTime {
                            Text(startTime, style: .timer)
                                .font(.system(.title, design: .monospaced, weight: .medium))
                                .foregroundStyle(categoryColor(cat.rawValue))
                        }
                    } else {
                        Text("今日时间概览")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(entry.data.formattedTotalTime)
                            .font(.system(.title, design: .rounded, weight: .bold))
                    }
                }

                Spacer()

                // 质量评分圆
                ZStack {
                    Circle()
                        .stroke(.secondary.opacity(0.2), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: entry.data.todayQualityScore / 100)
                        .stroke(scoreColor(entry.data.todayQualityScore), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(Int(entry.data.todayQualityScore))")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        Text("分")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 56, height: 56)
            }

            Divider()

            // 分类详情
            ForEach(WidgetCategory.allCases, id: \.rawValue) { cat in
                HStack(spacing: 8) {
                    Image(systemName: cat.icon)
                        .font(.caption)
                        .foregroundStyle(categoryColor(cat.rawValue))
                        .frame(width: 20)

                    Text(cat.displayName)
                        .font(.subheadline)
                        .frame(width: 32, alignment: .leading)

                    // 进度条
                    GeometryReader { geo in
                        let ratio = entry.data.todayTotalTime > 0
                            ? (entry.data.todayCategoryTimes[cat.rawValue] ?? 0) / entry.data.todayTotalTime
                            : 0
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.secondary.opacity(0.15))
                            Capsule()
                                .fill(categoryColor(cat.rawValue))
                                .frame(width: max(2, geo.size.width * ratio))
                        }
                    }
                    .frame(height: 8)

                    Text(entry.data.formattedTime(for: cat.rawValue))
                        .font(.caption.weight(.medium).monospacedDigit())
                        .frame(width: 50, alignment: .trailing)
                }
            }

            Divider()

            // 底部指标
            HStack {
                // 连续记录
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("连续 \(entry.data.currentStreak) 天")
                        .font(.caption)
                }

                Spacer()

                // 深度工作
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile.fill")
                        .foregroundStyle(.indigo)
                    Text("深度工作 \(entry.data.todayDeepWorkCount) 次")
                        .font(.caption)
                }

                Spacer()

                // 消耗预算
                HStack(spacing: 4) {
                    Image(systemName: entry.data.isConsumptionOverBudget ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(entry.data.isConsumptionOverBudget ? .red : .green)
                    Text(entry.data.isConsumptionOverBudget ? "消耗超标" : "预算正常")
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Widget 定义

struct TimeWidget: Widget {
    let kind: String = "TimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeTrackerProvider()) { entry in
            TimeWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("时间追踪")
        .description("查看今日时间分配和计时状态")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TimeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: TimeTrackerEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - 锁屏 Widget（F-31）

struct LockScreenWidget: Widget {
    let kind: String = "TimeWidgetLockScreen"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeTrackerProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("时间追踪")
        .description("锁屏查看今日概览")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct LockScreenWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: TimeTrackerEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }

    // MARK: - Circular（圆形）

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                if entry.data.isTimerRunning {
                    let cat = WidgetCategory.from(rawValue: entry.data.activeCategory)
                    Image(systemName: cat.icon)
                        .font(.caption)
                    if let startTime = entry.data.activeStartTime {
                        Text(startTime, style: .timer)
                            .font(.system(.caption2, design: .monospaced))
                            .minimumScaleFactor(0.6)
                    }
                } else {
                    Text("\(Int(entry.data.todayQualityScore))")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("分")
                        .font(.caption2)
                }
            }
        }
    }

    // MARK: - Rectangular（矩形）

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            if entry.data.isTimerRunning {
                let cat = WidgetCategory.from(rawValue: entry.data.activeCategory)
                HStack(spacing: 4) {
                    Image(systemName: cat.icon)
                        .font(.caption2)
                    Text("\(cat.displayName)计时中")
                        .font(.caption2.weight(.semibold))
                }
                if let startTime = entry.data.activeStartTime {
                    Text(startTime, style: .timer)
                        .font(.system(.headline, design: .monospaced))
                }
            } else {
                HStack {
                    Text("今日 \(entry.data.formattedTotalTime)")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text("⭐\(Int(entry.data.todayQualityScore))分")
                        .font(.caption2)
                }
                // 简化分类条
                HStack(spacing: 2) {
                    ForEach(WidgetCategory.allCases, id: \.rawValue) { cat in
                        let time = entry.data.todayCategoryTimes[cat.rawValue] ?? 0
                        if time > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 8))
                                Text(entry.data.formattedTime(for: cat.rawValue))
                                    .font(.system(size: 9))
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Inline（单行）

    private var inlineView: some View {
        Group {
            if entry.data.isTimerRunning {
                let cat = WidgetCategory.from(rawValue: entry.data.activeCategory)
                Label("\(cat.displayName)计时中", systemImage: cat.icon)
            } else {
                Label("今日 \(entry.data.formattedTotalTime) · \(Int(entry.data.todayQualityScore))分", systemImage: "clock.fill")
            }
        }
    }
}

// MARK: - 颜色工具

func categoryColor(_ rawValue: String) -> Color {
    switch rawValue {
    case "input":       return .blue
    case "output":      return .green
    case "consumption": return .orange
    case "maintenance": return .purple
    default:            return .gray
    }
}

func scoreColor(_ score: Double) -> Color {
    switch score {
    case 80...100: return .green
    case 60..<80:  return .blue
    case 40..<60:  return .orange
    default:       return .red
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    TimeWidget()
} timeline: {
    TimeTrackerEntry.placeholder
}

#Preview(as: .systemMedium) {
    TimeWidget()
} timeline: {
    TimeTrackerEntry.placeholder
}

#Preview(as: .systemLarge) {
    TimeWidget()
} timeline: {
    TimeTrackerEntry.placeholder
}
