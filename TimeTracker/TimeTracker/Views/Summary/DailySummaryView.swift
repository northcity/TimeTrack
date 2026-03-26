//
//  DailySummaryView.swift
//  TimeTracker
//
//  每日汇总统计视图
//

import SwiftUI
import Charts

struct DailySummaryView: View {
    @Bindable var viewModel: TimeTrackingViewModel
    @State private var currentDate: Date = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 日期导航
                    dateNavigator

                    let summary = viewModel.dailySummary(for: currentDate)

                    // 总览卡片
                    overviewCard(summary: summary)

                    // 时间质量评分（F-27/28）
                    QualityScoreCardView(scoreResult: summary.qualityScore)

                    // 深度工作卡片（F-24/25）
                    DeepWorkCardView(
                        count: summary.deepWorkCount,
                        duration: summary.formattedDeepWorkDuration,
                        entries: summary.deepWorkEntries
                    )

                    // 消耗预算（F-41）
                    if DateHelper.isToday(currentDate) {
                        ConsumptionBudgetView(status: viewModel.todayConsumptionStatus)
                    }

                    // 分类详情
                    categoryBreakdown(summary: summary)

                    // 时间结构条（输入/输出/消耗/维持）
                    timeStructureBar(summary: summary)

                    // 空白时间提示
                    gapSection

                    // 洞察提示
                    insightsSection(summary: summary)

                    // AI 行为建议（F-33）
                    if DateHelper.isToday(currentDate) {
                        BehaviorSuggestionView(viewModel: viewModel)
                    }

                    // 今日记录列表
                    entriesListSection(summary: summary)
                }
                .padding()
            }
            .navigationTitle("日报")
            .sheet(isPresented: $viewModel.showingBackfill) {
                AddEntryView(
                    viewModel: viewModel,
                    presetStart: viewModel.backfillPresetStart,
                    presetEnd: viewModel.backfillPresetEnd
                )
            }
        }
    }

    // MARK: - 日期导航
    private var dateNavigator: some View {
        HStack {
            Button {
                withAnimation {
                    currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(DateHelper.fullDateString(currentDate))
                    .font(.headline)
                Text(DateHelper.weekdayString(currentDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation {
                    currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 总览卡片
    private func overviewCard(summary: DailySummary) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(summary.formattedTotalTime)
                    .font(.title2.bold())
                Text("已记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 40)

            VStack(spacing: 8) {
                Text(summary.formattedEmptyTime)
                    .font(.title2.bold())
                    .foregroundStyle(.orange)
                Text("空白")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 40)

            VStack(spacing: 8) {
                MiniScoreView(score: summary.qualityScore.totalScore, size: 40)
                Text("质量分")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 分类详情
    private func categoryBreakdown(summary: DailySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类统计")
                .font(.headline)

            ForEach(TimeCategory.allCases) { cat in
                let time = summary.totalTimePerCategory[cat] ?? 0
                let ratio = summary.totalTrackedTime > 0
                    ? time / summary.totalTrackedTime
                    : 0

                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: cat.icon)
                            .foregroundStyle(cat.color)
                            .frame(width: 24)
                        Text(cat.displayName)
                            .font(.subheadline.bold())
                        Text(cat.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(summary.formattedTime(for: cat))
                            .font(.subheadline.bold())
                            .foregroundStyle(cat.color)
                        Text("(\(Int(ratio * 100))%)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // 进度条
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.1))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(cat.color.gradient)
                                .frame(width: geo.size.width * max(ratio, 0))
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 空白时间提示 + 补记录入口
    private var gapSection: some View {
        let gaps = viewModel.findGaps(on: currentDate)
        return Group {
            if !gaps.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("未记录时段")
                            .font(.headline)
                        Spacer()
                    }

                    ForEach(Array(gaps.enumerated()), id: \.offset) { _, gap in
                        HStack {
                            Text("\(DateHelper.timeString(gap.start)) - \(DateHelper.timeString(gap.end))")
                                .font(.subheadline)
                            Spacer()
                            Text(gap.end.timeIntervalSince(gap.start).shortFormatted)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("补记录") {
                                viewModel.startBackfill(start: gap.start, end: gap.end)
                            }
                            .font(.caption)
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                    }
                }
                .padding(16)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - 时间结构条（Swift Charts 升级）
    private func timeStructureBar(summary: DailySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时间结构")
                .font(.headline)

            // Swift Charts 扇形图
            Chart {
                ForEach(TimeCategory.allCases) { cat in
                    let time = summary.totalTimePerCategory[cat] ?? 0
                    SectorMark(
                        angle: .value(cat.displayName, max(time, 0)),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(cat.color.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 140)

            // 各分类占比文字 + 判断
            ForEach(TimeCategory.allCases) { cat in
                let ratio = summary.totalTrackedTime > 0
                    ? (summary.totalTimePerCategory[cat] ?? 0) / summary.totalTrackedTime
                    : 0
                HStack(spacing: 6) {
                    Circle()
                        .fill(cat.color)
                        .frame(width: 8, height: 8)
                    Text(cat.displayName)
                        .font(.caption)
                    Text("\(Int(ratio * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(cat.color)
                    Spacer()
                    Text(summary.formattedTime(for: cat))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    // 人话判断
                    Text(structureJudgment(for: cat, ratio: ratio))
                        .font(.caption2)
                        .foregroundStyle(structureJudgmentColor(for: cat, ratio: ratio))
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 洞察提示
    private func insightsSection(summary: DailySummary) -> some View {
        Group {
            if !summary.insights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text("今日洞察")
                            .font(.headline)
                    }

                    ForEach(summary.insights, id: \.self) { insight in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(insight)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(Color.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - 今日记录列表
    private func entriesListSection(summary: DailySummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日记录 (\(summary.entries.count))")
                .font(.headline)

            if summary.entries.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("暂无记录")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 24)
            } else {
                ForEach(summary.entries.sorted(by: { $0.startTime < $1.startTime })) { entry in
                    NavigationLink {
                        EntryDetailView(entry: entry, viewModel: viewModel)
                    } label: {
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(entry.category.color)
                                .frame(width: 4, height: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.category.displayName)
                                    .font(.subheadline.bold())
                                Text("\(DateHelper.timeString(entry.startTime)) - \(entry.endTime.map(DateHelper.timeString) ?? "...")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(entry.formattedDuration)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers
    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.5 { return .green }
        if score >= 0.3 { return .orange }
        return .red
    }

    /// 时间结构人话判断
    private func structureJudgment(for category: TimeCategory, ratio: Double) -> String {
        switch category {
        case .output:
            if ratio >= 0.30 { return "优秀" }
            if ratio >= 0.15 { return "达标" }
            if ratio > 0 { return "⚠️ 不足" }
            return "⚠️ 严重不足"
        case .input:
            if ratio >= 0.30 { return "充足" }
            if ratio >= 0.20 { return "达标" }
            return "偏低"
        case .consumption:
            if ratio <= 0.15 { return "控制优秀" }
            if ratio <= 0.25 { return "正常" }
            if ratio <= 0.40 { return "⚠️ 偏高" }
            return "🚨 严重超标"
        case .maintenance:
            if ratio >= 0.30 && ratio <= 0.40 { return "正常" }
            if ratio > 0.40 { return "偏多" }
            return "偏少"
        }
    }

    private func structureJudgmentColor(for category: TimeCategory, ratio: Double) -> Color {
        switch category {
        case .output:
            return ratio >= 0.15 ? .green : .red
        case .input:
            return ratio >= 0.20 ? .green : .orange
        case .consumption:
            return ratio <= 0.25 ? .green : .red
        case .maintenance:
            return .secondary
        }
    }
}
