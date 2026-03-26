# TimeTracker UI/UX 设计规范手册

> 版本：v1.3  
> 日期：2026年3月26日  
> 状态：与 PRD v1.3 同步

---

## 一、设计核心理念（Design Pillars）

三个关键词定义了 TimeTracker 所有界面的设计决策标准：

| 理念 | 英文 | 设计含义 | 反面案例 |
|------|------|----------|----------|
| **镜像** | Mirror | 界面应像镜子一样真实、冷峻地反射用户的时间状态 | 美化数据、隐藏问题 |
| **结构** | Structure | 视觉重心应放在"时间分类占比"而非"单一事件名称" | 以事件列表为主的 UI |
| **警醒** | Awareness | 通过色彩强度触发用户的情绪反馈（成就、焦虑或紧迫） | 中立无感的信息展示 |

### 设计决策检验清单

每个页面上线前，用以下问题自检：

- [ ] 用户 3 秒内能看出"今天时间结构健不健康"吗？
- [ ] 页面有没有一句"人话"结论？（不能只有图表）
- [ ] 色彩是否在传递情绪？（绿=好 / 橙=注意 / 红=警告）
- [ ] 数字是否等宽对齐？

---

## 二、色彩系统（Color System）

### 2.1 语义化核心色（Semantic Colors）

所有时间块**必须严格遵循以下四色分类**，禁止自定义色相，以培养用户的条件反射。

| 类别 | 颜色名 | HEX 代码 | RGB | 视觉隐喻 | 对应活动 |
|------|--------|----------|-----|----------|----------|
| **输出** | Deep Action | `#00C853` | 0, 200, 83 | 能量注入、高产 | 深度工作、写作、创作 |
| **输入** | Ocean Intake | `#2979FF` | 41, 121, 255 | 吸收、开阔 | 阅读、听课、调研 |
| **维持** | Neutral Ground | `#9E9E9E` | 158, 158, 158 | 背景、平稳 | 睡眠、饮食、通勤 |
| **消耗** | Black Hole | `#FF1744` | 255, 23, 68 | 危机、警示 | 刷短视频、无目的摸鱼 |

#### SwiftUI 实现

```swift
extension Color {
    // MARK: - 语义核心色
    static let ttOutput      = Color(hex: "#00C853")  // Deep Action
    static let ttInput       = Color(hex: "#2979FF")  // Ocean Intake
    static let ttMaintenance = Color(hex: "#9E9E9E")  // Neutral Ground
    static let ttConsumption = Color(hex: "#FF1744")  // Black Hole
}
```

#### 核心色使用规则

| 场景 | 用法 | 不透明度 |
|------|------|----------|
| 时间块填充 | 纯色 | 100% |
| 进度条/条形图 | 纯色 | 100% |
| 背景高亮（选中态） | 核心色 | 12% |
| 雷达图区域填充 | 核心色 | 20% |
| 饼图/环形图 | 纯色 | 100% |

### 2.2 基础色（Foundation Colors）

| 用途 | Light Mode | Dark Mode | 说明 |
|------|-----------|-----------|------|
| 背景（Primary） | `#F5F5F7` | `#121212` | 页面主背景 |
| 背景（Secondary） | `#FFFFFF` | `#1E1E1E` | 卡片/弹窗背景 |
| 背景（Tertiary） | `#F0F0F0` | `#2C2C2C` | 输入框/分组背景 |
| 文字主色 | `#1D1D1F` | `#F5F5F7` | 标题、正文 |
| 文字副色 | `#86868B` | `#98989D` | 辅助信息、刻度、时间轴 |
| 分割线 | `#E5E5E5` | `#38383A` | 极细线 0.5pt |

### 2.3 状态色（Status Colors）

用于评分、预算、趋势等需要传达"好/中/差"判断的场景。

| 状态 | 颜色 | HEX | 使用场景 |
|------|------|-----|----------|
| 优秀/达标 | 绿色 | `#34C759` | 评分 ≥ 80、占比达标、趋势上升 |
| 警告/注意 | 橙色 | `#FF9500` | 评分 60-79、预算 > 80%、轻度超标 |
| 危险/超标 | 红色 | `#FF3B30` | 评分 < 60、预算超标、严重偏离 |
| 中性/信息 | 蓝色 | `#007AFF` | 链接、可交互元素、信息提示 |

#### 状态色 vs 语义色的区别

```
语义色 = 分类身份（输出永远是绿色 #00C853）
状态色 = 判断结论（评分高是绿色 #34C759，评分低是红色 #FF3B30）

两者不混用。时间块颜色 ≠ 评分颜色。
```

---

## 三、字体规范（Typography）

### 3.1 字体栈

| 平台 | 正文字体 | 数字专用字体 |
|------|----------|-------------|
| iOS | SF Pro | SF Mono |
| 备选 | System Default | Menlo |

### 3.2 关键规范：数字必须等宽

> **所有涉及时间、时长、评分的数字必须使用等宽字体（Monospaced）**，确保上下对齐时视觉不跳动。

```swift
// SwiftUI 实现
Text("03:45:20")
    .font(.system(size: 32, weight: .bold, design: .monospaced))

// 评分数字
Text("78")
    .font(.system(size: 48, weight: .heavy, design: .monospaced))
```

### 3.3 文本层级体系

| 层级 | 用途 | 字号 | 字重 | 字体 | 行高 | 示例 |
|------|------|------|------|------|------|------|
| **Display** | 评分数字、总时长 | 32pt | Bold | Monospaced | 1.2 | `78分` `8.5h` |
| **Headline** | 扎心语/每日评价 | 18pt | Semi-bold | Default | 1.4 | 「你在逃避创作吗？」 |
| **Title** | 卡片标题、Section Header | 16pt | Semi-bold | Default | 1.3 | `今日时间结构` |
| **Body** | 时间块标题、正文 | 14pt | Medium | Default | 1.4 | `编程 / 开发` |
| **Caption** | 辅助标签、时间刻度 | 12pt | Regular | Default | 1.3 | `09:00` `占比 25%` |
| **Micro** | 极小标注 | 10pt | Regular | Default | 1.2 | 图表轴标签 |

### 3.4 SwiftUI 字体映射

```swift
extension Font {
    // MARK: - TimeTracker Typography
    static let ttDisplay   = Font.system(size: 32, weight: .bold, design: .monospaced)
    static let ttHeadline  = Font.system(size: 18, weight: .semibold)
    static let ttTitle     = Font.system(size: 16, weight: .semibold)
    static let ttBody      = Font.system(size: 14, weight: .medium)
    static let ttCaption   = Font.system(size: 12, weight: .regular)
    static let ttMicro     = Font.system(size: 10, weight: .regular)
    
    // 数字专用
    static let ttScore     = Font.system(size: 48, weight: .heavy, design: .monospaced)
    static let ttTimer     = Font.system(size: 40, weight: .bold, design: .monospaced)
    static let ttDuration  = Font.system(size: 14, weight: .medium, design: .monospaced)
}
```

---

## 四、间距与布局（Spacing & Layout）

### 4.1 间距系统（4pt 基准网格）

| Token | 值 | 用途 |
|-------|-----|------|
| `xs` | 4pt | 图标与文字间距、紧凑元素内间距 |
| `sm` | 8pt | 列表项内元素间距、标签间距 |
| `md` | 12pt | 卡片内边距（compact） |
| `lg` | 16pt | 卡片内边距（standard）、Section 间距 |
| `xl` | 24pt | Section 之间的间距 |
| `xxl` | 32pt | 页面顶部/底部安全间距 |

### 4.2 卡片规范

```
┌─────────────────────────────────────┐
│  16pt padding                        │
│  ┌─────────────────────────────┐    │
│  │  标题 (ttTitle)              │    │
│  │  8pt                         │    │
│  │  内容区域                    │    │
│  │  12pt                        │    │
│  │  底部辅助信息 (ttCaption)    │    │
│  └─────────────────────────────┘    │
│  16pt padding                        │
└─────────────────────────────────────┘

圆角：12pt
阴影：color: #000 @ 4%, offset: (0, 2), blur: 8
```

### 4.3 时间块规范（日历视图）

```
最小高度：30pt（30 分钟对应 30pt，1px/min）
圆角：8pt
左边框：3pt 宽色条（分类语义色）
内边距：水平 8pt，垂直 4pt
文字：分类名 (ttBody) + 时长 (ttDuration, 副色)
```

---

## 五、图标系统（Iconography）

### 5.1 分类图标

| 分类 | SF Symbol | 备选 | 使用场景 |
|------|-----------|------|----------|
| 输出 | `pencil.and.outline` | `hammer.fill` | 快捷按钮、分类标签 |
| 输入 | `book.fill` | `brain.head.profile` | 快捷按钮、分类标签 |
| 维持 | `heart.fill` | `bed.double.fill` | 快捷按钮、分类标签 |
| 消耗 | `play.tv.fill` | `gamecontroller.fill` | 快捷按钮、分类标签 |

### 5.2 状态图标

| 状态 | SF Symbol | 颜色 |
|------|-----------|------|
| 深度工作 | `flame.fill` | `#FF9500` |
| 趋势上升 | `arrow.up.right` | 状态色-绿 |
| 趋势下降 | `arrow.down.right` | 状态色-红 |
| 警告 | `exclamationmark.triangle.fill` | 状态色-橙 |
| 连续记录 | `bolt.fill` | `#FF9500` |

### 5.3 图标规格

| 场景 | 尺寸 | 字重 |
|------|------|------|
| Tab Bar | 24pt | Regular |
| 快捷按钮 | 28pt | Medium |
| 行内标签 | 14pt | Regular |
| 导航栏 | 20pt | Regular |

---

## 六、组件规范（Component Specs）

### 6.1 快捷启动卡片（Timer View）

```
┌──────────────────┐
│  ● 输出           │  ← 分类色圆点 + 分类名 (ttBody)
│                    │
│  ▶ 开始计时       │  ← CTA 按钮，分类色填充
│                    │
│  今日：1h 30m     │  ← ttCaption, 副色
└──────────────────┘

尺寸：(screenWidth - 48) / 2  × 100pt
圆角：16pt
状态：
  - 默认：白色背景 + 分类色边框 1pt
  - 活跃计时中：分类色背景 12% + 脉冲动画
  - 已禁用（其他分类计时中）：opacity 0.4
```

### 6.2 评分环（Quality Score Ring）

```
        ┌───┐
       ╱  78 ╲      ← ttScore, 居中
      │   分   │     ← ttCaption, 副色
       ╲      ╱
        └───┘

外环：粗 8pt，颜色根据分数：
  ≥ 80 → 状态色-绿
  60~79 → 状态色-橙
  < 60 → 状态色-红
内环：背景色，粗 8pt
动画：从 0 到目标值，1.2s，easeOut
尺寸：直径 120pt
```

### 6.3 日报扎心语卡片

```
┌─────────────────────────────────────┐
│                                      │
│  「今天 80% 的时间在输入，            │  ← ttHeadline
│    但几乎没有产出——                   │
│    你在逃避创作吗？」                 │
│                                      │
│  基于今日数据 · 犀利模式              │  ← ttCaption, 副色
└─────────────────────────────────────┘

背景：渐变（分类色 5% → 透明）
左边框：3pt，根据评价情绪取色
  警醒 → 状态色-红
  鼓励 → 状态色-绿
  中性 → 文字副色
圆角：12pt
内边距：20pt
```

### 6.4 后悔换算卡片

```
┌─────────────────────────────────────┐
│  ⏱ 消耗换算                         │  ← ttTitle
│                                      │
│  本周消耗：11h                       │  ← ttDisplay, 消耗色
│                                      │
│  ≈ 读完 1.5 本书                     │  ← ttBody, 副色
│  ≈ 写 3 篇文章                       │
│  ≈ 学完 1 门课的 60%                 │
│                                      │
│  ┌──────────┐                       │
│  │ 📤 分享   │                       │  ← 分享按钮
│  └──────────┘                       │
└─────────────────────────────────────┘

背景：消耗色 6% 底色
圆角：12pt
```

### 6.5 成就徽章

```
  ┌───┐
  │ 🔥│  ← 32pt emoji
  └───┘
  深度工作  ← ttCaption, 居中
  
尺寸：64 × 76pt
未解锁状态：grayscale + opacity 0.3
解锁动画：scale 0 → 1.2 → 1.0, 0.6s, spring
```

### 6.6 时间结构条（Stacked Bar）

```
输入 ████████████░░░░░░░░░░░░ 25%
输出 ███░░░░░░░░░░░░░░░░░░░░  8% ⚠️
消耗 ██████████████████░░░░░░ 40% ⚠️
维持 █████████████░░░░░░░░░░░ 27%

高度：8pt per bar
间距：6pt between bars
圆角：4pt
背景轨道：#E5E5E5 (Light) / #38383A (Dark)
⚠️ 标记：超出阈值时在右侧显示
```

---

## 七、动效规范（Motion & Animation）

### 7.1 基础原则

- **有意义**：动效必须传达状态变化，不做装饰性动画
- **快速**：主交互动效 < 0.3s，数据过渡 < 0.6s
- **一致**：全 App 使用统一缓动曲线

### 7.2 动效参数

| 场景 | 时长 | 曲线 | SwiftUI |
|------|------|------|---------|
| 页面切换 | 0.3s | easeInOut | `.animation(.easeInOut(duration: 0.3))` |
| 卡片展开/收起 | 0.25s | spring | `.animation(.spring(response: 0.25))` |
| 评分环填充 | 1.2s | easeOut | `.animation(.easeOut(duration: 1.2))` |
| 数字滚动 | 0.8s | easeOut | 自定义 `AnimatableModifier` |
| 时间块出现 | 0.2s | easeOut | `.transition(.opacity.combined(with: .scale))` |
| 徽章解锁 | 0.6s | spring(bounce) | `.animation(.spring(response: 0.6, dampingFraction: 0.6))` |
| 计时脉冲 | 2.0s | easeInOut, repeat | `.animation(.easeInOut(duration: 2).repeatForever())` |

### 7.3 触觉反馈

| 操作 | 反馈类型 | UIKit |
|------|----------|-------|
| 开始计时 | Medium Impact | `UIImpactFeedbackGenerator(style: .medium)` |
| 停止计时 | Success Notification | `UINotificationFeedbackGenerator().notificationOccurred(.success)` |
| 时间块拖动吸附 | Light Impact | `UIImpactFeedbackGenerator(style: .light)` |
| 删除操作 | Warning Notification | `UINotificationFeedbackGenerator().notificationOccurred(.warning)` |
| 评分刷新 | Soft Impact | `UIImpactFeedbackGenerator(style: .soft)` |

---

## 八、页面结构规范（Page Structure）

### 8.1 Tab 结构

```
┌─────────────────────────────────┐
│                                  │
│         [页面内容区]              │
│                                  │
├─────────────────────────────────┤
│  ⏱      📅      📊      ⚙️    │
│ 计时    日历    分析    设置     │
└─────────────────────────────────┘
```

### 8.2 计时页（Timer Tab）— 情绪核心

```
┌─────────────────────────────────┐
│  消耗预算状态栏                   │  ← 顶部，3 级颜色
├─────────────────────────────────┤
│                                  │
│  [ 活跃计时卡片 / 无计时提示 ]    │  ← 核心区域
│                                  │
├─────────────────────────────────┤
│  ┌────────┐  ┌────────┐        │
│  │ 📘输入  │  │ 📗输出  │        │  ← 四宫格快捷启动
│  └────────┘  └────────┘        │
│  ┌────────┐  ┌────────┐        │
│  │ 📕消耗  │  │ 📓维持  │        │
│  └────────┘  └────────┘        │
├─────────────────────────────────┤
│  今日速览                        │  ← 迷你日报
│  记录时长 8.5h | 效率分 72       │
│  连续记录 🔥 12天                │
└─────────────────────────────────┘
```

### 8.3 分析页（Analysis Tab）— 认知核心

```
┌─────────────────────────────────┐
│  [日报]  [周报]  [月账本]  [年]  │  ← Segmented Control
├─────────────────────────────────┤
│                                  │
│  「扎心语卡片」                   │  ← 最顶部，最醒目
│                                  │
│  评分环 78分                      │  ← 第二视觉焦点
│                                  │
│  时间结构条                       │  ← 四分类堆叠条
│                                  │
│  后悔换算卡片                     │  ← 消耗 > 0 时展示
│                                  │
│  深度工作统计                     │
│                                  │
│  空白时段提醒                     │
│                                  │
│  记录列表                         │
└─────────────────────────────────┘
```

---

## 九、Dark Mode 适配规范

### 9.1 核心原则

- 语义核心色（四分类色）在 Dark Mode 下 **不变**
- 状态色在 Dark Mode 下 **不变**
- 仅背景色、文字色、分割线色跟随模式切换

### 9.2 对照表

| 元素 | Light | Dark |
|------|-------|------|
| 页面背景 | `#F5F5F7` | `#121212` |
| 卡片背景 | `#FFFFFF` | `#1E1E1E` |
| 主文字 | `#1D1D1F` | `#F5F5F7` |
| 副文字 | `#86868B` | `#98989D` |
| 分割线 | `#E5E5E5` | `#38383A` |
| 时间块 | 语义色 100% | 语义色 100% |
| 评分环背景轨道 | `#E5E5E5` | `#38383A` |

---

## 十、无障碍规范（Accessibility）

### 10.1 对比度要求

- 文字主色 vs 背景：对比度 ≥ 7:1（WCAG AAA）
- 文字副色 vs 背景：对比度 ≥ 4.5:1（WCAG AA）
- 语义色块内文字：白色 `#FFFFFF`，对比度 ≥ 4.5:1

### 10.2 Dynamic Type 支持

- 所有文字层级支持 Dynamic Type 缩放
- 最小字号不低于 11pt
- 评分数字在超大字号时限制最大为 48pt

### 10.3 VoiceOver 标注

| 组件 | accessibilityLabel | accessibilityValue |
|------|-------------------|-------------------|
| 时间块 | "{分类名}，{开始}-{结束}" | "{时长}" |
| 评分环 | "时间质量评分" | "{分数}分，{等级}" |
| 快捷按钮 | "开始{分类名}计时" | "今日已记录{时长}" |
| 结构条 | "{分类名}占比" | "{百分比}" |

---

## 十一、设计 Token 汇总（Quick Reference）

```swift
// MARK: - Design Tokens

enum TTDesign {
    
    // MARK: Colors - Semantic
    enum SemanticColor {
        static let output      = Color(hex: "#00C853")
        static let input       = Color(hex: "#2979FF")
        static let maintenance = Color(hex: "#9E9E9E")
        static let consumption = Color(hex: "#FF1744")
    }
    
    // MARK: Colors - Status
    enum StatusColor {
        static let success = Color(hex: "#34C759")
        static let warning = Color(hex: "#FF9500")
        static let danger  = Color(hex: "#FF3B30")
        static let info    = Color(hex: "#007AFF")
    }
    
    // MARK: Typography
    enum Typography {
        static let display  = Font.system(size: 32, weight: .bold, design: .monospaced)
        static let headline = Font.system(size: 18, weight: .semibold)
        static let title    = Font.system(size: 16, weight: .semibold)
        static let body     = Font.system(size: 14, weight: .medium)
        static let caption  = Font.system(size: 12, weight: .regular)
        static let micro    = Font.system(size: 10, weight: .regular)
        static let score    = Font.system(size: 48, weight: .heavy, design: .monospaced)
        static let timer    = Font.system(size: 40, weight: .bold, design: .monospaced)
    }
    
    // MARK: Spacing
    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 12
        static let lg:  CGFloat = 16
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32
    }
    
    // MARK: Radius
    enum Radius {
        static let small:  CGFloat = 4
        static let medium: CGFloat = 8
        static let card:   CGFloat = 12
        static let button: CGFloat = 16
    }
}
```

---

*本规范与 PRODUCT_REQUIREMENTS.md 同步维护，UI 变更需同时更新两份文档。*
