//
//  BehaviorSuggestionView.swift
//  TimeTracker
//
//  AI 行为建议视图（F-33）
//  展示基于时间数据的个性化行为改善建议
//

import SwiftUI

// MARK: - 建议卡片列表

struct BehaviorSuggestionView: View {
    @Bindable var viewModel: TimeTrackingViewModel
    @State private var suggestions: [BehaviorSuggestion] = []
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("AI 行为建议")
                        .font(.headline)
                    Spacer()
                    Text("\(suggestions.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.15), in: Capsule())
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
            }

            if isExpanded {
                if suggestions.isEmpty {
                    emptyState
                } else {
                    ForEach(suggestions) { suggestion in
                        SuggestionCard(suggestion: suggestion)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            loadSuggestions()
        }
    }

    private var emptyState: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("暂无建议，状态很好！")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func loadSuggestions() {
        let today = Date()

        // 构建分析上下文
        let todaySummary = viewModel.dailySummary(for: today)
        let weeklySummary = viewModel.weeklySummary(for: today)

        // 获取上周汇总
        let calendar = Calendar.current
        let lastWeekDate = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let previousWeeklySummary = viewModel.weeklySummary(for: lastWeekDate)

        // 获取最近 7 天所有记录
        var recentEntries: [TimeEntry] = []
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                recentEntries.append(contentsOf: viewModel.entries(for: date))
            }
        }

        let context = BehaviorAnalysisContext(
            todaySummary: todaySummary,
            weeklySummary: weeklySummary,
            previousWeeklySummary: previousWeeklySummary.totalTrackedTime > 0 ? previousWeeklySummary : nil,
            currentStreak: viewModel.currentStreak,
            recentEntries: recentEntries
        )

        let engine = BehaviorSuggestionEngine()
        suggestions = engine.generateSuggestions(context: context)
    }
}

// MARK: - 单条建议卡片

struct SuggestionCard: View {
    let suggestion: BehaviorSuggestion
    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行
            HStack(spacing: 8) {
                Image(systemName: suggestion.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(suggestion.color)
                    .frame(width: 24, height: 24)

                Text(suggestion.title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                priorityBadge
            }

            // 详情
            if showDetail {
                Text(suggestion.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)

                if let actionHint = suggestion.actionHint {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption2)
                        Text(actionHint)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(suggestion.color)
                    .padding(.top, 2)
                }
            }
        }
        .padding(12)
        .background(suggestion.color.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(suggestion.color.opacity(0.15), lineWidth: 1)
        )
        .onTapGesture {
            withAnimation(.spring(duration: 0.25)) {
                showDetail.toggle()
            }
        }
    }

    @ViewBuilder
    private var priorityBadge: some View {
        switch suggestion.priority {
        case .critical:
            Text("紧急")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.red, in: Capsule())
        case .important:
            Text("重要")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.orange, in: Capsule())
        case .normal:
            Text("建议")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.secondary.opacity(0.15), in: Capsule())
        case .positive:
            Image(systemName: "hand.thumbsup.fill")
                .font(.caption2)
                .foregroundStyle(.green)
        }
    }
}

// MARK: - 内联迷你建议（用于 TimerView 等紧凑场景）

struct InlineSuggestionView: View {
    @Bindable var viewModel: TimeTrackingViewModel
    @State private var topSuggestion: BehaviorSuggestion?

    var body: some View {
        Group {
            if let suggestion = topSuggestion {
                HStack(spacing: 8) {
                    Image(systemName: suggestion.icon)
                        .font(.caption)
                        .foregroundStyle(suggestion.color)

                    Text(suggestion.title)
                        .font(.caption)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(suggestion.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .onAppear {
            loadTopSuggestion()
        }
    }

    private func loadTopSuggestion() {
        let today = Date()
        let todaySummary = viewModel.dailySummary(for: today)
        let weeklySummary = viewModel.weeklySummary(for: today)

        let calendar = Calendar.current
        let lastWeekDate = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let previousWeeklySummary = viewModel.weeklySummary(for: lastWeekDate)

        var recentEntries: [TimeEntry] = []
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                recentEntries.append(contentsOf: viewModel.entries(for: date))
            }
        }

        let context = BehaviorAnalysisContext(
            todaySummary: todaySummary,
            weeklySummary: weeklySummary,
            previousWeeklySummary: previousWeeklySummary.totalTrackedTime > 0 ? previousWeeklySummary : nil,
            currentStreak: viewModel.currentStreak,
            recentEntries: recentEntries
        )

        let engine = BehaviorSuggestionEngine()
        topSuggestion = engine.generateSuggestions(context: context).first
    }
}
