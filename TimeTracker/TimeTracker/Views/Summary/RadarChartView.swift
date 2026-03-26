//
//  RadarChartView.swift
//  TimeTracker
//
//  时间雷达图（F-18）
//  4 轴：输入 / 输出 / 消耗 / 维持
//  理想形态 vs 实际形态对比
//

import SwiftUI

struct RadarChartView: View {
    let data: [TimeCategory: Double]  // 各分类占比 0~1
    let idealData: [TimeCategory: Double]  // 理想占比

    /// 分类顺序（按雷达图轴排列）
    private let categories: [TimeCategory] = [.output, .input, .maintenance, .consumption]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时间雷达图")
                .font(.headline)

            ZStack {
                // 网格背景
                radarGrid

                // 理想形态
                radarPolygon(values: categories.map { idealData[$0] ?? 0 }, maxValue: 0.5)
                    .fill(Color.blue.opacity(0.08))
                    .overlay(
                        radarPolygon(values: categories.map { idealData[$0] ?? 0 }, maxValue: 0.5)
                            .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    )

                // 实际形态
                radarPolygon(values: categories.map { data[$0] ?? 0 }, maxValue: 0.5)
                    .fill(Color.green.opacity(0.15))
                    .overlay(
                        radarPolygon(values: categories.map { data[$0] ?? 0 }, maxValue: 0.5)
                            .stroke(Color.green, lineWidth: 2)
                    )

                // 数据点
                ForEach(Array(categories.enumerated()), id: \.offset) { index, cat in
                    let value = data[cat] ?? 0
                    let point = radarPoint(index: index, value: value, maxValue: 0.5, radius: 80)
                    Circle()
                        .fill(cat.color)
                        .frame(width: 8, height: 8)
                        .offset(x: point.x, y: point.y)
                }

                // 轴标签
                ForEach(Array(categories.enumerated()), id: \.offset) { index, cat in
                    let labelPoint = radarPoint(index: index, value: 0.58, maxValue: 0.5, radius: 80)
                    VStack(spacing: 2) {
                        Image(systemName: cat.icon)
                            .font(.caption2)
                            .foregroundStyle(cat.color)
                        Text(cat.displayName)
                            .font(.caption2.bold())
                            .foregroundStyle(cat.color)
                        Text("\(Int((data[cat] ?? 0) * 100))%")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .offset(x: labelPoint.x, y: labelPoint.y)
                }
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)

            // 图例
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.green)
                        .frame(width: 16, height: 3)
                    Text("实际")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                        .frame(width: 16, height: 3)
                    Text("理想")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 网格背景
    private var radarGrid: some View {
        ZStack {
            // 同心多边形
            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { level in
                radarPolygon(
                    values: Array(repeating: 0.5 * level, count: categories.count),
                    maxValue: 0.5
                )
                .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
            }

            // 轴线
            ForEach(0..<categories.count, id: \.self) { index in
                let point = radarPoint(index: index, value: 0.5, maxValue: 0.5, radius: 80)
                Path { path in
                    path.move(to: .zero)
                    path.addLine(to: CGPoint(x: point.x, y: point.y))
                }
                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
            }
        }
    }

    // MARK: - 雷达多边形 Shape
    private func radarPolygon(values: [Double], maxValue: Double) -> RadarShape {
        RadarShape(values: values, maxValue: maxValue, radius: 80)
    }

    // MARK: - 计算雷达图上的点
    private func radarPoint(index: Int, value: Double, maxValue: Double, radius: CGFloat) -> CGPoint {
        let angle = Double(index) / Double(categories.count) * 2 * Double.pi - Double.pi / 2
        let normalizedValue = min(value / maxValue, 1.0)
        let r = Double(radius) * normalizedValue
        
        return CGPoint(
            x: CGFloat(r * cos(angle)),
            y: CGFloat(r * sin(angle))
        )
    }
}

// MARK: - 雷达图 Shape
struct RadarShape: Shape {
    let values: [Double]
    let maxValue: Double
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()

        guard values.count >= 3 else { return path }

        for (index, value) in values.enumerated() {
            let angle = CGFloat(index) / CGFloat(values.count) * 2 * .pi - .pi / 2
            let normalizedValue = min(CGFloat(value / maxValue), 1.0)
            let r = radius * normalizedValue
            let point = CGPoint(
                x: center.x + r * cos(angle),
                y: center.y + r * sin(angle)
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - 理想时间分配参考
extension RadarChartView {
    /// 柳比歇夫推荐的理想时间结构
    static let idealDistribution: [TimeCategory: Double] = [
        .output: 0.225,      // 15~30% → 中值 22.5%
        .input: 0.25,        // 20~30% → 中值 25%
        .maintenance: 0.35,  // 30~40% → 中值 35%
        .consumption: 0.175  // < 20% → 取 17.5%
    ]
}
