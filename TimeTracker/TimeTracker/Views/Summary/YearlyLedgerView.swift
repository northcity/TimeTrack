//
//  YearlyLedgerView.swift
//  TimeTracker
//
//  年度累计账本 + 年报（F-22/23/37）
//  展示年度汇总、月度趋势、年度洞察
//

import SwiftUI
import Charts

struct YearlyLedgerView: View {
    @Bindable var viewModel: TimeTrackingViewModel
    @State private var currentYear: Int = Calendar.current.component(.year, from: Date())
    @State private var showShareCard = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 年份导航
                    yearNavigator

                    let comparison = viewModel.yearlyComparison(year: currentYear)
                    let summary = comparison.current

                    // 年度总览卡片
                    yearOverviewCard(summary: summary, comparison: comparison)

                    // 分类时间账本
                    categoryLedger(summary: summary, comparison: comparison)

                    // 月度趋势图
                    monthlyTrendChart(summary: summary)

                    // 月度质量评分趋势
                    monthlyQualityChart(summary: summary)

                    // 年度亮点
                    yearHighlights(summary: summary)

                    // 年度洞察
                    yearInsights(summary: summary)
                }
                .padding()
            }
            .navigationTitle("年报")
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
                let summary = viewModel.yearlySummary(year: currentYear)
                YearlyShareCardView(summary: summary)
            }
        }
    }

    // MARK: - 年份导航

    private var yearNavigator: some View {
        HStack {
            Button {
                withAnimation {
                    currentYear -= 1
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("\(String(currentYear))年")
                    .font(.headline)
                let summary = viewModel.yearlySummary(year: currentYear)
                Text("记录 \(summary.recordedDays) 天 / \(summary.totalDaysInYear) 天")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation {
                    let thisYear = Calendar.current.component(.year, from: Date())
                    if currentYear < thisYear {
                        currentYear += 1
                    }
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .disabled(currentYear >= Calendar.current.component(.year, from: Date()))
        }
    }

    // MARK: - 年度总览卡片

    private func yearOverviewCard(summary: YearlySummary, comparison: YearlyComparison) -> some View {
        VStack(spacing: 16) {
            // 总时间
            VStack(spacing: 4) {
                Text(summary.totalHours)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("小时")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 变化描述
            Text(comparison.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            // 关键指标
            HStack(spacing: 0) {
                yearStatItem(title: "记录天数", value: "\(summary.recordedDays)")
                yearStatItem(title: "覆盖率", value: "\(Int(summary.recordCompletionRate * 100))%")
                yearStatItem(title: "深度工作", value: "\(summary.totalDeepWorkCount)次")
                yearStatItem(title: "日均", value: formatHours(summary.averageDailyTime))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func yearStatItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .semibold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 分类时间账本

    private func categoryLedger(summary: YearlySummary, comparison: YearlyComparison) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时间账本")
                .font(.headline)

            // 分类占比饼图
            Chart(TimeCategory.allCases, id: \.self) { category in
                SectorMark(
                    angle: .value("时间", summary.totalTimePerCategory[category] ?? 0),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(category.color)
                .annotation(position: .overlay) {
                    let ratio = summary.ratio(for: category)
                    if ratio > 0.08 {
                        Text("\(Int(ratio * 100))%")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(height: 180)
            .padding(.bottom, 8)

            // 各分类详情
            ForEach(TimeCategory.allCases) { category in
                HStack {
                    Circle()
                        .fill(category.color)
                        .frame(width: 10, height: 10)

                    Text(category.displayName)
                        .font(.subheadline)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(summary.formattedTime(for: category))
                            .font(.subheadline.weight(.medium))

                        HStack(spacing: 4) {
                            Text("\(summary.hours(for: category))h")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let change = comparison.ratioChange(for: category) {
                                let arrow = change >= 0 ? "↑" : "↓"
                                let changeColor: Color = {
                                    switch category {
                                    case .output, .input:
                                        return change >= 0 ? .green : .red
                                    case .consumption:
                                        return change >= 0 ? .red : .green
                                    case .maintenance:
                                        return .secondary
                                    }
                                }()
                                Text("\(arrow)\(Int(abs(change) * 100))%")
                                    .font(.caption2)
                                    .foregroundStyle(changeColor)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)

                if category != TimeCategory.allCases.last {
                    Divider()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 月度趋势图

    private func monthlyTrendChart(summary: YearlySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("月度趋势")
                .font(.headline)

            let trendData = summary.monthlyTrend

            if trendData.isEmpty {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart {
                    ForEach(trendData) { item in
                        BarMark(
                            x: .value("月份", "\(item.month)月"),
                            y: .value("小时", item.hours)
                        )
                        .foregroundStyle(by: .value("分类", item.category.displayName))
                    }
                }
                .chartForegroundStyleScale([
                    "输入": Color.blue,
                    "输出": Color.green,
                    "消耗": Color.orange,
                    "维持": Color.purple
                ])
                .frame(height: 200)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 月度质量评分趋势

    private func monthlyQualityChart(summary: YearlySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("质量评分趋势")
                .font(.headline)

            let qualityData = summary.monthlyQualityScores

            if qualityData.isEmpty {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                Chart {
                    ForEach(qualityData) { item in
                        LineMark(
                            x: .value("月份", "\(item.month)月"),
                            y: .value("评分", item.score)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("月份", "\(item.month)月"),
                            y: .value("评分", item.score)
                        )
                        .foregroundStyle(.blue)
                        .annotation(position: .top) {
                            Text("\(Int(item.score))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // 及格线
                    RuleMark(y: .value("及格", 60))
                        .foregroundStyle(.orange.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                        .annotation(position: .leading) {
                            Text("60")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                }
                .chartYScale(domain: 0...100)
                .frame(height: 160)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 年度亮点

    private func yearHighlights(summary: YearlySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("年度亮点")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // 总投入
                highlightCard(
                    icon: "clock.fill",
                    color: .blue,
                    title: "总投入",
                    value: "\(summary.totalHours)h",
                    subtitle: "约 \(Int(summary.totalTrackedTime / 86400)) 天"
                )

                // 最佳月份
                if let best = summary.bestMonth {
                    highlightCard(
                        icon: "crown.fill",
                        color: .yellow,
                        title: "最高效月份",
                        value: best.shortDisplayName,
                        subtitle: "产出+输入占比最高"
                    )
                }

                // 最活跃月份
                if let active = summary.mostActiveMonth {
                    highlightCard(
                        icon: "flame.fill",
                        color: .orange,
                        title: "最活跃月份",
                        value: active.shortDisplayName,
                        subtitle: active.formattedTotalTime
                    )
                }

                // 深度工作
                highlightCard(
                    icon: "brain.head.profile.fill",
                    color: .indigo,
                    title: "深度工作",
                    value: "\(summary.totalDeepWorkCount)次",
                    subtitle: formatHoursShort(summary.totalDeepWorkDuration)
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func highlightCard(icon: String, color: Color, title: String, value: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 年度洞察

    private func yearInsights(summary: YearlySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("年度洞察")
                .font(.headline)

            let insights = summary.insights
            if insights.isEmpty {
                Text("继续记录以获得年度洞察")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(insights.enumerated()), id: \.offset) { _, insight in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                            .padding(.top, 2)
                        Text(insight)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func formatHours(_ interval: TimeInterval) -> String {
        let h = interval / 3600
        return String(format: "%.1fh", h)
    }

    private func formatHoursShort(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }

    private func navigateYear(delta: Int) {
        currentYear += delta
    }
}

// MARK: - 年报分享卡片

struct YearlyShareCardView: View {
    let summary: YearlySummary
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    shareCardContent
                        .padding()
                }
            }
            .navigationTitle("年报卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        generateShareImage()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    @ViewBuilder
    private var shareCardContent: some View {
        VStack(spacing: 20) {
            // 标题
            VStack(spacing: 6) {
                Text("⏱ TimeTracker")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(String(summary.year))年度时间报告")
                    .font(.title2.weight(.bold))
            }

            Divider()

            // 核心数字
            HStack(spacing: 0) {
                shareStatItem(value: summary.totalHours, label: "总小时")
                shareStatItem(value: "\(summary.recordedDays)", label: "记录天数")
                shareStatItem(value: "\(summary.totalDeepWorkCount)", label: "深度工作")
            }

            // 分类占比
            HStack(spacing: 12) {
                ForEach(TimeCategory.allCases) { category in
                    VStack(spacing: 4) {
                        Text("\(Int(summary.ratio(for: category) * 100))%")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(category.color)
                        Text(category.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            // 亮点
            if let best = summary.bestMonth {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("最高效月份：\(best.shortDisplayName)")
                        .font(.subheadline)
                }
            }

            // 底部品牌
            VStack(spacing: 2) {
                Text("用 TimeTracker 追踪时间")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("柳比歇夫时间统计法 · \(String(summary.year))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    private func shareStatItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @MainActor
    private func generateShareImage() {
        let renderer = ImageRenderer(content:
            shareCardContent
                .frame(width: 360)
                .padding(20)
                .background(.white)
        )
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            shareImage = uiImage
            showShareSheet = true
        }
    }
}

// ShareSheet 已在 ShareCardView.swift 中定义，此处复用
