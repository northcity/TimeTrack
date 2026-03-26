//
//  LiveActivityAttributes.swift
//  TimeTracker
//
//  实时活动属性定义（主 App 端）
//  与 TimeWidget/TimeWidgetLiveActivity.swift 中的定义保持同步
//

import Foundation
import ActivityKit

/// 计时实时活动属性（灵动岛 + 锁屏 Banner）
struct TimeTrackerActivityAttributes: ActivityAttributes {
    /// 固定属性（计时开始时不变）
    var categoryRaw: String
    var categoryDisplayName: String
    var categoryIcon: String
    var startTime: Date

    /// 动态状态
    public struct ContentState: Codable, Hashable {
        var elapsedMinutes: Int
        var isRunning: Bool
    }
}
