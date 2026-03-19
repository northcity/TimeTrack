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
                AddEntryView(viewModel: viewModel)
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

    var body: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                // 时间刻度背景
                timeGrid

                // 时间块
                timeBlocks
            }
            .padding(.leading, 50) // 留出时间标签空间
        }
    }

    // 时间刻度
    private var timeGrid: some View {
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
            }
        }
    }

    // 时间块叠加
    private var timeBlocks: some View {
        let entries = viewModel.entries(for: date)
        return ForEach(entries) { entry in
            TimeBlockCell(entry: entry, hourHeight: hourHeight, startHour: startHour)
                .onTapGesture {
                    selectedEntry = entry
                }
        }
    }
}

// MARK: - 单个时间块
struct TimeBlockCell: View {
    let entry: TimeEntry
    let hourHeight: CGFloat
    let startHour: Int

    var body: some View {
        let startMinute = entry.startMinuteOfDay()
        let endMinute = entry.endMinuteOfDay()
        let topOffset = CGFloat(startMinute - startHour * 60) / 60.0 * hourHeight
        let blockHeight = max(CGFloat(endMinute - startMinute) / 60.0 * hourHeight, 24)

        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(entry.category.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.category.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(entry.category.color)

                if blockHeight > 36 {
                    Text("\(DateHelper.timeString(entry.startTime)) - \(entry.endTime.map(DateHelper.timeString) ?? "...")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if blockHeight > 52, let notes = entry.notes {
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
        .frame(height: blockHeight)
        .background(entry.category.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(entry.category.color.opacity(0.2), lineWidth: 0.5)
        )
        .offset(y: topOffset)
        .padding(.horizontal, 4)
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
