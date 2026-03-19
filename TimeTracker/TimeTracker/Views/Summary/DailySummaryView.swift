//
//  DailySummaryView.swift
//  TimeTracker
//
//  每日汇总统计视图
//

import SwiftUI

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

                    // 分类详情
                    categoryBreakdown(summary: summary)

                    // 空白时间提示
                    gapSection

                    // 洞察提示
                    insightsSection(summary: summary)

                    // 今日记录列表
                    entriesListSection(summary: summary)
                }
                .padding()
            }
            .navigationTitle("日报")
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
                Text("\(Int(summary.outputScore * 100))%")
                    .font(.title2.bold())
                    .foregroundStyle(scoreColor(summary.outputScore))
                Text("效率")
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
                                viewModel.showingBackfill = true
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
}
