# TimeTracker ⏱

**基于柳比歇夫时间统计法的 iOS 时间追踪 App**

> 柳比歇夫一生用时间统计法记录了 56 年的时间使用情况，这款 App 帮助你数字化这一实践。

---

## ✨ MVP 功能

- **快速计时** — 一键开始/结束，支持 4 大分类快捷按钮
- **日历时间块** — 日/周视图直观呈现时间使用情况
- **日报** — 分类统计、效率评分、空白时段提示与补记录
- **周报** — 每日趋势、分类占比、周洞察
- **补记录** — 随时填补未记录的时间段

## 🗂️ 时间分类

| 分类 | 说明 | 颜色 |
|------|------|------|
| 📘 输入 | 学习 / 阅读 | 蓝色 |
| 📗 输出 | 写作 / 创作 | 绿色 |
| 📙 消耗 | 娱乐 / 社交媒体 | 橙色 |
| 📕 维持 | 生活 / 杂务 | 紫色 |

## 🛠 技术栈

- **SwiftUI** — 声明式 UI
- **SwiftData** — 本地数据持久化
- **Observation** — `@Observable` 状态管理
- **App Intents** — Siri / Shortcuts 快速记录（脚手架）
- 最低部署：**iOS 26.2**

## 📁 项目结构

详见 [ARCHITECTURE.md](./ARCHITECTURE.md)

## 🚀 快速开始

```bash
git clone git@github.com:northcity/TimeTrack.git
cd TimeTrack
open TimeTracker/TimeTracker.xcodeproj
```

在 Xcode 中选择模拟器或真机，`Cmd+R` 运行。

---

## 📌 开发路线图

- [ ] Widget 快速计时
- [ ] App Intents 完整实现（Siri 语音）
- [ ] Apple Charts 图表优化
- [ ] Deep Work 检测算法
- [ ] AI 个性化洞察
- [ ] iCloud 同步
- [ ] CSV / JSON 导出
