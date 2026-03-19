//
//  TimerView.swift
//  TimeTracker
//
//  计时主视图 - 快速开始/结束 + 快捷按钮
//

import SwiftUI

struct TimerView: View {
    @Bindable var viewModel: TimeTrackingViewModel
    @State private var stopNotes: String = ""
    @State private var showStopSheet: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - 当前计时状态
                    activeTimerSection

                    // MARK: - 快捷启动按钮
                    quickStartSection

                    // MARK: - 今日概览
                    todaySummarySection
                }
                .padding()
            }
            .navigationTitle("时间追踪")
            .sheet(isPresented: $showStopSheet) {
                stopTimerSheet
            }
            .sheet(isPresented: $viewModel.showingAddEntry) {
                AddEntryView(viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingAddEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
        }
    }

    // MARK: - 当前计时区域
    @ViewBuilder
    private var activeTimerSection: some View {
        if let active = viewModel.activeEntry {
            VStack(spacing: 16) {
                // 分类标签
                HStack {
                    Image(systemName: active.category.icon)
                    Text(active.category.displayName)
                    Text("·")
                    Text(active.category.subtitle)
                        .foregroundStyle(.secondary)
                }
                .font(.headline)

                // 计时器显示
                Text(viewModel.elapsedTime.timerFormatted)
                    .font(.system(size: 56, weight: .light, design: .monospaced))
                    .foregroundStyle(active.category.color)

                // 开始时间
                Text("开始于 \(DateHelper.timeString(active.startTime))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // 停止按钮
                Button {
                    showStopSheet = true
                } label: {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("停止计时")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red.gradient, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        } else {
            // 无活跃计时
            VStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("当前无进行中的计时")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("选择下方分类快速开始")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    // MARK: - 快捷启动按钮
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速开始")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(TimeCategory.allCases) { category in
                    Button {
                        viewModel.quickStart(category: category)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.title2)
                            Text(category.displayName)
                                .font(.headline)
                            Text(category.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(category.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(category.color.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.activeEntry != nil)
                    .opacity(viewModel.activeEntry != nil ? 0.5 : 1)
                }
            }
        }
    }

    // MARK: - 今日概览
    private var todaySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日概览")
                    .font(.headline)
                Spacer()
                Text(DateHelper.shortDateString(Date()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            let summary = viewModel.dailySummary(for: Date())

            HStack(spacing: 16) {
                SummaryMiniCard(
                    title: "已记录",
                    value: summary.formattedTotalTime,
                    color: .blue
                )
                SummaryMiniCard(
                    title: "空白",
                    value: summary.formattedEmptyTime,
                    color: .gray
                )
                SummaryMiniCard(
                    title: "效率",
                    value: "\(Int(summary.outputScore * 100))%",
                    color: .green
                )
            }

            // 各分类条形
            ForEach(TimeCategory.allCases) { cat in
                let time = summary.totalTimePerCategory[cat] ?? 0
                let ratio = summary.totalTrackedTime > 0
                    ? time / summary.totalTrackedTime
                    : 0

                HStack {
                    Image(systemName: cat.icon)
                        .foregroundStyle(cat.color)
                        .frame(width: 24)
                    Text(cat.displayName)
                        .font(.subheadline)
                    Spacer()
                    Text(time.shortFormatted)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(cat.color.opacity(0.3))
                        .frame(width: geo.size.width * max(ratio, 0.01), height: 6)
                }
                .frame(height: 6)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 停止计时弹窗
    private var stopTimerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let active = viewModel.activeEntry {
                    HStack {
                        Image(systemName: active.category.icon)
                            .foregroundStyle(active.category.color)
                        Text(active.category.displayName)
                            .font(.headline)
                        Spacer()
                        Text(viewModel.elapsedTime.shortFormatted)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }

                TextField("添加备注（可选）", text: $stopNotes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)

                Button {
                    viewModel.stopTracking(notes: stopNotes.isEmpty ? nil : stopNotes)
                    stopNotes = ""
                    showStopSheet = false
                } label: {
                    Text("确认停止")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.gradient, in: RoundedRectangle(cornerRadius: 14))
                }

                Spacer()
            }
            .padding()
            .navigationTitle("停止计时")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showStopSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - 概览小卡片
struct SummaryMiniCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}
