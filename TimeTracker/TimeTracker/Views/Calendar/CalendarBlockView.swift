//
//  CalendarBlockView.swift
//  TimeTracker
//
//  日历视图 - 日、周、月、年穿插视图
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
        case month = "月"
        case year = "年"
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

                // MARK: - 日历
                switch viewMode {
                case .day:
                    AppleDayTimelineView(viewModel: viewModel, date: currentDate, selectedEntry: $selectedEntry)
                case .week:
                    AppleWeekTimelineView(viewModel: viewModel, date: currentDate, selectedEntry: $selectedEntry)
                case .month:
                    AppleMonthCalendarView(viewModel: viewModel, date: currentDate)
                case .year:
                    AppleYearHeatmapView(viewModel: viewModel, date: currentDate)
                }
            }
            .navigationTitle("时间轴")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedEntry) { entry in
                EntryDetailView(entry: entry, viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    private var headerBar: some View {
        HStack {
            Button(action: { changeDate(by: -1) }) {
                Image(systemName: "chevron.left").padding()
            }
            Spacer()
            Text(dateHeaderText)
                .font(.headline)
                .bold()
            Spacer()
            Button(action: { changeDate(by: 1) }) {
                Image(systemName: "chevron.right").padding()
            }
            Button("今天") {
                currentDate = Date()
            }
            .padding(.trailing)
        }
    }
    
    private var dateHeaderText: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .day:
            formatter.dateFormat = "M月d日 EEEE"
        case .week:
            let start = DateHelper.startOfWeek(currentDate)
            let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? currentDate
            formatter.dateFormat = "M月d日"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        case .month:
            formatter.dateFormat = "yyyy年 M月"
        case .year:
            formatter.dateFormat = "yyyy年"
        }
        return formatter.string(from: currentDate)
    }
    
    private func changeDate(by value: Int) {
        let cal = Calendar.current
        switch viewMode {
        case .day:
            currentDate = cal.date(byAdding: .day, value: value, to: currentDate) ?? currentDate
        case .week:
            currentDate = cal.date(byAdding: .weekOfYear, value: value, to: currentDate) ?? currentDate
        case .month:
            currentDate = cal.date(byAdding: .month, value: value, to: currentDate) ?? currentDate
        case .year:
            currentDate = cal.date(byAdding: .year, value: value, to: currentDate) ?? currentDate
        }
    }
}

// MARK: - Timeline Layout Engine
struct LayoutItem: Equatable {
    let entry: TimeEntry
    var col: Int
    var maxCol: Int
}

class TimelineLayoutEngine {
    static func layout(entries: [TimeEntry]) -> [LayoutItem] {
        let sorted = entries.sorted { $0.startTime < $1.startTime }
        var result: [LayoutItem] = []
        var activeColumns: [(endTime: Date, col: Int)] = []
        
        for entry in sorted {
            activeColumns.removeAll { $0.endTime <= entry.startTime }
            activeColumns.sort { $0.col < $1.col }
            
            var colIndex = 0
            for col in activeColumns {
                if col.col == colIndex {
                    colIndex += 1
                } else {
                    break
                }
            }
            
            let endTime = entry.endTime ?? Date()
            activeColumns.append((endTime: endTime, col: colIndex))
            
            result.append(LayoutItem(entry: entry, col: colIndex, maxCol: activeColumns.count))
        }
        
        for i in 0..<result.count {
            let item = result[i]
            let overlaps = result.filter { r in
                let end1 = item.entry.endTime ?? Date()
                let end2 = r.entry.endTime ?? Date()
                return item.entry.startTime < end2 && r.entry.startTime < end1
            }
            let maxCol = overlaps.map { $0.col }.max() ?? 0
            result[i].maxCol = maxCol + 1
        }
        
        return result
    }
}

// MARK: - AppleDayTimelineView
struct AppleDayTimelineView: View {
    var viewModel: TimeTrackingViewModel
    var date: Date
    @Binding var selectedEntry: TimeEntry?
    
    let hourHeight: CGFloat = 60
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<24) { hour in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(hour):00")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .frame(width: 45, alignment: .bottomTrailing)
                                .offset(y: -6)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 1)
                        }
                        .frame(height: hourHeight, alignment: .top)
                    }
                }
                
                let entries = viewModel.entries(for: date)
                let layoutItems = TimelineLayoutEngine.layout(entries: entries)
                
                GeometryReader { geo in
                    let leftPadding: CGFloat = 53
                    let availableWidth = geo.size.width - leftPadding - 10
                    
                    ForEach(Array(layoutItems.enumerated()), id: \.element.entry.id) { index, item in
                        let yOffset = CGFloat(item.entry.startMinuteOfDay()) / 60.0 * hourHeight
                        let durationMins = CGFloat(item.entry.endMinuteOfDay() - item.entry.startMinuteOfDay())
                        let blockHeight = max(durationMins / 60.0 * hourHeight, 15)
                        
                        let width = availableWidth / CGFloat(item.maxCol)
                        let xOffset = leftPadding + width * CGFloat(item.col)
                        
                        TimelineBlock(entry: item.entry, height: blockHeight)
                            .frame(width: width - 2, height: blockHeight)
                            .offset(x: xOffset, y: yOffset)
                            .onTapGesture {
                                selectedEntry = item.entry
                            }
                    }
                    
                    if Calendar.current.isDateInToday(date) {
                        let curMins = Calendar.current.dateComponents([.hour, .minute], from: Date())
                        let curY = CGFloat((curMins.hour ?? 0) * 60 + (curMins.minute ?? 0)) / 60.0 * hourHeight
                        
                        HStack(spacing: 0) {
                            Circle().fill(Color.red).frame(width: 6, height: 6)
                            Rectangle().fill(Color.red).frame(height: 1)
                        }
                        .padding(.leading, 45)
                        .offset(y: curY - 3)
                        .zIndex(2)
                    }
                }
                .frame(height: hourHeight * 24)
            }
            .padding(.trailing, 10)
            .padding(.top, 10)
        }
    }
}

// MARK: - AppleWeekTimelineView
struct AppleWeekTimelineView: View {
    var viewModel: TimeTrackingViewModel
    var date: Date
    @Binding var selectedEntry: TimeEntry?
    
    let hourHeight: CGFloat = 40
    
    var body: some View {
        let startOfWeek = DateHelper.startOfWeek(date)
        let weekDays = (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startOfWeek) }
        
        ScrollView(.vertical, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: 0) {
                    Text("").frame(height: 20)
                    ForEach(0..<24) { hour in
                        Text("\(hour):00")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .frame(width: 25, height: hourHeight, alignment: .bottom)
                    }
                }
                
                ForEach(weekDays, id: \.self) { day in
                    VStack(spacing: 0) {
                        Text(dayHeader(day))
                            .font(.system(size: 12))
                            .foregroundColor(Calendar.current.isDateInToday(day) ? .blue : .primary)
                            .padding(.bottom, 5)
                        
                        ZStack(alignment: .topLeading) {
                            VStack(spacing: 0) {
                                ForEach(0..<24) { _ in
                                    Rectangle()
                                        .strokeBorder(Color.gray.opacity(0.1), lineWidth: 0.5)
                                        .frame(height: hourHeight)
                                }
                            }
                            
                            let entries = viewModel.entries(for: day)
                            let layoutItems = TimelineLayoutEngine.layout(entries: entries)
                            
                            GeometryReader { geo in
                                let availableWidth = geo.size.width
                                ForEach(Array(layoutItems.enumerated()), id: \.element.entry.id) { index, item in
                                    let yOffset = CGFloat(item.entry.startMinuteOfDay()) / 60.0 * hourHeight
                                    let dMins = CGFloat(item.entry.endMinuteOfDay() - item.entry.startMinuteOfDay())
                                    let height = max(dMins / 60.0 * hourHeight, 10)
                                    let width = availableWidth / CGFloat(item.maxCol)
                                    let xOff = width * CGFloat(item.col)
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(item.entry.category.color.opacity(0.8))
                                        .frame(width: width - 2, height: height)
                                        .offset(x: xOff, y: yOffset)
                                        .onTapGesture {
                                            selectedEntry = item.entry
                                        }
                                }
                            }
                            .frame(height: hourHeight * 24)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.trailing, 5)
        }
    }
    
    func dayHeader(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "E\nd"
        return f.string(from: date)
    }
}

// MARK: - AppleMonthCalendarView
struct AppleMonthCalendarView: View {
    var viewModel: TimeTrackingViewModel
    var date: Date
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack {
            let days = stride(from: 0, to: 7, by: 1).map {
                Calendar.current.date(byAdding: .day, value: $0, to: DateHelper.startOfWeek(Date()))!
            }
            HStack {
                ForEach(days, id: \.self) { d in
                    Text(d.formatted(.dateTime.weekday(.short)))
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 10)
            
            let monthDays = getDaysInMonth()
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(0..<monthDays.count, id: \.self) { index in
                    if let d = monthDays[index] {
                        MonthDayCell(date: d, entries: viewModel.entries(for: d))
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }
    
    func getDaysInMonth() -> [Date?] {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: date)
        comps.day = 1
        let firstDay = cal.date(from: comps)!
        let range = cal.range(of: .day, in: .month, for: firstDay)!
        let startWeekday = cal.component(.weekday, from: firstDay) - cal.firstWeekday
        let adjustedStart = startWeekday < 0 ? startWeekday + 7 : startWeekday
        var result: [Date?] = Array(repeating: nil, count: adjustedStart)
        for i in 1...range.count {
            if let d = cal.date(byAdding: .day, value: i - 1, to: firstDay) {
                result.append(d)
            }
        }
        return result
    }
}

struct MonthDayCell: View {
    var date: Date
    var entries: [TimeEntry]
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14))
                .foregroundColor(Calendar.current.isDateInToday(date) ? .white : .primary)
                .background(
                    Circle().fill(Calendar.current.isDateInToday(date) ? Color.blue : Color.clear)
                        .frame(width: 25, height: 25)
                )
            
            HStack(spacing: 2) {
                let uniqueCategories = Array(Set(entries.map { $0.category })).prefix(3)
                ForEach(uniqueCategories, id: \.rawValue) { cat in
                    Circle()
                        .fill(cat.color)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 5)
        }
        .frame(height: 40)
    }
}

// MARK: - AppleYearHeatmapView
struct AppleYearHeatmapView: View {
    var viewModel: TimeTrackingViewModel
    var date: Date
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(1...12, id: \.self) { month in
                    MonthHeatmap(viewModel: viewModel, yearDate: date, month: month)
                }
            }
            .padding()
        }
    }
}

struct MonthHeatmap: View {
    var viewModel: TimeTrackingViewModel
    var yearDate: Date
    var month: Int
    
    var body: some View {
        let rows = Array(repeating: GridItem(.fixed(6), spacing: 2), count: 6)
        
        VStack(alignment: .leading, spacing: 4) {
            Text("\(month)月")
                .font(.system(size: 10, weight: .bold))
            
            let days = getMonthDays(month: month)
            LazyHGrid(rows: rows, spacing: 2) {
                ForEach(0..<days.count, id: \.self) { index in
                    if let d = days[index] {
                        let count = viewModel.entries(for: d).count
                        RoundedRectangle(cornerRadius: 1)
                            .fill(heatmapColor(count: count))
                            .frame(width: 6, height: 6)
                    } else {
                        Color.clear.frame(width: 6, height: 6)
                    }
                }
            }
        }
        .frame(height: 80)
    }
    
    func heatmapColor(count: Int) -> Color {
        if count == 0 { return Color.gray.opacity(0.1) }
        if count <= 2 { return Color.blue.opacity(0.3) }
        if count <= 5 { return Color.blue.opacity(0.6) }
        return Color.blue
    }
    
    func getMonthDays(month: Int) -> [Date?] {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year], from: yearDate)
        comps.month = month
        comps.day = 1
        guard let firstDay = cal.date(from: comps) else { return [] }
        let range = cal.range(of: .day, in: .month, for: firstDay)!
        let start = (cal.component(.weekday, from: firstDay) - cal.firstWeekday + 7) % 7
        var result: [Date?] = Array(repeating: nil, count: start)
        for i in 1...range.count {
            result.append(cal.date(byAdding: .day, value: i - 1, to: firstDay))
        }
        return result
    }
}

// MARK: - TimelineBlock
struct TimelineBlock: View {
    var entry: TimeEntry
    var height: CGFloat
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(entry.category.color.opacity(0.2))
            
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(entry.category.color.opacity(0.5), lineWidth: 1)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.category.rawValue)
                    .font(.caption)
                    .bold()
                    .foregroundColor(entry.category.color)
                    .lineLimit(1)
                if height > 30 {
                    Text(entry.subCategory ?? "")
                        .font(.caption2)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            }
            .padding(4)
        }
    }
}
