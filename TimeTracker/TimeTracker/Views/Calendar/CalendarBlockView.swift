//
//  CalendarBlockView.swift
//  TimeTracker
//
//  日历时间块视图 - 日/周模式
//

import SwiftUI

struct CalendarBlockView: View {
    @Bindable var viewModel: TimeTrackingViewModel
    @State private var viewMode: CalendarViewMode = .day
    @State private var currentDate: Date = Date()
    @State private var selectedEntry: TimeEntry?

    enum CalendarViewMode: String, CaseIterable {
        case day = "日"
        case week = "周"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - 顶部导航
                headerBar

                // MARK: - 视图模式切换
                Picker("视图", selection: $viewMode) {
                    ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                // MARK: - 日历内容
                switch viewMode {
                case .day:
                    DayCalendarView(
                        viewModel: viewModel,
                        date: currentDate,
                        selectedEntry: $selectedEntry
                    )
                case .week:
                    WeekCalendarView(
                        viewModel: viewModel,
                        weekStartDate: DateHelper.startOfWeek(currentDate),
                        selectedEntry: $selectedEntry
                    )
                }
            }
            .navigationTitle("日历")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedEntry) { entry in
                NavigationStack {
                    EntryDetailView(entry: entry, viewModel: viewModel)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $viewModel.showingBackfill) {
                AddEntryView(
                    viewModel: viewModel,
                    presetStart: viewModel.backfillPresetStart,
                    presetEnd: viewModel.backfillPresetEnd
                )
            }
        }
    }

    // MARK: - 顶部日期导航
    private var headerBar: some View {
        HStack {
            Button {
                withAnimation {
                    if viewMode == .day {
                        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                    } else {
                        currentDate = DateHelper.previousWeekStart(from: currentDate)
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            VStack(spacing: 2) {
                if viewMode == .day {
                    Text(DateHelper.fullDateString(currentDate))
                        .font(.headline)
                    Text(DateHelper.weekdayString(currentDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    let weekStart = DateHelper.startOfWeek(currentDate)
                    let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
                    Text("\(DateHelper.shortDateString(weekStart)) - \(DateHelper.shortDateString(weekEnd))")
                        .font(.headline)
                }
            }

            Spacer()

            Button {
                withAnimation {
                    if viewMode == .day {
                        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                    } else {
                        currentDate = DateHelper.nextWeekStart(from: currentDate)
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }

            // 回到今天
            Button {
                withAnimation {
                    currentDate = Date()
                }
            } label: {
                Text("今天")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
            }
            .padding(.leading, 8)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - 日视图
struct DayCalendarView: View {
    @Bindable var viewModel: TimeTrackingViewModel
    let date: Date
    @Binding var selectedEntry: TimeEntry?

    /// 每小时高度
    private let hourHeight: CGFloat = 60
    /// 显示的起始小时
    private let startHour = 6
    /// 显示的结束小时
    private let endHour = 24
    /// 吸附精度（分钟）
    private let snapMinutes: CGFloat = 15

    // MARK: - 拖动状态（F-09）
    @State private var dragEntry: TimeEntry?
    @State private var dragMode: DragMode = .none
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    enum DragMode {
        case none
        case move           // 整体移动
        case resizeTop      // 调整开始时间
        case resizeBottom   // 调整结束时间
    }

    var body: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                // 时间刻度背景（可点击空白区补记录）
                timeGridWithTap

                // 时间块（含拖动支持）
                draggableTimeBlocks

                // 拖动时的吸附参考线
                if isDragging {
                    snapGuideLine
                }
            }
            .padding(.leading, 50) // 留出时间标签空间
        }
    }

    // MARK: - 时间刻度（带空白区点击补记录）
    private var timeGridWithTap: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 4) {
                    Text(String(format: "%02d:00", hour))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)
                        .offset(x: -50)

                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 0.5)
                        .frame(maxWidth: .infinity)
                }
                .frame(height: hourHeight)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !isDragging else { return }
                    let calendar = Calendar.current
                    if let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date),
                       let end = calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: date) {
                        viewModel.startBackfill(start: start, end: end)
                    }
                }
            }
        }
    }

    // MARK: - 可拖动时间块
    private var draggableTimeBlocks: some View {
        let entries = viewModel.entries(for: date).filter { !$0.isRunning }
        return ForEach(entries) { entry in
            DraggableTimeBlockCell(
                entry: entry,
                hourHeight: hourHeight,
                startHour: startHour,
                snapMinutes: snapMinutes,
                dragEntry: $dragEntry,
                dragMode: $dragMode,
                dragOffset: $dragOffset,
                isDragging: $isDragging,
                onTap: {
                    selectedEntry = entry
                },
                onDragEnd: { mode, totalOffset in
                    applyDrag(entry: entry, mode: mode, offset: totalOffset)
                }
            )
        }
    }

    // MARK: - 吸附参考线
    private var snapGuideLine: some View {
        Group {
            if let entry = dragEntry {
                let snappedMinute = snappedMinuteForDrag(entry: entry)
                let y = CGFloat(snappedMinute - startHour * 60) / 60.0 * hourHeight

                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
                    .offset(y: y)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - 拖动逻辑

    /// 计算吸附后的分钟值
    private func snappedMinuteForDrag(entry: TimeEntry) -> Int {
        let startMinute = entry.startMinuteOfDay()
        let endMinute = entry.endMinuteOfDay()
        let offsetMinutes = Int(dragOffset / hourHeight * 60)

        let targetMinute: Int
        switch dragMode {
        case .move, .resizeTop:
            targetMinute = startMinute + offsetMinutes
        case .resizeBottom:
            targetMinute = endMinute + offsetMinutes
        case .none:
            return startMinute
        }

        // 吸附到 snapMinutes 整数倍
        let snapped = Int(round(Double(targetMinute) / Double(snapMinutes)) * Double(snapMinutes))
        return max(startHour * 60, min(endHour * 60, snapped))
    }

    /// 应用拖动结果
    private func applyDrag(entry: TimeEntry, mode: DragMode, offset: CGFloat) {
        let offsetMinutes = offset / hourHeight * 60
        let snappedOffset = round(offsetMinutes / snapMinutes) * snapMinutes
        let deltaSeconds = TimeInterval(snappedOffset * 60)

        guard abs(deltaSeconds) >= 60 else { return } // 至少 1 分钟变化

        switch mode {
        case .move:
            let newStart = entry.startTime.addingTimeInterval(deltaSeconds)
            viewModel.moveEntry(entry, toStartTime: newStart)
        case .resizeTop:
            let newStart = entry.startTime.addingTimeInterval(deltaSeconds)
            viewModel.resizeEntryStart(entry, toStartTime: newStart)
        case .resizeBottom:
            let newEnd = (entry.endTime ?? Date()).addingTimeInterval(deltaSeconds)
            viewModel.resizeEntryEnd(entry, toEndTime: newEnd)
        case .none:
            break
        }
    }
}

// MARK: - 可拖动的时间块单元格
struct DraggableTimeBlockCell: View {
    let entry: TimeEntry
    let hourHeight: CGFloat
    let startHour: Int
    let snapMinutes: CGFloat
    @Binding var dragEntry: TimeEntry?
    @Binding var dragMode: DayCalendarView.DragMode
    @Binding var dragOffset: CGFloat
    @Binding var isDragging: Bool
    let onTap: () -> Void
    let onDragEnd: (DayCalendarView.DragMode, CGFloat) -> Void

    /// 拖动边缘检测区域高度
    private let edgeHitArea: CGFloat = 14

    private var isBeingDragged: Bool {
        dragEntry?.id == entry.id && isDragging
    }

    var body: some View {
        let startMinute = entry.startMinuteOfDay()
        let endMinute = entry.endMinuteOfDay()
        let baseTopOffset = CGFloat(startMinute - startHour * 60) / 60.0 * hourHeight
        let baseHeight = max(CGFloat(endMinute - startMinute) / 60.0 * hourHeight, 24)

        // 计算拖动中的偏移
        let (displayTop, displayHeight) = calculateDisplayPosition(
            baseTopOffset: baseTopOffset,
            baseHeight: baseHeight,
            isBeingDragged: isBeingDragged
        )

        return ZStack(alignment: .top) {
            // 主体内容
            timeBlockContent(height: displayHeight)

            // 顶部拖动手柄（调整开始时间）
            if displayHeight > 40 {
                edgeHandle(isTop: true)
                    .frame(height: edgeHitArea)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .gesture(edgeDragGesture(isTop: true))
            }

            // 底部拖动手柄（调整结束时间）
            if displayHeight > 40 {
                VStack {
                    Spacer()
                    edgeHandle(isTop: false)
                        .frame(height: edgeHitArea)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .gesture(edgeDragGesture(isTop: false))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: displayHeight)
        .offset(y: displayTop)
        .padding(.horizontal, 4)
        .zIndex(isBeingDragged ? 100 : 0)
        .opacity(isBeingDragged ? 0.85 : 1.0)
        .shadow(color: isBeingDragged ? .black.opacity(0.2) : .clear, radius: 8, y: 4)
        .scaleEffect(isBeingDragged ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isBeingDragged)
        .onTapGesture {
            if !isDragging {
                onTap()
            }
        }
        .gesture(moveDragGesture)
    }

    // MARK: - 计算拖动中的显示位置
    private func calculateDisplayPosition(
        baseTopOffset: CGFloat,
        baseHeight: CGFloat,
        isBeingDragged: Bool
    ) -> (CGFloat, CGFloat) {
        guard isBeingDragged else {
            return (baseTopOffset, baseHeight)
        }

        switch dragMode {
        case .move:
            return (baseTopOffset + dragOffset, baseHeight)
        case .resizeTop:
            return (baseTopOffset + dragOffset, max(baseHeight - dragOffset, 24))
        case .resizeBottom:
            return (baseTopOffset, max(baseHeight + dragOffset, 24))
        case .none:
            return (baseTopOffset, baseHeight)
        }
    }

    // MARK: - 时间块内容
    private func timeBlockContent(height: CGFloat) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(entry.category.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.category.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(entry.category.color)

                    if entry.isDeepWork {
                        Text("🔥")
                            .font(.caption2)
                    }
                }

                if height > 36 {
                    Text("\(DateHelper.timeString(entry.startTime)) - \(entry.endTime.map(DateHelper.timeString) ?? "...")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if height > 52, let notes = entry.notes {
                    Text(notes)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(entry.formattedDuration)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(entry.category.color.opacity(isBeingDragged ? 0.2 : 0.12), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                    isBeingDragged ? entry.category.color : entry.category.color.opacity(0.2),
                    lineWidth: isBeingDragged ? 1.5 : 0.5
                )
        )
    }

    // MARK: - 边缘拖动手柄
    private func edgeHandle(isTop: Bool) -> some View {
        VStack(spacing: 0) {
            if !isTop { Spacer() }
            RoundedRectangle(cornerRadius: 2)
                .fill(isBeingDragged && (dragMode == (isTop ? .resizeTop : .resizeBottom))
                      ? entry.category.color
                      : Color.secondary.opacity(0.3))
                .frame(width: 32, height: 4)
                .padding(.vertical, 2)
            if isTop { Spacer() }
        }
    }

    // MARK: - 整体移动手势（长按 + 拖动）
    private var moveDragGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                switch value {
                case .first(true):
                    // 长按识别成功
                    break
                case .second(true, let drag):
                    if let drag = drag {
                        if !isDragging {
                            startDrag(mode: .move)
                        }
                        dragOffset = drag.translation.height
                    }
                default:
                    break
                }
            }
            .onEnded { value in
                if isDragging {
                    endDrag()
                }
            }
    }

    // MARK: - 边缘拖动手势
    private func edgeDragGesture(isTop: Bool) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                if !isDragging {
                    startDrag(mode: isTop ? .resizeTop : .resizeBottom)
                }
                dragOffset = value.translation.height
            }
            .onEnded { _ in
                endDrag()
            }
    }

    private func startDrag(mode: DayCalendarView.DragMode) {
        isDragging = true
        dragEntry = entry
        dragMode = mode
        dragOffset = 0
        // 触觉反馈
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func endDrag() {
        let finalOffset = dragOffset
        let finalMode = dragMode

        // 触觉反馈
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        onDragEnd(finalMode, finalOffset)

        withAnimation(.easeOut(duration: 0.2)) {
            isDragging = false
            dragEntry = nil
            dragMode = .none
            dragOffset = 0
        }
    }
}

// MARK: - 周视图
struct WeekCalendarView: View {
    @Bindable var viewModel: TimeTrackingViewModel
    let weekStartDate: Date
    @Binding var selectedEntry: TimeEntry?

    var body: some View {
        let days = DateHelper.daysInWeek(of: weekStartDate)

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 2) {
                ForEach(days, id: \.self) { day in
                    WeekDayColumn(
                        viewModel: viewModel,
                        date: day,
                        selectedEntry: $selectedEntry
                    )
                    .frame(width: 100)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - 周视图中的一天列
struct WeekDayColumn: View {
    @Bindable var viewModel: TimeTrackingViewModel
    let date: Date
    @Binding var selectedEntry: TimeEntry?

    var body: some View {
        let entries = viewModel.entries(for: date)
        let isToday = DateHelper.isToday(date)

        VStack(spacing: 4) {
            // 日期头
            VStack(spacing: 2) {
                Text(DateHelper.weekdayString(date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.headline)
                    .foregroundStyle(isToday ? .white : .primary)
                    .frame(width: 32, height: 32)
                    .background(isToday ? Color.accentColor : Color.clear, in: Circle())
            }
            .padding(.bottom, 4)

            // 时间块列表（紧凑模式）
            if entries.isEmpty {
                Text("无记录")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
            } else {
                ForEach(entries) { entry in
                    CompactTimeBlock(entry: entry)
                        .onTapGesture {
                            selectedEntry = entry
                        }
                }
            }

            Spacer()
        }
    }
}

// MARK: - 紧凑时间块（周视图用）
struct CompactTimeBlock: View {
    let entry: TimeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Circle()
                    .fill(entry.category.color)
                    .frame(width: 6, height: 6)
                Text(entry.category.displayName)
                    .font(.caption2.bold())
                    .lineLimit(1)
            }
            Text(entry.formattedDuration)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
        .background(entry.category.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
    }
}
