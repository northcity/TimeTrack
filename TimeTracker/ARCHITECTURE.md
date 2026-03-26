# TimeTracker - 项目归档记忆文件

> 基于柳比歇夫时间统计法的 iOS 时间追踪 App  
> 创建时间：2026年3月19日  
> 技术栈：SwiftUI + SwiftData + App Intents  
> 最低部署版本：iOS 26.2  

---

## 📁 项目目录结构

```
TimeTracker/                          ← Xcode 工程根目录
├── TimeTracker.xcodeproj/
│   ├── project.pbxproj               ← 工程配置（使用文件系统同步组，新增文件自动入编译）
│   └── project.xcworkspace/
└── TimeTracker/                      ← 源码目录
    ├── TimeTrackerApp.swift          ← App 入口，配置 ModelContainer
    ├── ContentView.swift             ← 保留兼容，重定向至 MainTabView
    ├── Info.plist
    ├── TimeTracker.entitlements
    │
    ├── Models/
    │   ├── Category.swift            ← TimeCategory 枚举 + EntrySource 枚举
    │   ├── TimeEntry.swift           ← @Model 核心时间记录（SwiftData 持久化）
    │   ├── DailySummary.swift        ← 每日汇总（实时计算，非持久化 struct）
    │   └── WeeklySummary.swift       ← 每周汇总（实时计算，非持久化 struct）
    │
    ├── ViewModels/
    │   └── TimeTrackingViewModel.swift  ← @Observable 主 ViewModel（计时、查询、补记录）
    │
    ├── Views/
    │   ├── MainTabView.swift         ← Tab 导航（计时 / 日历 / 日报 / 周报）
    │   ├── Timer/
    │   │   └── TimerView.swift       ← 计时主页：活跃计时器 + 4分类快捷启动 + 今日概览
    │   ├── Calendar/
    │   │   └── CalendarBlockView.swift  ← 日历时间块视图（日视图 + 周视图）
    │   ├── Entry/
    │   │   ├── AddEntryView.swift    ← 补记录/手动添加记录（支持预设时间段）
    │   │   └── EntryDetailView.swift ← 记录详情 + 删除 + 标签 FlowLayout
    │   └── Summary/
    │       ├── DailySummaryView.swift   ← 日报：分类统计 + 进度条 + 空白提示 + 洞察
    │       └── WeeklyReviewView.swift  ← 周报：效率趋势柱状图 + 分类饼图 + 每日明细
    │
    ├── Helpers/
    │   └── DateHelper.swift          ← 日期工具函数 + TimeInterval 格式化扩展
    │
    └── Intents/
        └── TimeTrackerIntents.swift  ← App Intents 脚手架（Siri / Shortcuts）
```

---

## 🗂️ 数据模型设计

### TimeEntry（`@Model` SwiftData 持久化）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | `UUID` | 唯一标识 |
| `startTime` | `Date` | 开始时间 |
| `endTime` | `Date?` | 结束时间（nil = 进行中）|
| `categoryRaw` | `String` | 分类原始值（用于 SwiftData）|
| `category` | `TimeCategory` | 计算属性包装 |
| `subCategory` | `String?` | 子分类（预留扩展）|
| `tags` | `[String]` | 标签数组 |
| `notes` | `String?` | 备注 |
| `sourceRaw` | `String` | 来源原始值 |
| `source` | `EntrySource` | 计算属性包装 |
| `createdAt` | `Date` | 创建时间 |
| `isDeepWork` | `Bool` | 是否深度工作（预留）|
| `qualityScore` | `Double?` | 质量评分（预留 AI）|

### TimeCategory（枚举）

| case | 显示 | 说明 | `isProductive` |
|------|------|------|------|
| `.input` | 输入 | 学习 / 阅读 | `true` |
| `.output` | 输出 | 写作 / 创作 | `true` |
| `.consumption` | 消耗 | 娱乐 / 消耗 | `false` |
| `.maintenance` | 维持 | 生活 / 杂务 | `false` |

### EntrySource（枚举）

| case | 说明 |
|------|------|
| `.manual` | 手动记录 |
| `.quick` | 快捷按钮 |
| `.appIntent` | Siri / Shortcuts |
| `.backfill` | 补记录 |

### DailySummary（计算 struct，非持久化）

通过 `DailySummary.from(entries:date:)` 工厂方法从 `TimeEntry` 数组实时生成。

| 计算属性 | 说明 |
|----------|------|
| `totalTimePerCategory` | 各分类总时间字典 |
| `totalTrackedTime` | 当日总记录时间 |
| `emptyTime` | 空白时间（基准 16h = 57600s）|
| `outputScore` | 输入+输出占比（效率评分）|
| `pureOutputRatio` | 纯输出占比 |
| `insights` | 洞察提示数组（可接 AI）|

### WeeklySummary（计算 struct，非持久化）

通过 `WeeklySummary.from(entries:weekStartDate:)` 生成，包含 7 个 `DailySummary`。

---

## 🧠 ViewModel 核心方法（TimeTrackingViewModel）

```swift
// 计时控制
func startTracking(category:source:)   // 开始计时，自动停止上一条
func stopTracking(notes:)              // 停止并可添加备注
func quickStart(category:)            // 快捷按钮（source = .quick）

// 补记录
func addBackfillEntry(startTime:endTime:category:notes:tags:)

// 数据查询
func entries(for date:) -> [TimeEntry]
func entries(forWeekOf date:) -> [TimeEntry]
func dailySummary(for date:) -> DailySummary
func weeklySummary(for date:) -> WeeklySummary
func findGaps(on date:minGapMinutes:) -> [(start:end:)]  // 空白时段检测

// 删除
func deleteEntry(_ entry:)
```

---

## 📱 UI 视图架构

### Tab 1 — 计时（TimerView）
- 当前活跃计时器（大字计时 + 分类标签 + 停止按钮）
- 4 个分类快捷启动按钮（有活跃计时时禁用）
- 今日概览卡片（已记录 / 空白 / 效率 + 分类进度条）
- 右上角 `+` 跳转补记录

### Tab 2 — 日历（CalendarBlockView）
- 日/周切换 Picker
- 日期前后导航 + 回今天按钮
- **日视图**：固定每小时 60pt 高，按时间线性定位时间块，支持点击查看详情
- **周视图**：横向滚动，每列一天，紧凑时间块列表

### Tab 3 — 日报（DailySummaryView）
- 总览卡片（已记录 / 空白 / 效率三列）
- 分类详情（图标 + 名称 + 时长 + 占比 + 渐变进度条）
- 未记录空白时段提示 + 快速补记录按钮
- 洞察提示（规则引擎，预留 AI 接口）
- 今日记录列表（可点击进入详情）

### Tab 4 — 周报（WeeklyReviewView）
- 周导航 + 周次显示
- 周总览（总记录 / 平均效率 / 记录天数）
- 每日效率趋势柱状图（7日）
- 分类占比环形图 + 图例
- 每日明细（堆叠条形图）
- 周洞察

---

## 🔮 预留扩展点

| 扩展 | 位置 | 状态 |
|------|------|------|
| 深度工作检测 | `TimeEntry.isDeepWork` | 字段已预留 |
| AI 行为评分 | `TimeEntry.qualityScore` | 字段已预留 |
| AI 洞察接口 | `DailySummary.insights` / `WeeklySummary.insights` | 规则引擎实现，可替换为 AI |
| 子分类 | `TimeEntry.subCategory` | 字段已预留 |
| App Intents 完整实现 | `Intents/TimeTrackerIntents.swift` | 脚手架已建 |
| Widget 快速计时 | — | 需新建 Widget Extension |
| 导出报表 | — | 待实现 |
| 数据图表（Charts）| — | 待接入 Apple Charts 框架 |

---

## 🔧 技术说明

- **SwiftData 主 Model**：仅 `TimeEntry` 持久化，聚合数据实时计算避免冗余存储
- **@Observable**：`TimeTrackingViewModel` 使用 Observation 框架，无需 `@ObservableObject`
- **文件系统同步组**：Xcode 工程使用 `PBXFileSystemSynchronizedRootGroup`，新增 .swift 文件自动加入编译，无需手动添加到 project.pbxproj
- **日历视图定位算法**：`startMinuteOfDay()` → 转换为 pt 偏移量，每分钟 = `hourHeight / 60`
- **周开始**：以周一为第一天（`Calendar.firstWeekday = 2`）

---

## 🚀 后续迭代计划

1. **Widget**：锁屏 / 桌面小组件，快速开始/结束计时
2. **App Intents 完整实现**：共享 ModelContainer，Siri 语音记录
3. **Apple Charts**：替换手写柱状图 / 饼图
4. **Deep Work Score**：连续专注时段检测算法
5. **AI 洞察**：本地 Core ML 或调用 API 生成个性化建议
6. **iCloud 同步**：SwiftData + CloudKit
7. **导出**：CSV / JSON 报表导出
