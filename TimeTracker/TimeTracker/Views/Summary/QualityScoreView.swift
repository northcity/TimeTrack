//
//  QualityScoreView.swift
//  TimeTracker
//
//  时间质量评分展示组件（F-27/28）
//  显示评分环、得分明细、改进建议
//

import SwiftUI

// MARK: - 质量评分卡片
struct QualityScoreCardView: View {
    let scoreResult: QualityScoreResult
    @State private var showDetail: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("时间质量")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation { showDetail.toggle() }
                } label: {
                    Image(systemName: showDetail ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 评分环 + 等级
            HStack(spacing: 24) {
                // 环形评分
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: scoreResult.totalScore / 100)
                        .stroke(
                            scoreColor.gradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: scoreResult.totalScore)

                    VStack(spacing: 2) {
                        Text("\(Int(scoreResult.totalScore))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(scoreColor)
                        Text("分")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 80, height: 80)

                // 等级和建议
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(scoreResult.level.emoji)
                        Text(scoreResult.level.displayName)
                            .font(.title3.bold())
                            .foregroundStyle(scoreColor)
                    }
                    Text(scoreResult.suggestion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            // 展开明细
            if showDetail {
                Divider()
                scoreBreakdownView
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 评分明细
    private var scoreBreakdownView: some View {
        VStack(spacing: 10) {
            ForEach(scoreResult.breakdowns) { item in
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: item.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(item.passed ? .green : .orange)
                        Text(item.ruleName)
                            .font(.subheadline)
                        Spacer()
                        Text("+\(Int(item.earned))")
                            .font(.subheadline.bold())
                            .foregroundStyle(item.passed ? .green : .orange)
                        Text("/\(Int(item.maxPoints))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
        }
    }

    private var scoreColor: Color {
        switch scoreResult.level {
        case .excellent: return .green
        case .good: return .blue
        case .average: return .orange
        case .poor: return .red
        }
    }
}

// MARK: - 迷你评分展示（用于概览卡片）
struct MiniScoreView: View {
    let score: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 3)
            Circle()
                .trim(from: 0, to: score / 100)
                .stroke(
                    scoreColor.gradient,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(Int(score))")
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor)
        }
        .frame(width: size, height: size)
    }

    private var scoreColor: Color {
        let level = QualityScoreResult.ScoreLevel.from(score: score)
        switch level {
        case .excellent: return .green
        case .good: return .blue
        case .average: return .orange
        case .poor: return .red
        }
    }
}

// MARK: - 深度工作卡片
struct DeepWorkCardView: View {
    let count: Int
    let duration: String
    let entries: [TimeEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.blue)
                Text("深度工作")
                    .font(.headline)
                Spacer()
                if count > 0 {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                }
            }

            if count == 0 {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "brain")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("暂无深度工作记录")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("连续专注 90 分钟以上自动识别")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(.title2.bold())
                            .foregroundStyle(.blue)
                        Text("次数")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 4) {
                        Text(duration)
                            .font(.title2.bold())
                            .foregroundStyle(.blue)
                        Text("总时长")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(entries) { entry in
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Image(systemName: entry.category.icon)
                            .font(.caption)
                            .foregroundStyle(entry.category.color)
                        Text(entry.category.displayName)
                            .font(.caption)
                        Text(DateHelper.timeString(entry.startTime))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("-")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(entry.endTime.map(DateHelper.timeString) ?? "...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(entry.formattedDuration)
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 消耗预算卡片
struct ConsumptionBudgetView: View {
    let status: ConsumptionBudgetStatus

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.title3)
                .foregroundStyle(statusColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("消耗预算")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(status.message)
                    .font(.subheadline)
                    .foregroundStyle(statusColor)
            }

            Spacer()

            // 进度环
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: min(usedRatio, 1.0))
                    .stroke(
                        statusColor.gradient,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 36, height: 36)
        }
        .padding(12)
        .background(statusColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private var usedRatio: CGFloat {
        switch status {
        case .normal(let used, let budget, _):
            return CGFloat(used / budget)
        case .warning(let used, let budget, _):
            return CGFloat(used / budget)
        case .exceeded(let used, let budget):
            return CGFloat(used / budget)
        }
    }

    private var statusIcon: String {
        switch status {
        case .normal: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .exceeded: return "xmark.shield.fill"
        }
    }

    private var statusColor: Color {
        switch status {
        case .normal: return .green
        case .warning: return .orange
        case .exceeded: return .red
        }
    }
}

// MARK: - 连续记录 Streak 视图
struct StreakBadgeView: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: streak > 0 ? "flame.fill" : "flame")
                .foregroundStyle(streak > 0 ? .orange : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("连续记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text("\(streak)")
                        .font(.title3.bold())
                        .foregroundStyle(streak > 0 ? .orange : .secondary)
                    Text("天")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            streak > 0
                ? Color.orange.opacity(0.1)
                : Color.secondary.opacity(0.05),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}
