# TimeTracker 项目记忆文档

**最后更新**: 2026年3月26日（Phase 4 Widget + Live Activity 完成）

## 📋 项目基本信息

**项目名称**: TimeTracker（时间追踪器）  
**开发者**: 北城  
**角色**: 产品经理 + iOS 开发  
**开发工具**: VS Code + GitHub Copilot (AI辅助开发)  
**语言偏好**: 中文  
**创建时间**: 2025年  

**项目状态**: Phase 4 开发中（F-09/F-33/F-22/F-23/F-37/F-29/F-30/F-31 已完成）  
**PRD 版本**: v1.5

---

## 🎯 产品理念

### 核心方法论：柳比歇夫时间统计法
> **TimeTracker 不是计时器，不是统计工具，是你人生时间的镜子。**

### 柳比歇夫方法论精髓
1. **结构（Structure）** — 时间分配是否均衡，产出占比是否合理
2. **趋势（Trend）** — 时间结构是否在变好 / 变差
3. **价值（Value）** — 时间是否用在有长期产出的事情上

### 核心壁垒
- 可视化时间块（日/周） → 直观认知
- 结构化分类评分（输入/输出/消耗/维持） → 可量化"产出性"
- 周复盘与趋势分析 → 纵向方向感
- 行为引导 + 补缺提示 → 持续回流

### 设计原则
- 每屏只讲一个结论
- 每个图表必须有一句人话总结
- 让用户产生情绪（焦虑 / 成就 / 反思）

---

## 🏗️ 技术架构

### 技术栈
| 项目 | 选型 |
|------|------|
| 平台 | iOS 18+ |
| 语言 | Swift 5 |
| UI 框架 | SwiftUI |
| 数据持久化 | SwiftData |
| 图表 | Swift Charts + 自定义 RadarChart |
| 系统集成 | App Intents (Siri/Shortcuts) |
| 架构模式 | MVVM + @Observable |

### Xcode 配置
- **Xcode**: 26.2
- **SWIFT_DEFAULT_ACTOR_ISOLATION**: `MainActor`（所有类型默认 @MainActor）
- **项目结构**: `PBXFileSystemSynchronizedRootGroup`（新文件自动加入项目，无需手动编辑 `.pbxproj`）

### 分层架构

| 层 | 文件 | 模式 |
|------|------|------|
| **App 入口** | `TimeTrackerApp`, `ContentView` | SwiftUI App 生命周期 + SwiftData 容器 |
| **模型层** | `TimeEntry`, `Category`, `DailySummary`, `WeeklySummary`, `MonthlySummary`, `YearlySummary`, `QualityScore`, `BehaviorSuggestion` | `@Model` 持久化 + 计算型 Summary 结构体 + 评分引擎 + 行为建议引擎 |
| **ViewModel** | `TimeTrackingViewModel` | `@Observable` 单一数据源 |
| **视图层** | 17 个视图文件，4 个分组 | Tab 导航 + Charts + 自定义布局 |
| **工具层** | `DateHelper` | 日期格式化 / 计算工具 |
| **Intents** | `TimeTrackerIntents` | Siri / Shortcuts 集成 |

### 四大时间分类

| 分类 | 含义 | 典型活动 | `isProductive` | 颜色 |
|------|------|----------|----------------|------|
| 输入（Input）| 知识吸收 | 学习 / 阅读 / 听播客 | ✅ | 蓝 |
| 输出（Output）| 知识产出 | 写作 / 编程 / 创作 | ✅ | 绿 |
| 消耗（Consumption）| 娱乐消耗 | 刷短视频 / 游戏 / 无意义社交 | ❌ | 橙/红 |
| 维持（Maintenance）| 生命维持 | 睡眠 / 饮食 / 运动 / 杂务 | ❌（中性）| 紫 |

---

## 📁 项目文件结构

```
TimeTracker/
├── TimeTrackerApp.swift          # App 入口，ModelContainer 配置
├── ContentView.swift             # 兼容性入口，重定向 MainTabView
├── Info.plist
├── TimeTracker.entitlements
├── Assets.xcassets/
├── Models/
│   ├── TimeEntry.swift           # @Model 核心数据模型
│   ├── Category.swift            # TimeCategory + EntrySource 枚举
│   ├── DailySummary.swift        # 日汇总（计算型，非持久化）
│   ├── WeeklySummary.swift       # 周汇总
│   ├── MonthlySummary.swift      # 月汇总 + 月度对比
│   ├── YearlySummary.swift       # 年汇总 + 年度对比（Phase 4 新增）
│   ├── QualityScore.swift        # 评分引擎（协议 + 规则引擎 + 配置）
│   └── BehaviorSuggestion.swift  # AI行为建议引擎（Phase 4 新增）
├── ViewModels/
│   └── TimeTrackingViewModel.swift  # 核心 ViewModel（计时/CRUD/查询/评分）
├── Views/
│   ├── MainTabView.swift         # 6 Tab 导航（计时/日历/日报/周报/月报/年报）
│   ├── Timer/
│   │   └── TimerView.swift       # 计时主屏 + 快速开始 + 今日概览
│   ├── Entry/
│   │   ├── AddEntryView.swift    # 补记录表单
│   │   ├── EntryDetailView.swift # 记录详情 + FlowLayout 标签
│   │   └── EditEntryView.swift   # 编辑记录表单（Phase 3 新增）
│   ├── Calendar/
│   │   └── CalendarBlockView.swift  # 日/周日历时间块视图
│   └── Summary/
│       ├── DailySummaryView.swift    # 日报（Charts SectorMark）
│       ├── WeeklyReviewView.swift    # 周报（Charts BarMark + SectorMark）
│       ├── MonthlyLedgerView.swift   # 月报 + 热力图
│       ├── YearlyLedgerView.swift    # 年度账本 + 年报（Phase 4 新增）
│       ├── RadarChartView.swift      # 自定义 4 轴雷达图
│       ├── QualityScoreView.swift    # 质量评分组件集
│       ├── BehaviorSuggestionView.swift # AI行为建议视图（Phase 4 新增）
│       ├── ShareCardView.swift       # 周报分享卡片（Phase 3 新增）
│       └── CSVExportView.swift       # CSV 数据导出（Phase 3 新增）
├── Helpers/
│   ├── DateHelper.swift          # 日期工具 + TimeInterval 扩展
│   └── WidgetData.swift          # Widget 共享数据模型（Phase 4 新增）
└── Intents/
    └── TimeTrackerIntents.swift  # App Intents（4 个 Intent + Siri Phrases）

TimeWidget/                           # Widget Extension Target（Phase 4 新增）
├── TimeWidgetBundle.swift        # Widget Bundle（4 个 Widget）
├── TimeWidget.swift              # 主屏 + 锁屏 Widget
├── TimeWidgetLiveActivity.swift  # 实时活动（灵动岛 + 锁屏 Banner）
├── TimeWidgetControl.swift       # 控制中心 Widget
├── WidgetData.swift              # 共享数据模型（与主 App 同步）
├── AppIntent.swift               # Widget Intents
└── Assets.xcassets/
```

**总计**: 约 6,100 行 Swift 代码，33 个文件（含 Widget Extension）

---

## 📐 关键数据模型

### TimeEntry（@Model —— 唯一持久化模型）

```swift
@Model
final class TimeEntry {
    var id: UUID
    var startTime: Date
    var endTime: Date?                // nil = 正在计时
    var categoryRaw: String           // 存储枚举原始值
    var subCategory: String?
    var tags: [String]
    var notes: String?
    var sourceRaw: String             // manual / quick / appIntent / backfill
    var createdAt: Date
    var isDeepWork: Bool
    var qualityScore: Double?         // 0.0 ~ 1.0

    // 计算属性: category, source, duration, formattedDuration, isRunning
    // 扩展方法: stop(), isOn(date:), startMinuteOfDay(), endMinuteOfDay()
}
```

### 汇总模型（计算型，非持久化）
- `DailySummary` — 从当天 `[TimeEntry]` 计算，包含分类时间、质量评分、深度工作、消耗预算
- `WeeklySummary` — 聚合 7 个 `DailySummary`，包含趋势和周评分
- `MonthlySummary` — 月度聚合 + `MonthlyComparison` 环比对比

### 质量评分系统

```swift
protocol ScoringEngine {
    func score(summary: DailySummary) -> QualityScoreResult
    func score(summary: WeeklySummary) -> QualityScoreResult
}

// RuleBasedScoringEngine: 5 项规则，满分 100
// - 输出占比 (30pts) - 阈值 15%
// - 输入占比 (20pts) - 阈值 20%
// - 消耗控制 (20pts) - 警戒 25%
// - 深度工作 (20pts) - 达标 2 次/天
// - 连续记录 (10pts) - streak bonus

// 评分等级: excellent(>=80) / good(60~79) / average(40~59) / poor(<40)
```

---

## 📱 功能完成状态

### Phase 1 — MVP 基础（已完成 ✅）

| 功能 | 状态 |
|------|------|
| 四分类计时器 + 快速开始 | ✅ |
| SwiftData 持久化 | ✅ |
| 补记录功能 | ✅ |
| 日历时间块视图（日/周） | ✅ |
| 日报统计 + 分类占比 | ✅ |
| 周报复盘 + 趋势分析 | ✅ |
| 空白时间检测 + 补记录 | ✅ |
| 洞察提示（规则引擎） | ✅ |
| App Intents 脚手架 | ✅ |

### Phase 2 — 数据深度（已完成 ✅）

| 功能 | 状态 | 实现说明 |
|------|------|----------|
| 时间质量评分系统（F-26/27/28）| ✅ | ScoringEngine 协议 + RuleBasedScoringEngine |
| 深度工作自动检测（F-24/25）| ✅ | productive + >=90min 自动标记 |
| 时间雷达图（F-18）| ✅ | 自定义 4 轴 RadarChartView（理想 vs 实际）|
| 日历时间块补记录（点击空白区）| ✅ | CalendarBlockView 空白时段点击 → AddEntryView |
| 月度时间账本（F-21）| ✅ | MonthlyLedgerView + MonthlySummary + MonthlyComparison |
| 连续记录 streak 显示 | ✅ | ViewModel.calculateStreak() + StreakBadgeView |
| 娱乐时间预算提醒（F-41）| ✅ | ConsumptionBudgetStatus + ConsumptionBudgetView |

### Phase 3 — 体验提升（已完成 ✅）

| 功能 | 状态 | 实现说明 |
|------|------|----------|
| App Intents 完整实现（F-05）| ✅ | 4 个 Intent + TimeCategoryAppEnum + Siri Phrases |
| 记录编辑功能完善（F-04）| ✅ | EditEntryView + ViewModel.updateEntry() |
| Apple Charts 图表升级 | ✅ | BarMark + SectorMark 替换自定义图表 |
| 周报分享卡片（F-36）| ✅ | ShareCardView + ImageRenderer 3x + UIActivityViewController |
| CSV 数据导出（F-35）| ✅ | CSVExportView + FileDocument + BOM UTF-8 |

### Phase 4 — 智能与生态（开发中）

| 功能 | 状态 | 实现说明 |
|------|------|----------|
| 时间块拖动编辑（F-09）| ✅ | DraggableTimeBlockCell + 长按拖动 + 边缘调整 + 15min吸附 |
| AI 行为建议（F-33）| ✅ | BehaviorSuggestionEngine 规则引擎 + 6 类建议 + 优先级排序 |
| 年度累计账本（F-22/23）| ✅ | YearlySummary 模型 + YearlyLedgerView + 月度趋势 + 年度对比 |
| 年报生成（F-37）| ✅ | YearlyShareCardView + ImageRenderer 3x + 年度亮点 |
| Widget（锁屏 + 主屏）（F-29/30/31）| ✅ | Small/Medium/Large + 锁屏 3 尺寸 + Live Activity + 控制中心 |
| iCloud 同步（F-43）| 🟡 待实现 | P1 |
| 评分规则自定义（F-40）| 🟡 待实现 | P2 |
| AI 时间结构评估报告（F-34）| 🟡 待实现 | P3 |

---

## 📱 最新更新 (2026-03-26)

### ✅ Widget 全套实现（F-29/30/31）

**新增文件 (TimeWidget Target)**:
- `WidgetData.swift` — 共享数据模型 + App Group UserDefaults 读写
- `TimeWidget.swift` — 主屏 Widget (Small/Medium/Large) + 锁屏 Widget (Circular/Rectangular/Inline)
- `TimeWidgetLiveActivity.swift` — 实时活动（灵动岛 + 锁屏 Banner）
- `TimeWidgetControl.swift` — 控制中心 Widget
- `TimeWidgetBundle.swift` — Widget Bundle（4 个 Widget）

**新增文件 (主 App)**:
- `Helpers/WidgetData.swift` — 共享数据模型（与 Widget 端同步）
- `Models/LiveActivityAttributes.swift` — Live Activity 属性定义

**修改文件**:
- `ViewModels/TimeTrackingViewModel.swift` — 新增 `syncWidgetData()` + `startLiveActivity()` + `stopLiveActivity()`
- `Info.plist` — 添加 `NSSupportsLiveActivities`

#### 数据共享方案
- **App Group**: `group.com.test.huxi.TimeTracker`
- **共享机制**: `WidgetSharedData` 结构体，JSON 编码存入 App Group UserDefaults
- **同步时机**: 开始/停止计时、setup、保存数据时自动同步
- **刷新策略**: 计时中每 1 分钟刷新，非计时每 15 分钟刷新

#### 主屏 Widget（Small/Medium/Large）
- **Small**: 计时状态 + 总时间 + 质量评分 + streak + 分类色带
- **Medium**: 左侧计时+指标 / 右侧四分类时间列表
- **Large**: 计时状态 + 评分圆环 + 四分类进度条 + streak/深度工作/消耗预算

#### 锁屏 Widget
- **Circular**: 计时 icon+timer / 评分数字
- **Rectangular**: 计时状态 / 总时间+评分+分类概览
- **Inline**: "输出计时中" / "今日 3h 20m · 72分"

#### Live Activity（灵动岛 + 锁屏 Banner）
- **展开**: 分类图标+名称 / 计时器 / 开始时间
- **紧凑**: 分类图标+名称 / timer
- **最小**: 分类图标
- **锁屏 Banner**: 分类信息 + 计时器 + 状态指示
- **自动管理**: 开始计时启动 / 停止计时结束

#### 控制中心 Widget
- 显示当前计时状态，点击打开 App

#### 重要配置
- 主 App + Widget Extension 均需添加 App Group: `group.com.test.huxi.TimeTracker`
- 主 App Info.plist 需添加 `NSSupportsLiveActivities = YES`
- Widget Extension 的 Deployment Target 与主 App 保持一致

---

## 📱 历史更新 (2026-03-26 早)

**新增文件**: `Models/BehaviorSuggestion.swift`, `Views/Summary/BehaviorSuggestionView.swift`  
**修改文件**: `Views/Summary/DailySummaryView.swift`, `Views/Timer/TimerView.swift`

#### 功能说明
基于用户时间数据的规则引擎，生成个性化行为改善建议：

- **6 类建议**: 时间结构、深度工作、趋势预警、时段优化、习惯养成、正面鼓励
- **4 级优先级**: 紧急(critical) / 重要(important) / 一般(normal) / 正面(positive)
- **上下文分析**: 结合日/周数据、上周对比、时段分布、消耗高峰、深度工作模式
- **个性化建议**: 包含具体可执行的 `actionHint`（如"设一个无手机时段"）
- **展示形式**: 日报页完整卡片列表 + 计时页顶部内联摘要

#### 新增类型
- `BehaviorSuggestion` — 建议模型（type / title / detail / priority / actionHint）
- `BehaviorAnalysisContext` — 分析上下文（日/周汇总 + streak + 时段分布）
- `BehaviorSuggestionEngine` — 规则引擎（5 大分析维度，最多返回 5 条建议）
- `BehaviorSuggestionView` — 可折叠建议卡片列表
- `SuggestionCard` — 单条建议展开/折叠卡片
- `InlineSuggestionView` — 计时页内联迷你建议

#### 分析规则
```
结构分析: 消耗>35%紧急, >25%重要; 输出<10%紧急, <15%一般; 输入<10%重要; 维持>60%
深度工作: 0次重要, <3次建议; 分析最佳时段
趋势分析: 消耗周环比+10%预警; 输出周环比-10%预警; 输出+5%鼓励
时段优化: 消耗高峰时段提醒; 晚间(20:00+)消耗>30min提醒
习惯分析: streak>=30鼓励, >=7鼓励, ==0提醒; 空白时间提醒
```

### ✅ 年度累计账本（F-22/23）

**新增文件**: `Models/YearlySummary.swift`, `Views/Summary/YearlyLedgerView.swift`  
**修改文件**: `ViewModels/TimeTrackingViewModel.swift`, `Views/MainTabView.swift`

#### 功能说明
年度时间数据全景展示：

- **年度总览**: 总小时数 + 记录天数 + 覆盖率 + 深度工作次数 + 日均时间
- **时间账本**: 各分类年度累计时间 + 占比饼图 + 与去年对比
- **月度趋势图**: Swift Charts 堆叠 BarMark，展示 12 个月各分类时间变化
- **质量评分趋势**: LineMark + PointMark + 60 分及格线
- **年度亮点**: 2x2 宫格展示总投入/最高效月/最活跃月/深度工作
- **年度洞察**: 智能洞察文案（产出/消耗/输入/记录习惯/深度工作/最佳月份）
- **年份导航**: 左右切换年份

#### 新增类型
- `YearlySummary` — 年度汇总（聚合 12 个 MonthlySummary）
- `YearlyComparison` — 年度对比（当前 vs 去年）
- `YearlySummary.MonthlyTrendItem` — Charts 月度趋势数据项
- `YearlySummary.MonthlyQualityItem` — Charts 月度质量数据项

#### ViewModel 新增方法
- `entries(forYear:)` — 年度数据查询
- `yearlySummary(year:)` — 年度汇总生成
- `yearlyComparison(year:)` — 年度对比生成

### ✅ 年报生成（F-37）

**实现文件**: `Views/Summary/YearlyLedgerView.swift`（内含 YearlyShareCardView）

#### 功能说明
年报分享卡片，可生成高清图片分享：

- **卡片内容**: 年度核心数字 + 四分类占比 + 最高效月份 + 品牌水印
- **分享功能**: ImageRenderer 3x 高清渲染 + UIActivityViewController 系统分享
- **入口**: 年报页 toolbar 分享按钮

#### Tab 导航更新
MainTabView 新增第 6 个 Tab：年报（chart.bar.doc.horizontal）

---

## 📱 历史更新 (2026-03-26 早)

### ✅ 时间块拖动编辑（F-09）

**修改文件**: `Views/Calendar/CalendarBlockView.swift`, `ViewModels/TimeTrackingViewModel.swift`

#### 功能说明
日历日视图中的时间块支持拖动操作，可以直接拖动调整时间：

- **整体移动**：长按时间块 0.3s 后拖动，保持时长不变，修改起止时间
- **调整开始时间**：拖动时间块顶部边缘手柄
- **调整结束时间**：拖动时间块底部边缘手柄
- **15 分钟吸附**：拖动释放后自动对齐到最近的15分钟整数
- **最小时长保护**：调整时保证最小 5 分钟时长
- **视觉反馈**：拖动中显示阴影 + 缩放 + 透明度变化 + 吸附参考线
- **触觉反馈**：开始拖动和释放时触发 Haptic
- **进行中记录过滤**：正在计时的记录不可拖动

#### 新增类型
- `DraggableTimeBlockCell` — 替代原 `TimeBlockCell`，包含完整拖动交互
- `DayCalendarView.DragMode` — 拖动模式枚举（none/move/resizeTop/resizeBottom）

#### ViewModel 新增方法
- `moveEntry(_:toStartTime:)` — 整体移动，保持时长
- `resizeEntryStart(_:toStartTime:)` — 调整开始时间
- `resizeEntryEnd(_:toEndTime:)` — 调整结束时间

#### 手势实现
```swift
// 整体移动：LongPress(0.3s) + Drag 组合手势
LongPressGesture(minimumDuration: 0.3)
    .sequenced(before: DragGesture(minimumDistance: 0))

// 边缘调整：直接 Drag，最小距离 4pt
DragGesture(minimumDistance: 4)
```

---

## 📱 历史更新 (2026-03-25)

### ✅ Phase 3 体验提升 — 全部 5 个功能完成

#### 1. App Intents 完整实现（F-05）

**修改文件**: `Intents/TimeTrackerIntents.swift`

**新增类型**:
- `TimeCategoryAppEnum` — AppEnum 适配四分类
- `IntentModelContainer` — 共享 SwiftData ModelContainer
- `StartTrackingIntent` — 开始计时（自动停止已有计时）
- `StopTrackingIntent` — 停止计时（可附备注，自动检测深度工作）
- `TodayStatusIntent` — 查询今日时间状态和质量评分
- `QuickBackfillIntent` — 快速补记录（分类 + 时长分钟数）
- `TimeTrackerShortcuts` — Siri 短语注册

**Siri 短语**: 用TimeTracker开始计时 / 停止计时 / 查看今日状态 / 补记录

#### 2. 记录编辑功能（F-04）

**新增文件**: `Views/Entry/EditEntryView.swift`  
**修改文件**: `Views/Entry/EntryDetailView.swift`, `ViewModels/TimeTrackingViewModel.swift`

- `EditEntryView` — 完整编辑表单（分类、时间、子分类、标签、备注、深度工作）
- `EntryDetailView` — 新增 toolbar 编辑按钮 + 列表内编辑按钮 + sheet 弹出
- `ViewModel.updateEntry()` — 更新所有可编辑字段

#### 3. Apple Charts 图表升级

**修改文件**: `Views/Summary/WeeklyReviewView.swift`, `Views/Summary/DailySummaryView.swift`

- 周报质量趋势：`BarMark` + 及格线 `RuleMark` + Y 轴标注
- 周报分类饼图：`SectorMark` 环形图（替换自定义 Circle.trim）
- 周报每日堆叠图：`dailyStackedChart` 新增
- 日报时间结构：`SectorMark` 扇形图（替换自定义 GeometryReader 条形图）
- 移除旧的 `PieSlice` 辅助类型

#### 4. 周报分享卡片（F-36）

**新增文件**: `Views/Summary/ShareCardView.swift`  
**修改文件**: `Views/Summary/WeeklyReviewView.swift`

- `ShareCardView` — 分享卡片预览和渲染
- `ImageRenderer` 3x 渲染生成 UIImage
- `ShareSheet` (UIViewControllerRepresentable) 调用系统分享
- `QualityScoreResult.ScoreBreakdown.shortName` 扩展
- 周报 toolbar 新增分享按钮

#### 5. CSV 数据导出（F-35）

**新增文件**: `Views/Summary/CSVExportView.swift`  
**修改文件**: `ViewModels/TimeTrackingViewModel.swift`, `Views/Summary/MonthlyLedgerView.swift`

- `CSVExportView` — 日期范围选择 + 记录数预览 + 生成导出
- `CSVDocument` (FileDocument) — 符合 fileExporter 协议
- `CSVExporter.export(entries:)` — 11 列 CSV 生成，BOM UTF-8 编码
- `ViewModel.fetchEntries(from:to:)` — 日期范围查询
- 月报 toolbar 新增导出按钮

#### 6. 辅助更新

- `DateHelper` 新增 `shortDateTimeString(_:)` 和 `yearMonthString(_:)` 方法
- PRD 更新至 v1.2，Phase 3 标记完成

---

## 📱 历史更新

### ✅ Phase 2 数据深度 — 全部 7 个功能完成 (2026-03-24)

#### 新增文件
- `Models/QualityScore.swift` — 评分引擎（331 行）
- `Models/MonthlySummary.swift` — 月汇总 + 环比对比（167 行）
- `Views/Summary/RadarChartView.swift` — 自定义 4 轴雷达图（197 行）
- `Views/Summary/QualityScoreView.swift` — 质量评分组件集（294 行）
- `Views/Summary/MonthlyLedgerView.swift` — 月度时间账本（290 行）

#### 修改文件
- `Models/DailySummary.swift` — 增加深度工作检测、质量评分、消耗预算
- `Models/WeeklySummary.swift` — 增加深度工作统计、质量评分、消耗预算
- `ViewModels/TimeTrackingViewModel.swift` — 增加月度查询、streak 计算、深度工作自动检测、消耗预算状态、补记录预设时间
- `Views/MainTabView.swift` — 新增第 5 个 Tab（月报）
- `Views/Timer/TimerView.swift` — 顶部 streak + 消耗预算 + 质量评分
- `Views/Calendar/CalendarBlockView.swift` — 空白点击补记录 + 深度工作徽章
- `Views/Summary/DailySummaryView.swift` — 质量评分 + 深度工作 + 消耗预算 + 时间结构条
- `Views/Summary/WeeklyReviewView.swift` — 质量评分 + 雷达图 + 深度工作周统计 + 质量趋势

### ✅ Phase 1 MVP — 9 个基础功能完成

初始版本实现了完整的时间追踪 MVP：四分类计时、SwiftData 持久化、日历视图、日报/周报、空白检测、补记录功能。

---

## 🔑 关键代码约定

### 1. SwiftData 使用
- 仅有一个 `@Model`：`TimeEntry`
- 所有汇总（Daily/Weekly/Monthly）是计算型结构体，不持久化
- 枚举字段存储为 rawValue 字符串（`categoryRaw`、`sourceRaw`）
- `ModelContainer` 在 `TimeTrackerApp` 中创建，通过环境注入

### 2. ViewModel 模式
- 单一 `TimeTrackingViewModel`，使用 `@Observable` 宏
- 所有视图通过 `@Bindable var viewModel` 引用
- `setup(context:)` 在 `MainTabView.onAppear` 中调用
- 计时器使用 `Timer.scheduledTimer`，通过 `Task { @MainActor }` 回调

### 3. 深度工作检测
- 自动规则：`isProductive` 分类 + 时长 >= 90 分钟
- 检测时机：停止计时时、`autoDetectDeepWork()` 近 7 天扫描
- 手动标记：`AddEntryView` / `EditEntryView` 提供 Toggle

### 4. 评分系统
- `ScoringEngine` 协议，当前实现 `RuleBasedScoringEngine`
- 配置通过 `ScoringConfig` 可调
- 消耗预算：日 3h / 周 15h

### 5. 日期处理
- 周一作为一周开始（`firstWeekday = 2`）
- 中文 locale（`zh_CN`）
- 16 小时作为每日可用时间基准（用于空白时间计算）

### 6. 文件自动同步
- Xcode 使用 `PBXFileSystemSynchronizedRootGroup`
- 新增 `.swift` 文件到对应目录即可，无需手动编辑 `.pbxproj`

---

## 💡 开发建议

### 给北城的建议
1. **保持简单** — 柳比歇夫方法论本身就强调简单持续
2. **数据驱动** — 所有功能围绕"认知时间结构"的核心目标
3. **情绪设计** — 每个数据展示要能触发情绪反应
4. **测试为先** — 评分引擎可配置化已经为 A/B 测试做好准备
5. **代码注释** — 关键逻辑保持中文注释

### 开发注意事项
1. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`，注意并发标注
2. `#Predicate` 内不能使用计算属性（如 `category`），必须用 `startTime` 等存储属性
3. `ImageRenderer` 需要在 `@MainActor` 上下文中使用
4. `FileDocument` 需要遵循 Transferable 相关协议用于 `fileExporter`

---

## 📚 参考资料

### 官方文档
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [SwiftData Guide](https://developer.apple.com/documentation/swiftdata)
- [Swift Charts](https://developer.apple.com/documentation/charts)
- [App Intents](https://developer.apple.com/documentation/appintents)

### 产品文档
- `PRODUCT_REQUIREMENTS.md` — PRD 全景规划文档（v1.2）

---

## 📞 联系方式

**开发者**: 北城  
**项目地址**: GitHub - TimeTracker

---

*最后更新: 2026年3月26日*  
*本文档由 GitHub Copilot 辅助创建和维护*
