//
//  ShareCardView.swift
//  TimeTracker
//
//  周报分享卡片（F-36）
//  生成可分享的周报摘要图片
//

import SwiftUI
import Charts

// MARK: - 分享卡片视图
struct ShareCardView: View {
    let summary: WeeklySummary
    let weekStart: Date
    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 预览卡片
                    cardContent
                        .padding(20)
                        .background(
                            LinearGradient(
                                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                        .padding(.horizontal)

                    // 分享按钮
                    Button {
                        renderAndShare()
                    } label: {
                        Label("分享周报", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("分享卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = renderedImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    // MARK: - 卡片内容（用于预览 & 渲染）
    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: 16) {
            // 标题
            VStack(spacing: 4) {
                Text("📊 周报摘要")
                    .font(.title2.bold())

                let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
                Text("\(DateHelper.shortDateString(weekStart)) - \(DateHelper.shortDateString(weekEnd))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // 核心数据
            HStack(spacing: 0) {
                statItem(value: summary.formattedTotalTime, label: "总记录")
                Divider().frame(height: 40)
                statItem(value: "\(Int(summary.qualityScore.totalScore))", label: "质量评分", color: qualityColor(summary.qualityScore.totalScore))
                Divider().frame(height: 40)
                statItem(value: "\(summary.totalDeepWorkCount)", label: "深度工作", color: .blue)
            }

            // 分类扇形图
            Chart {
                ForEach(TimeCategory.allCases) { cat in
                    let time = summary.totalTimePerCategory[cat] ?? 0
                    SectorMark(
                        angle: .value(cat.displayName, max(time, 0)),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(cat.color.gradient)
                    .cornerRadius(3)
                }
            }
            .frame(height: 140)

            // 分类明细
            HStack(spacing: 12) {
                ForEach(TimeCategory.allCases) { cat in
                    let time = summary.totalTimePerCategory[cat] ?? 0
                    let ratio = summary.totalTrackedTime > 0 ? time / summary.totalTrackedTime : 0
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Circle().fill(cat.color).frame(width: 6, height: 6)
                            Text(cat.displayName)
                                .font(.system(size: 10))
                        }
                        Text("\(Int(ratio * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(cat.color)
                    }
                }
            }

            Divider()

            // 质量评分详情
            let score = summary.qualityScore
            HStack(spacing: 16) {
                ForEach(score.breakdowns, id: \.ruleName) { bd in
                    VStack(spacing: 2) {
                        Text(bd.shortName)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text("\(Int(bd.earned))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(bd.earned >= bd.maxPoints * 0.6 ? .green : .orange)
                    }
                }
            }

            // 品牌水印
            HStack {
                Spacer()
                Text("TimeTracker · 柳比歇夫时间统计法")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - 辅助视图
    private func statItem(value: String, label: String, color: Color = .primary) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func qualityColor(_ score: Double) -> Color {
        let level = QualityScoreResult.ScoreLevel.from(score: score)
        switch level {
        case .excellent: return .green
        case .good: return .blue
        case .average: return .orange
        case .poor: return .red
        }
    }

    // MARK: - 渲染分享
    @MainActor
    private func renderAndShare() {
        let renderer = ImageRenderer(content:
            cardContent
                .padding(24)
                .background(Color(.systemBackground))
                .frame(width: 400)
                .environment(\.colorScheme, .light)
        )
        renderer.scale = 3.0 // Retina

        if let uiImage = renderer.uiImage {
            renderedImage = uiImage
            showShareSheet = true
        }
    }
}

// MARK: - QualityScoreResult.ScoreBreakdown 辅助
extension QualityScoreResult.ScoreBreakdown {
    var shortName: String {
        if ruleName.contains("输出") { return "输出" }
        if ruleName.contains("空白") || ruleName.contains("记录") { return "记录" }
        if ruleName.contains("消耗") { return "消耗" }
        if ruleName.contains("深度") { return "深度" }
        if ruleName.contains("连续") { return "连续" }
        if ruleName.contains("稳定") { return "稳定" }
        return String(ruleName.prefix(2))
    }
}

// MARK: - UIKit ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
