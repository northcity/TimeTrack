//
//  WeeklyReviewView.swift
//  TimeTracker
//
//  周复盘视图 - 趋势、输出占比、行为评分
//

import SwiftUI
import Charts

struct WeeklyReviewView: View {
    @Bindable var viewModel: TimeTrackingViewModel
    @State private var currentWeekStart: Date = DateHelper.startOfWeek(Date())
    @State private var showShareCard = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 周导航
                    weekNavigator

                    let summary = viewModel.weeklySummary(for: currentWeekStart)

                    // 周总览
                    weekOverviewCard(summary: summary)

                    // 周质量评分（F-26/27/28）
                    QualityScoreCardView(scoreResult: summary.qualityScore)

                    // 时间雷达图（F-18）
                    radarChart(summary: summary)

                    // 深度工作周统计（F-24/25）
                    weekDeepWorkCard(summary: summary)

                    // 每日质量评分趋势
                    dailyQualityTrendChart(summary: summary)

                    // 每日分类堆叠图（Swift Charts）
                    dailyStackedChart(summary: summary)

                    // 分类饼图概览
                    categoryPieChart(summary: summary)

                    // 每日明细
                    dailyBreakdown(summary: summary)

                    // 周洞察
                    weekInsights(summary: summary)
                }
                .padding()
            }
            .navigationTitle("周报")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showShareCard = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareCard) {
                ShareCardView(
                    summary: viewModel.weeklySummary(for: currentWeekStart),
                    weekStart: currentWeekStart
                )
            }
        }
    }

    // MARK: - 周导航
    private var weekNavigator: some View {
        HStack {
            Button {
                withAnimation {
                    currentWeekStart = DateHelper.previousWeekStart(from: currentWeekStart)
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart
            VStack(spacing: 2) {
                Text("\(DateHelper.shortDateString(currentWeekStart)) - \(DateHelper.shortDateString(weekEnd))")
                    .font(.headline)
                Text("第 \(Calendar.current.component(.weekOfYear, from: currentWeekStart)) 周")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation {
                    currentWeekStart = DateHelper.nextWeekStart(from: currentWeekStart)
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 周总览卡片
    private func weekOverviewCard(summary: WeeklySummary) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text(summary.formattedTotalTime)
                        .font(.title2.bold())
                    Text("总记录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 40)

                VStack(spacing: 6) {
                    MiniScoreView(score: summary.qualityScore.totalScore, size: 40)
                    Text("质量分")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 40)

                VStack(spacing: 6) {
                    Text("\(summary.dailySummaries.filter { $0.totalTrackedTime > 0 }.count)")
                        .font(.title2.bold())
                    Text("记录天数")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 40)

                VStack(spacing: 6) {
                    Text("\(summary.totalDeepWorkCount)")
                        .font(.title2.bold())
                        .foregroundStyle(.blue)
                    Text("深度工作")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 时间雷达图（F-18）
    private func radarChart(summary: WeeklySummary) -> some View {
        let total = summary.totalTrackedTime
        var actualData: [TimeCategory: Double] = [:]
        for cat in TimeCategory.allCases {
            actualData[cat] = total > 0 ? (summary.totalTimePerCategory[cat] ?? 0) / total : 0
        }
        return RadarChartView(
            data: actualData,
            idealData: RadarChartView.idealDistribution
        )
    }

    // MARK: - 深度工作周统计（F-24/25）
    private func weekDeepWorkCard(summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.blue)
                Text("深度工作周统计")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(summary.totalDeepWorkCount)")
                        .font(.title.bold())
                        .foregroundStyle(.blue)
                    Text("总次数")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Text(summary.formattedDeepWorkDuration)
                        .font(.title.bold())
                        .foregroundStyle(.blue)
                    Text("总时长")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // 每日深度工作条形
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(summary.dailySummaries) { daily in
                    VStack(spacing: 4) {
                        if daily.deepWorkCount > 0 {
                            Text("\(daily.deepWorkCount)")
                                .font(.system(size: 9))
                                .foregroundStyle(.blue)
                            ForEach(0..<daily.deepWorkCount, id: \.self) { _ in
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.orange)
                            }
                        } else {
                            Text("-")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        Text(DateHelper.weekdayString(daily.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 60, alignment: .bottom)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 每日质量评分趋势（Swift Charts）
    private func dailyQualityTrendChart(summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每日质量评分")
                .font(.headline)

            Chart {
                ForEach(summary.dailySummaries) { daily in
                    let score = daily.qualityScore.totalScore
                    BarMark(
                        x: .value("日期", DateHelper.weekdayString(daily.date)),
                        y: .value("评分", score)
                    )
                    .foregroundStyle(qualityScoreColor(score).gradient)
                    .cornerRadius(6)
                    .annotation(position: .top, alignment: .center) {
                        if score > 0 {
                            Text("\(Int(score))")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // 及格线
                RuleMark(y: .value("及格", 60))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.orange.opacity(0.5))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("及格")
                            .font(.system(size: 8))
                            .foregroundStyle(.orange)
                    }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)")
                            .font(.system(size: 9))
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 分类饼图概览（Swift Charts SectorMark）
    private func categoryPieChart(summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类占比")
                .font(.headline)

            HStack(spacing: 16) {
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
                .frame(width: 120, height: 120)

                // 图例
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(TimeCategory.allCases) { cat in
                        let time = summary.totalTimePerCategory[cat] ?? 0
                        let ratio = summary.totalTrackedTime > 0 ? time / summary.totalTrackedTime : 0
                        HStack(spacing: 6) {
                            Circle()
                                .fill(cat.color)
                                .frame(width: 8, height: 8)
                            Text(cat.displayName)
                                .font(.caption)
                            Spacer()
                            Text(time.shortFormatted)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(Int(ratio * 100))%")
                                .font(.caption.bold())
                                .foregroundStyle(cat.color)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 每日分类堆叠图（Swift Charts）
    private func dailyStackedChart(summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每日时间分布")
                .font(.headline)

            Chart {
                ForEach(summary.dailySummaries) { daily in
                    ForEach(TimeCategory.allCases) { cat in
                        let hours = (daily.totalTimePerCategory[cat] ?? 0) / 3600
                        BarMark(
                            x: .value("日期", DateHelper.weekdayString(daily.date)),
                            y: .value("小时", hours)
                        )
                        .foregroundStyle(by: .value("分类", cat.displayName))
                    }
                }
            }
            .chartForegroundStyleScale([
                TimeCategory.input.displayName: TimeCategory.input.color,
                TimeCategory.output.displayName: TimeCategory.output.color,
                TimeCategory.consumption.displayName: TimeCategory.consumption.color,
                TimeCategory.maintenance.displayName: TimeCategory.maintenance.color
            ])
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v))h")
                                .font(.system(size: 9))
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 每日明细
    private func dailyBreakdown(summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每日明细")
                .font(.headline)

            ForEach(summary.dailySummaries) { daily in
                VStack(spacing: 6) {
                    HStack {
                        Text(DateHelper.weekdayString(daily.date))
                            .font(.subheadline.bold())
                        Text(DateHelper.shortDateString(daily.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(daily.formattedTotalTime)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // 堆叠条形图
                    GeometryReader { geo in
                        HStack(spacing: 1) {
                            ForEach(TimeCategory.allCases) { cat in
                                let time = daily.totalTimePerCategory[cat] ?? 0
                                let ratio = daily.totalTrackedTime > 0 ? time / daily.totalTrackedTime : 0
                                if ratio > 0 {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(cat.color)
                                        .frame(width: geo.size.width * ratio)
                                }
                            }

                            // 空白时段
                            let trackedRatio = daily.totalTrackedTime / 57600
                            if trackedRatio < 1 {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.secondary.opacity(0.1))
                            }
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 周洞察
    private func weekInsights(summary: WeeklySummary) -> some View {
        Group {
            if !summary.insights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text("周度洞察")
                            .font(.headline)
                    }

                    ForEach(summary.insights, id: \.self) { insight in
                        HStack(alignment: .top, spacing: 8) {
                            Text("💡")
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

    // MARK: - Helpers

    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.5 { return .green }
        if score >= 0.3 { return .orange }
        return .red
    }

    private func qualityScoreColor(_ score: Double) -> Color {
        let level = QualityScoreResult.ScoreLevel.from(score: score)
        switch level {
        case .excellent: return .green
        case .good: return .blue
        case .average: return .orange
        case .poor: return .red
        }
    }
}
