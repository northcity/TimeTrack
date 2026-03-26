//
//  QualityScore.swift
//  TimeTracker
//
//  时间质量评分系统（F-26/27/28）
//  基于柳比歇夫方法论的可配置规则引擎
//

import Foundation

// MARK: - 评分引擎协议
protocol ScoringEngine {
    func score(summary: DailySummary) -> QualityScoreResult
    func score(summary: WeeklySummary) -> QualityScoreResult
}

// MARK: - 评分结果
struct QualityScoreResult: Identifiable {
    let id = UUID()
    let totalScore: Double          // 0 ~ 100
    let breakdowns: [ScoreBreakdown] // 各项得分明细
    let level: ScoreLevel
    let suggestion: String          // 一句话建议

    struct ScoreBreakdown: Identifiable {
        let id = UUID()
        let ruleName: String
        let earned: Double
        let maxPoints: Double
        let passed: Bool
        let description: String
    }

    enum ScoreLevel: String {
        case excellent  // >= 80
        case good       // 60~79
        case average    // 40~59
        case poor       // < 40

        var displayName: String {
            switch self {
            case .excellent: return "优秀"
            case .good:      return "不错"
            case .average:   return "一般"
            case .poor:      return "需改进"
            }
        }

        var emoji: String {
            switch self {
            case .excellent: return "🌟"
            case .good:      return "👍"
            case .average:   return "⚡"
            case .poor:      return "⚠️"
            }
        }

        static func from(score: Double) -> ScoreLevel {
            switch score {
            case 80...100: return .excellent
            case 60..<80:  return .good
            case 40..<60:  return .average
            default:       return .poor
            }
        }
    }
}

// MARK: - 评分规则配置
struct ScoringConfig {
    /// 输出占比达标阈值（默认 15%）
    var outputThreshold: Double = 0.15
    /// 输出占比满分分值
    var outputMaxPoints: Double = 30

    /// 输入占比达标阈值（默认 20%）
    var inputThreshold: Double = 0.20
    /// 输入占比满分分值
    var inputMaxPoints: Double = 20

    /// 消耗占比警戒线（默认 25%）
    var consumptionThreshold: Double = 0.25
    /// 消耗占比满分分值
    var consumptionMaxPoints: Double = 20

    /// 深度工作次数达标线（默认 2 次）
    var deepWorkCountThreshold: Int = 2
    /// 深度工作满分分值
    var deepWorkMaxPoints: Double = 20

    /// 连续记录天数 bonus 分值
    var streakMaxPoints: Double = 10

    /// 消耗类每日预算上限（秒，默认 3 小时）
    var dailyConsumptionBudget: TimeInterval = 3 * 3600

    /// 消耗类每周预算上限（秒，默认 15 小时）
    var weeklyConsumptionBudget: TimeInterval = 15 * 3600

    static let `default` = ScoringConfig()
}

// MARK: - 基于规则的评分引擎
struct RuleBasedScoringEngine: ScoringEngine {
    let config: ScoringConfig

    init(config: ScoringConfig = .default) {
        self.config = config
    }

    // MARK: - 日评分
    func score(summary: DailySummary) -> QualityScoreResult {
        var breakdowns: [QualityScoreResult.ScoreBreakdown] = []
        var totalScore: Double = 0

        // 规则 1: 输出占比
        let outputRatio = summary.pureOutputRatio
        let outputPassed = outputRatio >= config.outputThreshold
        let outputScore = outputPassed ? config.outputMaxPoints :
            (outputRatio / config.outputThreshold) * config.outputMaxPoints
        breakdowns.append(.init(
            ruleName: "输出占比",
            earned: outputScore,
            maxPoints: config.outputMaxPoints,
            passed: outputPassed,
            description: outputPassed
                ? "输出占比 \(Int(outputRatio * 100))%，达标 ✓"
                : "输出占比 \(Int(outputRatio * 100))%，低于 \(Int(config.outputThreshold * 100))%"
        ))
        totalScore += outputScore

        // 规则 2: 输入占比
        let inputRatio = summary.totalTrackedTime > 0
            ? (summary.totalTimePerCategory[.input] ?? 0) / summary.totalTrackedTime
            : 0
        let inputPassed = inputRatio >= config.inputThreshold
        let inputScore = inputPassed ? config.inputMaxPoints :
            (inputRatio / config.inputThreshold) * config.inputMaxPoints
        breakdowns.append(.init(
            ruleName: "输入占比",
            earned: inputScore,
            maxPoints: config.inputMaxPoints,
            passed: inputPassed,
            description: inputPassed
                ? "输入占比 \(Int(inputRatio * 100))%，达标 ✓"
                : "输入占比 \(Int(inputRatio * 100))%，低于 \(Int(config.inputThreshold * 100))%"
        ))
        totalScore += inputScore

        // 规则 3: 消耗占比
        let consumptionRatio = summary.totalTrackedTime > 0
            ? (summary.totalTimePerCategory[.consumption] ?? 0) / summary.totalTrackedTime
            : 0
        let consumptionPassed = consumptionRatio <= config.consumptionThreshold
        let consumptionScore = consumptionPassed ? config.consumptionMaxPoints :
            max(0, config.consumptionMaxPoints * (1 - (consumptionRatio - config.consumptionThreshold) / config.consumptionThreshold))
        breakdowns.append(.init(
            ruleName: "消耗控制",
            earned: consumptionScore,
            maxPoints: config.consumptionMaxPoints,
            passed: consumptionPassed,
            description: consumptionPassed
                ? "消耗占比 \(Int(consumptionRatio * 100))%，控制良好 ✓"
                : "消耗占比 \(Int(consumptionRatio * 100))%，超过 \(Int(config.consumptionThreshold * 100))%"
        ))
        totalScore += consumptionScore

        // 规则 4: 深度工作
        let deepWorkCount = summary.deepWorkCount
        let deepWorkPassed = deepWorkCount >= config.deepWorkCountThreshold
        let deepWorkScore = deepWorkPassed ? config.deepWorkMaxPoints :
            Double(deepWorkCount) / Double(config.deepWorkCountThreshold) * config.deepWorkMaxPoints
        breakdowns.append(.init(
            ruleName: "深度工作",
            earned: deepWorkScore,
            maxPoints: config.deepWorkMaxPoints,
            passed: deepWorkPassed,
            description: deepWorkPassed
                ? "深度工作 \(deepWorkCount) 次，达标 ✓"
                : "深度工作 \(deepWorkCount) 次，未达 \(config.deepWorkCountThreshold) 次"
        ))
        totalScore += deepWorkScore

        // 规则 5: 连续记录（日评分中给基础分）
        let hasRecords = summary.totalTrackedTime > 600 // 至少 10 分钟算有记录
        let streakScore = hasRecords ? config.streakMaxPoints : 0
        breakdowns.append(.init(
            ruleName: "记录完整",
            earned: streakScore,
            maxPoints: config.streakMaxPoints,
            passed: hasRecords,
            description: hasRecords
                ? "今日有记录，保持习惯 ✓"
                : "今日暂无有效记录"
        ))
        totalScore += streakScore

        totalScore = min(100, max(0, totalScore))
        let level = QualityScoreResult.ScoreLevel.from(score: totalScore)

        return QualityScoreResult(
            totalScore: totalScore,
            breakdowns: breakdowns,
            level: level,
            suggestion: generateSuggestion(level: level, breakdowns: breakdowns)
        )
    }

    // MARK: - 周评分
    func score(summary: WeeklySummary) -> QualityScoreResult {
        // 计算周维度的各项指标
        var breakdowns: [QualityScoreResult.ScoreBreakdown] = []
        var totalScore: Double = 0

        let totalTime = summary.totalTrackedTime
        guard totalTime > 0 else {
            return QualityScoreResult(
                totalScore: 0,
                breakdowns: [],
                level: .poor,
                suggestion: "本周暂无记录，开始记录你的时间吧"
            )
        }

        // 规则 1: 输出占比
        let outputRatio = (summary.totalTimePerCategory[.output] ?? 0) / totalTime
        let outputPassed = outputRatio >= config.outputThreshold
        let outputScore = outputPassed ? config.outputMaxPoints :
            (outputRatio / config.outputThreshold) * config.outputMaxPoints
        breakdowns.append(.init(
            ruleName: "输出占比",
            earned: outputScore,
            maxPoints: config.outputMaxPoints,
            passed: outputPassed,
            description: outputPassed
                ? "周输出占比 \(Int(outputRatio * 100))%，达标 ✓"
                : "周输出占比 \(Int(outputRatio * 100))%，低于 \(Int(config.outputThreshold * 100))%"
        ))
        totalScore += outputScore

        // 规则 2: 输入占比
        let inputRatio = (summary.totalTimePerCategory[.input] ?? 0) / totalTime
        let inputPassed = inputRatio >= config.inputThreshold
        let inputScore = inputPassed ? config.inputMaxPoints :
            (inputRatio / config.inputThreshold) * config.inputMaxPoints
        breakdowns.append(.init(
            ruleName: "输入占比",
            earned: inputScore,
            maxPoints: config.inputMaxPoints,
            passed: inputPassed,
            description: inputPassed
                ? "周输入占比 \(Int(inputRatio * 100))%，达标 ✓"
                : "周输入占比 \(Int(inputRatio * 100))%，低于 \(Int(config.inputThreshold * 100))%"
        ))
        totalScore += inputScore

        // 规则 3: 消耗控制
        let consumptionRatio = (summary.totalTimePerCategory[.consumption] ?? 0) / totalTime
        let consumptionPassed = consumptionRatio <= config.consumptionThreshold
        let consumptionScore = consumptionPassed ? config.consumptionMaxPoints :
            max(0, config.consumptionMaxPoints * (1 - (consumptionRatio - config.consumptionThreshold) / config.consumptionThreshold))
        breakdowns.append(.init(
            ruleName: "消耗控制",
            earned: consumptionScore,
            maxPoints: config.consumptionMaxPoints,
            passed: consumptionPassed,
            description: consumptionPassed
                ? "周消耗占比 \(Int(consumptionRatio * 100))%，控制良好 ✓"
                : "周消耗占比 \(Int(consumptionRatio * 100))%，超过 \(Int(config.consumptionThreshold * 100))%"
        ))
        totalScore += consumptionScore

        // 规则 4: 深度工作（周累计）
        let weekDeepWorkCount = summary.dailySummaries.reduce(0) { $0 + $1.deepWorkCount }
        let weekDeepWorkThreshold = config.deepWorkCountThreshold * 5 // 工作日标准
        let deepWorkPassed = weekDeepWorkCount >= weekDeepWorkThreshold
        let deepWorkScore = deepWorkPassed ? config.deepWorkMaxPoints :
            min(config.deepWorkMaxPoints, Double(weekDeepWorkCount) / Double(weekDeepWorkThreshold) * config.deepWorkMaxPoints)
        breakdowns.append(.init(
            ruleName: "深度工作",
            earned: deepWorkScore,
            maxPoints: config.deepWorkMaxPoints,
            passed: deepWorkPassed,
            description: deepWorkPassed
                ? "周深度工作 \(weekDeepWorkCount) 次，达标 ✓"
                : "周深度工作 \(weekDeepWorkCount) 次，目标 \(weekDeepWorkThreshold) 次"
        ))
        totalScore += deepWorkScore

        // 规则 5: 记录天数
        let recordDays = summary.dailySummaries.filter { $0.totalTrackedTime > 600 }.count
        let streakPassed = recordDays >= 5
        let streakScore = Double(recordDays) / 7.0 * config.streakMaxPoints
        breakdowns.append(.init(
            ruleName: "记录天数",
            earned: streakScore,
            maxPoints: config.streakMaxPoints,
            passed: streakPassed,
            description: "本周记录 \(recordDays) 天\(streakPassed ? "，保持良好 ✓" : "")"
        ))
        totalScore += streakScore

        totalScore = min(100, max(0, totalScore))
        let level = QualityScoreResult.ScoreLevel.from(score: totalScore)

        return QualityScoreResult(
            totalScore: totalScore,
            breakdowns: breakdowns,
            level: level,
            suggestion: generateSuggestion(level: level, breakdowns: breakdowns)
        )
    }

    // MARK: - 建议生成
    private func generateSuggestion(level: QualityScoreResult.ScoreLevel, breakdowns: [QualityScoreResult.ScoreBreakdown]) -> String {
        switch level {
        case .excellent:
            return "优秀，保持节奏！你的时间结构非常合理"
        case .good:
            let weakest = breakdowns.min(by: { ($0.earned / $0.maxPoints) < ($1.earned / $1.maxPoints) })
            return "不错，\(weakest?.ruleName ?? "")还有提升空间"
        case .average:
            let failed = breakdowns.filter { !$0.passed }
            let names = failed.prefix(2).map(\.ruleName).joined(separator: "和")
            return "需要在\(names)方面改进"
        case .poor:
            return "时间结构需要调整，建议减少消耗、增加输出"
        }
    }
}
