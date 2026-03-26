//
//  MainTabView.swift
//  TimeTracker
//
//  主 Tab 导航视图
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TimeTrackingViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TimerView(viewModel: viewModel)
                .tabItem {
                    Label("计时", systemImage: "timer")
                }
                .tag(0)

            CalendarBlockView(viewModel: viewModel)
                .tabItem {
                    Label("日历", systemImage: "calendar")
                }
                .tag(1)

            DailySummaryView(viewModel: viewModel)
                .tabItem {
                    Label("日报", systemImage: "chart.bar.fill")
                }
                .tag(2)

            WeeklyReviewView(viewModel: viewModel)
                .tabItem {
                    Label("周报", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)

            MonthlyLedgerView(viewModel: viewModel)
                .tabItem {
                    Label("月报", systemImage: "book.closed.fill")
                }
                .tag(4)

            YearlyLedgerView(viewModel: viewModel)
                .tabItem {
                    Label("年报", systemImage: "chart.bar.doc.horizontal")
                }
                .tag(5)
        }
        .onAppear {
            viewModel.setup(context: modelContext)
        }
    }
}
