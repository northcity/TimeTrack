//
//  WeeklyReviewView.swift
//  TimeTracker
//
//  周复盘视图 - 趋势、输出占比、行为评分
//

import SwiftUI

struct WeeklyReviewView: View {
    @Bindable var viewModel: TimeTrackingViewModel
    @State private var currentWeekStart: Date = DateHelper.startOfWeek(Date())

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 周导航
                    weekNavigator

                    let summary = viewModel.weeklySummary(for: currentWeekStart)

                    // 周总览
                    weekOverviewCard(summary: summary)

                    // 每日输出评分趋势
                    dailyTrendChart(summary: summary)

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
                    Text("\(Int(summary.averageOutputScore * 100))%")
                        .font(.title2.bold())
                        .foregroundStyle(scoreColor(summary.averageOutputScore))
                    Text("平均效率")
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
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 每日输出评分趋势（柱状图）
    private func dailyTrendChart(summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每日效率趋势")
                .font(.headline)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(summary.dailySummaries) { daily in
                    VStack(spacing: 4) {
                        Text("\(Int(daily.outputScore * 100))%")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(scoreColor(daily.outputScore).gradient)
                            .frame(
                                width: 32,
                                height: max(CGFloat(daily.outputScore) * 120, 4)
                            )

                        Text(DateHelper.weekdayString(daily.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160, alignment: .bottom)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 分类饼图概览
    private func categoryPieChart(summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类占比")
                .font(.headline)

            HStack(spacing: 16) {
                // 简化饼图：使用环形占比
                ZStack {
                    ForEach(Array(pieSliceData(summary: summary).enumerated()), id: \.offset) { index, slice in
                        Circle()
                            .trim(from: slice.startAngle, to: slice.endAngle)
                            .stroke(slice.color, lineWidth: 20)
                            .rotationEffect(.degrees(-90))
                    }
                }
                .frame(width: 100, height: 100)

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

    private struct PieSlice {
        let startAngle: CGFloat
        let endAngle: CGFloat
        let color: Color
    }

    private func pieSliceData(summary: WeeklySummary) -> [PieSlice] {
        var slices: [PieSlice] = []
        var currentAngle: CGFloat = 0

        guard summary.totalTrackedTime > 0 else {
            return [PieSlice(startAngle: 0, endAngle: 1, color: .secondary.opacity(0.2))]
        }

        for cat in TimeCategory.allCases {
            let time = summary.totalTimePerCategory[cat] ?? 0
            let ratio = CGFloat(time / summary.totalTrackedTime)
            if ratio > 0 {
                slices.append(PieSlice(
                    startAngle: currentAngle,
                    endAngle: currentAngle + ratio,
                    color: cat.color
                ))
                currentAngle += ratio
            }
        }

        return slices
    }
}
