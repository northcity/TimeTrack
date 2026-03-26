//
//  MonthlyLedgerView.swift
//  TimeTracker
//
//  月度时间账本（F-21）
//  展示月度各分类绝对时间、占比、对比上月变化
//

import SwiftUI

struct MonthlyLedgerView: View {
    @Bindable var viewModel: TimeTrackingViewModel
    @State private var currentYear: Int = Calendar.current.component(.year, from: Date())
    @State private var currentMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var showCSVExport = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 月份导航
                    monthNavigator

                    let comparison = viewModel.monthlyComparison(year: currentYear, month: currentMonth)
                    let summary = comparison.current

                    // 月总览卡片
                    monthOverviewCard(summary: summary, comparison: comparison)

                    // 各分类账本
                    categoryLedger(summary: summary, comparison: comparison)

                    // 每日记录热力图
                    dailyHeatMap(summary: summary)

                    // 月度洞察
                    monthInsights(summary: summary)
                }
                .padding()
            }
            .navigationTitle("月报")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCSVExport = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showCSVExport) {
                CSVExportView(viewModel: viewModel)
            }
        }
    }

    // MARK: - 月份导航
    private var monthNavigator: some View {
        HStack {
            Button {
                withAnimation {
                    navigateMonth(delta: -1)
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("\(currentYear)年\(currentMonth)月")
                    .font(.headline)
                let summary = viewModel.monthlySummary(year: currentYear, month: currentMonth)
                Text("记录 \(summary.recordedDays)/\(summary.totalDays) 天")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation {
                    navigateMonth(delta: 1)
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 月总览卡片
    private func monthOverviewCard(summary: MonthlySummary, comparison: MonthlyComparison) -> some View {
        VStack(spacing: 16) {
            // 总时间 + 变化
            VStack(spacing: 4) {
                Text(summary.formattedTotalTime)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text(comparison.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text("\(summary.recordedDays)")
                        .font(.title2.bold())
                    Text("记录天数")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 40)

                VStack(spacing: 6) {
                    Text(formatInterval(summary.averageDailyTime))
                        .font(.title2.bold())
                    Text("日均时长")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 40)

                VStack(spacing: 6) {
                    let productRatio = summary.ratio(for: .output) + summary.ratio(for: .input)
                    Text("\(Int(productRatio * 100))%")
                        .font(.title2.bold())
                        .foregroundStyle(productRatio >= 0.35 ? .green : .orange)
                    Text("高效占比")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 各分类账本
    private func categoryLedger(summary: MonthlySummary, comparison: MonthlyComparison) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("分类账本")
                .font(.headline)

            ForEach(TimeCategory.allCases) { cat in
                let ratio = summary.ratio(for: cat)
                let change = comparison.ratioChange(for: cat)

                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: cat.icon)
                            .foregroundStyle(cat.color)
                            .frame(width: 24)
                        Text(cat.displayName)
                            .font(.subheadline.bold())

                        Spacer()

                        // 绝对小时数
                        Text("\(summary.hours(for: cat))h")
                            .font(.title3.bold())
                            .foregroundStyle(cat.color)

                        // 占比
                        Text("(\(Int(ratio * 100))%)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // 变化箭头
                        if let change = change {
                            changeIndicator(change: change)
                        }
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

    // MARK: - 每日热力图
    private func dailyHeatMap(summary: MonthlySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每日记录")
                .font(.headline)

            let columns = Array(
                repeating: GridItem(.flexible(), spacing: 3),
                count: 7
            )

            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(summary.dailySummaries) { daily in
                    let intensity = min(daily.totalTrackedTime / 57600, 1.0)
                    let day = Calendar.current.component(.day, from: daily.date)
                    let isToday = DateHelper.isToday(daily.date)

                    VStack(spacing: 2) {
                        Text("\(day)")
                            .font(.system(size: 10))
                            .foregroundStyle(isToday ? .white : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(
                        heatColor(intensity: intensity, isToday: isToday),
                        in: RoundedRectangle(cornerRadius: 4)
                    )
                    .overlay(
                        isToday ? RoundedRectangle(cornerRadius: 4).stroke(Color.accentColor, lineWidth: 1.5) : nil
                    )
                }
            }

            // 图例
            HStack(spacing: 4) {
                Text("少")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatColor(intensity: level, isToday: false))
                        .frame(width: 12, height: 12)
                }
                Text("多")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 月度洞察
    private func monthInsights(summary: MonthlySummary) -> some View {
        Group {
            if !summary.insights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text("月度洞察")
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

    // MARK: - Helpers

    private func navigateMonth(delta: Int) {
        let calendar = Calendar.current
        guard let date = calendar.date(from: DateComponents(year: currentYear, month: currentMonth)),
              let newDate = calendar.date(byAdding: .month, value: delta, to: date) else { return }
        currentYear = calendar.component(.year, from: newDate)
        currentMonth = calendar.component(.month, from: newDate)
    }

    @ViewBuilder
    private func changeIndicator(change: Double) -> some View {
        let percent = Int(abs(change) * 100)
        if percent > 0 {
            HStack(spacing: 2) {
                Image(systemName: change > 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 9))
                Text("\(percent)%")
                    .font(.system(size: 9))
            }
            .foregroundStyle(change > 0 ? .green : .red)
        }
    }

    private func heatColor(intensity: Double, isToday: Bool) -> Color {
        if isToday {
            return .accentColor
        }
        if intensity <= 0 {
            return Color.secondary.opacity(0.05)
        }
        return Color.green.opacity(0.15 + intensity * 0.6)
    }

    private func formatInterval(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}
