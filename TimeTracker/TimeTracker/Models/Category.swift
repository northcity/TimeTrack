//
//  Category.swift
//  TimeTracker
//
//  柳比歇夫时间统计法 - 时间分类
//

import Foundation
import SwiftUI

/// 时间分类：输入 / 输出 / 消耗 / 维持
enum TimeCategory: String, Codable, CaseIterable, Identifiable {
    case input        // 输入：学习 / 阅读
    case output       // 输出：写作 / 创作
    case consumption  // 消耗：娱乐 / 社交媒体
    case maintenance  // 维持：生活 / 杂务

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .input:       return "输入"
        case .output:      return "输出"
        case .consumption: return "消耗"
        case .maintenance: return "维持"
        }
    }

    var subtitle: String {
        switch self {
        case .input:       return "学习 / 阅读"
        case .output:      return "写作 / 创作"
        case .consumption: return "娱乐 / 消耗"
        case .maintenance: return "生活 / 杂务"
        }
    }

    var icon: String {
        switch self {
        case .input:       return "book.fill"
        case .output:      return "pencil.and.outline"
        case .consumption: return "sparkles.tv"
        case .maintenance: return "house.fill"
        }
    }

    var color: Color {
        switch self {
        case .input:       return .blue
        case .output:      return .green
        case .consumption: return .orange
        case .maintenance: return .purple
        }
    }

    /// 输出相关分类（用于计算输出占比评分）
    var isProductive: Bool {
        switch self {
        case .input, .output: return true
        case .consumption, .maintenance: return false
        }
    }
}

/// 记录来源
enum EntrySource: String, Codable, CaseIterable {
    case manual     // 手动记录
    case quick      // 快捷按钮
    case appIntent  // App Intents / Siri
    case backfill   // 补记录

    var displayName: String {
        switch self {
        case .manual:    return "手动"
        case .quick:     return "快捷"
        case .appIntent: return "Siri"
        case .backfill:  return "补记录"
        }
    }
}
