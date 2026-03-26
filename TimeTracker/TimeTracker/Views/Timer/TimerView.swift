//
//  TimerView.swift
//  TimeTracker
//
//  主视图 - 基于市面顶级时间管理/习惯养成应用(Toggl/Streaks/Forest)的方法论重构
//

import SwiftUI

struct TimerView: View {
    @Bindable var viewModel: TimeTrackingViewModel
    @State private var showStopSheet: Bool = false
    @State private var stopNotes: String = ""
    
    // 动画状态
    @State private var pulseState: Bool = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 经典 iOS 高级浅灰底色
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // MARK: - 1. 沉浸式专注区域 (Focus Zone)
                        // 借鉴 Forest / Focus To-Do: 计时状态占据绝对主导权
                        if viewModel.activeEntry != nil {
                            activeTimerCard
                                .padding(.top, 16)
                                .transition(.scale(scale: 0.95).combined(with: .opacity))
                        } else {
                            headerGreeting
                                .padding(.top, 16)
                                .transition(.opacity)
                        }
                        
                        // MARK: - 2. 零阻力启动区 (Frictionless Start)
                        // 借鉴 Streaks / Toggl: 一键启动，去掉多余层级
                        quickStartList
                            .padding(.horizontal, TTDesign.Spacing.lg)
                        
                        // MARK: - 3. 当日回顾区 (Contextual Awareness)
                        // 借鉴 Apple Fitness: 每日进度可视化
                        todaySummaryBoard
                            .padding(.horizontal, TTDesign.Spacing.lg)
                            .padding(.bottom, 120) // 留出防遮挡空间
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.activeEntry != nil)
                
                // MARK: - 悬浮控制台 (Dynamic Floating Action)
                // 借鉴主流手势：在底部保留全局添加按钮
                if viewModel.activeEntry == nil {
                    floatingAddButton
                }
            }
            .navigationTitle("Focus")
            .navigationBarHidden(true)
            .sheet(isPresented: $showStopSheet) {
                stopTrackingSheet
            }
            .sheet(isPresented: $viewModel.showingAddEntry) {
                AddEntryView(viewModel: viewModel)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseState = true
                }
            }
        }
    }
    
    // MARK: - 头图：未计时状态的问候
    private var headerGreeting: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(Date(), format: .dateTime.weekday(.wide).month().day())
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .textCase(.uppercase)
                
                Text("Ready to focus?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
            }
            Spacer()
        }
        .padding(.horizontal, TTDesign.Spacing.xl)
    }
    
    // MARK: - 头图：沉浸式计时卡片 (Active Timer)
    private var activeTimerCard: some View {
        guard let active = viewModel.activeEntry else { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(spacing: 20) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: active.category.icon)
                        Text(active.category.displayName)
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(active.category.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(active.category.color.opacity(0.15), in: Capsule())
                    
                    Spacer()
                    
                    // 呼吸脉冲指示器
                    Circle()
                        .fill(active.category.color)
                        .frame(width: 8, height: 8)
                        .opacity(pulseState ? 1 : 0.3)
                        .shadow(color: active.category.color, radius: pulseState ? 4 : 0)
                }
                
                // 核心数字排版
                Text(viewModel.elapsedTime.timerFormatted)
                    .font(.system(size: 72, weight: .light, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.vertical, 10)
                
                // 长按/滑动停止反馈 (拟物化拉锯/长按)
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                    impact.impactOccurred()
                    showStopSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.fill")
                            .font(.system(size: 14))
                        Text("Finish Session")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(active.category.color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: active.category.color.opacity(0.3), radius: 10, y: 5)
                }
            }
            .padding(24)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 15, y: 8)
            .padding(.horizontal, TTDesign.Spacing.lg)
        )
    }
    
    // MARK: - 快速启动列表 (一键摩擦力最小化)
    private var quickStartList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK START")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.secondary)
                .padding(.leading, 8)
            
            VStack(spacing: 0) {
                ForEach(Array(TimeCategory.allCases.enumerated()), id: \.element) { index, category in
                    let isActive = (viewModel.activeEntry?.category == category)
                    let isDisabled = (viewModel.activeEntry != nil && !isActive)
                    
                    Button {
                        if isActive {
                            showStopSheet = true
                        } else if !isDisabled {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            viewModel.quickStart(category: category)
                        }
                    } label: {
                        HStack(spacing: 16) {
                            // 图标
                            ZStack {
                                Circle()
                                    .fill(category.color.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Image(systemName: category.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(category.color)
                            }
                            
                            // 文字信息
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.displayName)
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.primary)
                                
                                let time = viewModel.dailySummary(for: Date()).totalTimePerCategory[category] ?? 0
                                if time > 0 {
                                    Text("Today: \(time.shortFormatted)")
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundStyle(Color.secondary)
                                } else {
                                    Text("Not started")
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundStyle(Color.secondary.opacity(0.5))
                                }
                            }
                            
                            Spacer()
                            
                            // 动作按钮
                            if isActive {
                                Image(systemName: "waveform")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(category.color)
                                    .opacity(pulseState ? 1 : 0.4)
                            } else {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled)
                    .opacity(isDisabled ? 0.4 : 1.0)
                    
                    if index < TimeCategory.allCases.count - 1 {
                        Divider()
                            .padding(.leading, 76)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.02), radius: 8, y: 4)
        }
    }
    
    // MARK: - 每日进度可视化 (Apple Fitness 风格的块状进度)
    private var todaySummaryBoard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY'S PROGRESS")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.secondary)
                .padding(.leading, 8)
            
            let summary = viewModel.dailySummary(for: Date())
            let score = Int(summary.qualityScore.totalScore)
            
            VStack(spacing: 20) {
                // 大数据概览
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(summary.totalTrackedTime.shortFormatted)
                            .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                        Text("Tracked Time")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 2) {
                            Text("\(score)")
                                .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(qualityColor(summary.qualityScore.totalScore))
                                .offset(y: -4)
                        }
                        Text("Quality Score")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.secondary)
                    }
                }
                
                // 时间分配比例条 (无缝拼接风格)
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        if summary.totalTrackedTime == 0 {
                            Rectangle()
                                .fill(Color(uiColor: .tertiarySystemFill))
                        } else {
                            ForEach(TimeCategory.allCases) { cat in
                                let time = summary.totalTimePerCategory[cat] ?? 0
                                let ratio = time / summary.totalTrackedTime
                                if ratio > 0 {
                                    Rectangle()
                                        .fill(cat.color)
                                        .frame(width: max(0, geo.size.width * ratio))
                                }
                            }
                        }
                    }
                }
                .frame(height: 12)
                .clipShape(Capsule())
            }
            .padding(20)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.02), radius: 8, y: 4)
        }
    }
    
    // MARK: - 悬浮添加按钮 (全局入口)
    private var floatingAddButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            viewModel.showingAddEntry = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Manual Log")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.primary, in: Capsule())
            .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
        }
        .padding(.bottom, 24)
    }

    // MARK: - 停止追踪弹窗
    private var stopTrackingSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let active = viewModel.activeEntry {
                    VStack(spacing: 8) {
                        Image(systemName: active.category.icon)
                            .font(.system(size: 40))
                            .foregroundStyle(active.category.color)
                            .padding(.bottom, 8)
                        
                        Text(viewModel.elapsedTime.shortFormatted)
                            .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(Color.primary)
                        
                        Text(active.category.displayName)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.top, 40)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Add a note (Optional)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.secondary)
                    
                    TextField("What did you work on?", text: $stopNotes, axis: .vertical)
                        .font(.system(size: 16))
                        .focused($isNoteFocused)
                        .padding(16)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(uiColor: .separator), lineWidth: 0.5))
                        .lineLimit(3...5)
                }
                .padding(.horizontal, 24)

                Spacer()
                
                Button {
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                    viewModel.stopTracking(notes: stopNotes.isEmpty ? nil : stopNotes)
                    stopNotes = ""
                    showStopSheet = false
                } label: {
                    Text("Save Session")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(TTDesign.StatusColor.success, in: Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showStopSheet = false }
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .presentationDetents([.fraction(0.65)])
    }
    
    @FocusState private var isNoteFocused: Bool

    private func qualityColor(_ score: Double) -> Color {
        let level = QualityScoreResult.ScoreLevel.from(score: score)
        switch level {
        case .excellent: return TTDesign.StatusColor.success
        case .good: return TTDesign.StatusColor.info
        case .average: return TTDesign.StatusColor.warning
        case .poor: return TTDesign.StatusColor.danger
        }
    }
}

