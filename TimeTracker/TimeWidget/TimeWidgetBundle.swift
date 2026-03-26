//
//  TimeWidgetBundle.swift
//  TimeWidget
//
//  TimeTracker Widget Bundle
//

import WidgetKit
import SwiftUI

@main
struct TimeWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimeWidget()               // 主屏 Widget (Small/Medium/Large)
        LockScreenWidget()         // 锁屏 Widget (Circular/Rectangular/Inline)
        TimeWidgetControl()        // 控制中心 Widget
        TimeWidgetLiveActivity()   // 实时活动 (灵动岛 + 锁屏 Banner)
    }
}
