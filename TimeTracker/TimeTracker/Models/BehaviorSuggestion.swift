//
//  BehaviorSuggestion.swift
//  TimeTracker
//
//  AI 行为建议引擎（F-33）
//  基于用户时间数据的规则引擎，生成个性化行为改善建议
//

import Foundation
import SwiftUI

// MARK: - 建议模型

/// 行为建议
struct BehaviorSuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let title: String
    let detail: String
    let priority: SuggestionPriority
    let icon: String
    let color: Color
    let actionHint: String?  // 可执行的行动提示

    /// 建议类型
    enum SuggestionType: String {
        case structure     // 时间结构
        case habit         // 习惯养成
        case trend         // 趋势预警
        case timeSlot      // 时段优化
        case deepWork      // 深度工作
        case balance       // 生活平衡
        case celebration   // 正面鼓励
    }

    /// 建议优先级
    enum SuggestionPriority: Int, Comparable {
        case critical = 3   // 紧急（红色警告）
        case important = 2  // 重要
        case normal = 1     // 一般
        case positive = 0   // 正面鼓励

        static func < (lhs: SuggestionPriority, rhs: SuggestionPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

// MARK: - 行为分析上下文

/// 供建议引擎使用的分析上下文
struct BehaviorAnalysisContext {
    let todaySummary: DailySummary
    let weeklySummary: WeeklySummary
    let previousWeeklySummary: WeeklySummary?
    let currentStreak: Int
    let recentEntries: [TimeEntry]  // 最近 7 天的所有记录

    /// 本周各分类占比
    var weekCategoryRatios: [TimeCategory: Double] {
        let total = weeklySummary.totalTrackedTime
        guard total > 0 else { return [:] }
        var ratios: [TimeCategory: Double] = [:]
        for cat in TimeCategory.allCases {
            ratios[cat] = (weeklySummary.totalTimePerCategory[cat] ?? 0) / total
        }
        return ratios
    }

    /// 上周各分类占比
    var previousWeekCategoryRatios: [TimeCategory: Double]? {
        guard let prev = previousWeeklySummary, prev.totalTrackedTime > 0 else { return nil }
        var ratios: [TimeCategory: Double] = [:]
        for cat in TimeCategory.allCases {
            ratios[cat] = (prev.totalTimePerCategory[cat] ?? 0) / prev.totalTrackedTime
        }
        return ratios
    }

    /// 今日各时段分类分布（以 2 小时为一个时段）
    var todayTimeSlotDistribution: [Int: [TimeCategory: TimeInterval]] {
        var distribution: [Int: [TimeCategory: TimeInterval]] = [:]
        let calendar = Calendar.current
        for entry in todaySummary.entries {
            guard !entry.isRunning, let endTime = entry.endTime else { continue }
            let startHour = calendar.component(.hour, from: entry.startTime)
            let slot = startHour / 2 * 2  // 0, 2, 4, 6, ..., 22
            distribution[slot, default: [:]][entry.category, default: 0] += endTime.timeIntervalSince(entry.startTime)
        }
        return distribution
    }

    /// 最近 7 天各时段的深度工作分布
    var deepWorkTimeSlotPattern: [Int: Int] {
        var pattern: [Int: Int] = [:]
        let calendar = Calendar.current
        for entry in recentEntries {
            if entry.isDeepWork {
                let startHour = calendar.component(.hour, from: entry.startTime)
                let slot = startHour / 2 * 2
                pattern[slot, default: 0] += 1
            }
        }
        return pattern
    }

    /// 最近 7 天消耗类高峰时段
    var consumptionPeakSlots: [Int] {
        var slotTime: [Int: TimeInterval] = [:]
        let calendar = Calendar.current
        for entry in recentEntries {
            guard entry.category == .consumption, !entry.isRunning else { continue }
            let startHour = calendar.component(.hour, from: entry.startTime)
            let slot = startHour / 2 * 2
            slotTime[slot, default: 0] += entry.duration
        }
        // 返回消耗时间最多的前 2 个时段
        return slotTime.sorted { $0.value > $1.value }.prefix(2).map(\.key)
    }

    /// 周环比变化幅度
    func weeklyChange(for category: TimeCategory) -> Double? {
        guard let prevRatios = previousWeekCategoryRatios,
              let currentRatio = weekCategoryRatios[category],
              let prevRatio = prevRatios[category] else { return nil }
        return currentRatio - prevRatio
    }
}

// MARK: - 行为建议引擎

struct BehaviorSuggestionEngine {
    let config: ScoringConfig

    init(config: ScoringConfig = .default) {
        self.config = config
    }

    /// 生成行为建议（主入口）
    func generateSuggestions(context: BehaviorAnalysisContext) -> [BehaviorSuggestion] {
        var suggestions: [BehaviorSuggestion] = []

        // 1. 时间结构分析
        suggestions.append(contentsOf: analyzeStructure(context: context))

        // 2. 深度工作分析
        suggestions.append(contentsOf: analyzeDeepWork(context: context))

        // 3. 趋势分析
        suggestions.append(contentsOf: analyzeTrends(context: context))

        // 4. 时段优化
        suggestions.append(contentsOf: analyzeTimeSlots(context: context))

        // 5. 习惯分析
        suggestions.append(contentsOf: analyzeHabits(context: context))

        // 6. 正面鼓励
        suggestions.append(contentsOf: generateCelebrations(context: context))

        // 按优先级排序，最多返回 5 条
        return suggestions
            .sorted { $0.priority > $1.priority }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - 时间结构分析

    private func analyzeStructure(context: BehaviorAnalysisContext) -> [BehaviorSuggestion] {
        var suggestions: [BehaviorSuggestion] = []
        let ratios = context.weekCategoryRatios

        // 消耗占比过高
        let consumptionRatio = ratios[.consumption] ?? 0
        if consumptionRatio > 0.35 {
            suggestions.append(BehaviorSuggestion(
                type: .structure,
                title: "消耗时间偏高",
                detail: "本周消耗类占比 \(Int(consumptionRatio * 100))%，超过建议值 25%。试试用「替代法」：想刷手机时，改为读 10 分钟书。",
                priority: .critical,
                icon: "exclamationmark.triangle.fill",
                color: .red,
                actionHint: "设一个「无手机时段」，从 30 分钟开始"
            ))
        } else if consumptionRatio > 0.25 {
            suggestions.append(BehaviorSuggestion(
                type: .structure,
                title: "消耗时间需关注",
                detail: "本周消耗类占比 \(Int(consumptionRatio * 100))%，已接近警戒线。可以给自己设一个「有意识消耗」的规则。",
                priority: .important,
                icon: "exclamationmark.circle.fill",
                color: .orange,
                actionHint: "每次消耗前先问自己：这是主动选择还是习惯性行为？"
            ))
        }

        // 输出占比不足
        let outputRatio = ratios[.output] ?? 0
        if outputRatio < 0.10 {
            suggestions.append(BehaviorSuggestion(
                type: .structure,
                title: "输出时间过少",
                detail: "本周输出类仅占 \(Int(outputRatio * 100))%，低于建议值 15%。输出是价值沉淀的关键环节。",
                priority: .critical,
                icon: "pencil.and.outline",
                color: .green,
                actionHint: "每天安排一个固定 1 小时的「创作时间块」"
            ))
        } else if outputRatio < 0.15 {
            suggestions.append(BehaviorSuggestion(
                type: .structure,
                title: "输出占比可提升",
                detail: "本周输出类占比 \(Int(outputRatio * 100))%，接近但未达 15% 目标。再多一点点就达标了！",
                priority: .normal,
                icon: "pencil.and.outline",
                color: .green,
                actionHint: "试试「输入-输出转化」：读完一篇文章后写 3 句笔记"
            ))
        }

        // 输入不足
        let inputRatio = ratios[.input] ?? 0
        if inputRatio < 0.10 {
            suggestions.append(BehaviorSuggestion(
                type: .structure,
                title: "输入时间不足",
                detail: "本周输入类仅占 \(Int(inputRatio * 100))%，知识储备需要持续投入。",
                priority: .important,
                icon: "book.fill",
                color: .blue,
                actionHint: "利用碎片时间：通勤听播客、午休读 15 分钟书"
            ))
        }

        // 维持时间过高（可能记录不精确）
        let maintenanceRatio = ratios[.maintenance] ?? 0
        if maintenanceRatio > 0.60 {
            suggestions.append(BehaviorSuggestion(
                type: .structure,
                title: "维持类占比偏高",
                detail: "本周维持类占比 \(Int(maintenanceRatio * 100))%。检查是否有时间可以归类为「输入」或「输出」？",
                priority: .normal,
                icon: "house.fill",
                color: .purple,
                actionHint: "做家务时听有声书，维持+输入双重计时"
            ))
        }

        return suggestions
    }

    // MARK: - 深度工作分析

    private func analyzeDeepWork(context: BehaviorAnalysisContext) -> [BehaviorSuggestion] {
        var suggestions: [BehaviorSuggestion] = []
        let weekDeepWorkCount = context.weeklySummary.totalDeepWorkCount

        if weekDeepWorkCount == 0 {
            suggestions.append(BehaviorSuggestion(
                type: .deepWork,
                title: "本周尚无深度工作",
                detail: "深度工作是高质量输出的基石。连续专注 90 分钟以上才能进入心流状态。",
                priority: .important,
                icon: "brain.head.profile.fill",
                color: .indigo,
                actionHint: "明天上午选一个 90 分钟时段，关闭通知，专注一件事"
            ))
        } else if weekDeepWorkCount < 3 {
            suggestions.append(BehaviorSuggestion(
                type: .deepWork,
                title: "深度工作次数偏少",
                detail: "本周深度工作 \(weekDeepWorkCount) 次，建议目标为每周 5 次以上。",
                priority: .normal,
                icon: "brain.head.profile.fill",
                color: .indigo,
                actionHint: "在日历中预留「深度工作时段」，像对待会议一样不可更改"
            ))
        }

        // 深度工作最佳时段建议
        let deepWorkPattern = context.deepWorkTimeSlotPattern
        if let bestSlot = deepWorkPattern.max(by: { $0.value < $1.value }),
           bestSlot.value >= 2 {
            let slotName = timeSlotName(bestSlot.key)
            suggestions.append(BehaviorSuggestion(
                type: .deepWork,
                title: "深度工作黄金时段",
                detail: "你的深度工作集中在\(slotName)，这是你的高效时段。建议固定为每日深度工作时间。",
                priority: .positive,
                icon: "star.fill",
                color: .yellow,
                actionHint: "将\(slotName)设为固定深度工作时段"
            ))
        }

        return suggestions
    }

    // MARK: - 趋势分析

    private func analyzeTrends(context: BehaviorAnalysisContext) -> [BehaviorSuggestion] {
        var suggestions: [BehaviorSuggestion] = []

        // 消耗趋势上升
        if let consumptionChange = context.weeklyChange(for: .consumption),
           consumptionChange > 0.10 {
            suggestions.append(BehaviorSuggestion(
                type: .trend,
                title: "消耗趋势上升",
                detail: "消耗占比较上周增加 \(Int(consumptionChange * 100))%，注意控制趋势。",
                priority: .important,
                icon: "chart.line.uptrend.xyaxis",
                color: .red,
                actionHint: "回顾本周消耗记录，找出最大的「时间黑洞」"
            ))
        }

        // 输出趋势下降
        if let outputChange = context.weeklyChange(for: .output),
           outputChange < -0.10 {
            suggestions.append(BehaviorSuggestion(
                type: .trend,
                title: "输出趋势下降",
                detail: "输出占比较上周减少 \(Int(abs(outputChange) * 100))%，创作势头在放缓。",
                priority: .important,
                icon: "chart.line.downtrend.xyaxis",
                color: .orange,
                actionHint: "重新审视本周计划，确保有足够的创作时间"
            ))
        }

        // 输出趋势上升（正面）
        if let outputChange = context.weeklyChange(for: .output),
           outputChange > 0.05 {
            suggestions.append(BehaviorSuggestion(
                type: .trend,
                title: "输出势头良好",
                detail: "输出占比较上周增加 \(Int(outputChange * 100))%，创作节奏在提升！",
                priority: .positive,
                icon: "chart.line.uptrend.xyaxis",
                color: .green,
                actionHint: nil
            ))
        }

        return suggestions
    }

    // MARK: - 时段优化

    private func analyzeTimeSlots(context: BehaviorAnalysisContext) -> [BehaviorSuggestion] {
        var suggestions: [BehaviorSuggestion] = []

        // 消耗高峰时段提醒
        let peakSlots = context.consumptionPeakSlots
        if let topSlot = peakSlots.first {
            let slotName = timeSlotName(topSlot)
            suggestions.append(BehaviorSuggestion(
                type: .timeSlot,
                title: "消耗高峰：\(slotName)",
                detail: "最近 7 天，\(slotName)是你消耗类活动最集中的时段。这个时段的行为模式值得关注。",
                priority: .normal,
                icon: "clock.badge.exclamationmark",
                color: .orange,
                actionHint: "在\(slotName)之前设一个提醒：「现在想做什么？」"
            ))
        }

        // 晚间消耗提醒（22:00 后）
        let todayDistribution = context.todayTimeSlotDistribution
        let lateConsumption = (todayDistribution[22]?[.consumption] ?? 0) + (todayDistribution[20]?[.consumption] ?? 0)
        if lateConsumption > 1800 { // 晚间消耗超过 30 分钟
            suggestions.append(BehaviorSuggestion(
                type: .timeSlot,
                title: "注意晚间消耗",
                detail: "今晚已有 \(Int(lateConsumption / 60)) 分钟消耗活动。晚间消耗容易影响睡眠质量。",
                priority: .important,
                icon: "moon.fill",
                color: .indigo,
                actionHint: "设一个「数字宵禁」时间，22:00 后不碰手机"
            ))
        }

        return suggestions
    }

    // MARK: - 习惯分析

    private func analyzeHabits(context: BehaviorAnalysisContext) -> [BehaviorSuggestion] {
        var suggestions: [BehaviorSuggestion] = []

        // 连续记录鼓励
        if context.currentStreak >= 30 {
            suggestions.append(BehaviorSuggestion(
                type: .habit,
                title: "记录习惯已建立！",
                detail: "连续记录 \(context.currentStreak) 天，你已经形成了稳定的时间记录习惯。这本身就是一种自律。",
                priority: .positive,
                icon: "flame.fill",
                color: .orange,
                actionHint: nil
            ))
        } else if context.currentStreak >= 7 {
            suggestions.append(BehaviorSuggestion(
                type: .habit,
                title: "记录习惯正在养成",
                detail: "连续记录 \(context.currentStreak) 天。研究表明 21 天可以养成一个习惯，继续坚持！",
                priority: .positive,
                icon: "flame.fill",
                color: .orange,
                actionHint: nil
            ))
        } else if context.currentStreak == 0 {
            suggestions.append(BehaviorSuggestion(
                type: .habit,
                title: "重新开始记录",
                detail: "记录中断了，没关系！最重要的是现在就开始。每一天都是新的起点。",
                priority: .important,
                icon: "arrow.counterclockwise",
                color: .blue,
                actionHint: "现在就开始一次计时，哪怕只有 15 分钟"
            ))
        }

        // 空白时间多
        let todayEmpty = context.todaySummary.emptyTime
        if todayEmpty > 8 * 3600 && !DateHelper.isToday(context.todaySummary.date) {
            // 只对非今天的日期提醒（今天可能还没过完）
        } else if DateHelper.isToday(context.todaySummary.date) {
            let calendar = Calendar.current
            let currentHour = calendar.component(.hour, from: Date())
            let trackedHours = context.todaySummary.totalTrackedTime / 3600
            if currentHour >= 14 && trackedHours < 2 {
                suggestions.append(BehaviorSuggestion(
                    type: .habit,
                    title: "今日记录较少",
                    detail: "已经下午了，今日仅记录 \(context.todaySummary.formattedTotalTime)，别忘了补记录。",
                    priority: .normal,
                    icon: "clock.badge.questionmark",
                    color: .secondary,
                    actionHint: "回顾今天上午做了什么，补上记录"
                ))
            }
        }

        return suggestions
    }

    // MARK: - 正面鼓励

    private func generateCelebrations(context: BehaviorAnalysisContext) -> [BehaviorSuggestion] {
        var suggestions: [BehaviorSuggestion] = []
        let score = context.todaySummary.qualityScore

        if score.totalScore >= 80 {
            suggestions.append(BehaviorSuggestion(
                type: .celebration,
                title: "今日状态优秀！",
                detail: "质量评分 \(Int(score.totalScore)) 分，\(score.level.emoji) 时间分配非常合理，继续保持这个节奏。",
                priority: .positive,
                icon: "star.circle.fill",
                color: .yellow,
                actionHint: nil
            ))
        }

        let weekScore = context.weeklySummary.qualityScore
        if weekScore.totalScore >= 80 {
            suggestions.append(BehaviorSuggestion(
                type: .celebration,
                title: "本周表现出色！",
                detail: "周评分 \(Int(weekScore.totalScore)) 分，你正在成为时间管理的高手。",
                priority: .positive,
                icon: "trophy.fill",
                color: .yellow,
                actionHint: nil
            ))
        }

        return suggestions
    }

    // MARK: - 辅助

    /// 时段名称
    private func timeSlotName(_ slot: Int) -> String {
        switch slot {
        case 0...4:   return "凌晨（\(slot):00-\(slot+2):00）"
        case 6:       return "早晨（6:00-8:00）"
        case 8:       return "上午（8:00-10:00）"
        case 10:      return "上午（10:00-12:00）"
        case 12:      return "午间（12:00-14:00）"
        case 14:      return "下午（14:00-16:00）"
        case 16:      return "下午（16:00-18:00）"
        case 18:      return "傍晚（18:00-20:00）"
        case 20:      return "晚间（20:00-22:00）"
        case 22:      return "深夜（22:00-24:00）"
        default:      return "\(slot):00-\(slot+2):00"
        }
    }
}
