//
//  ContentView.swift
//  TimeTracker
//
//  保留文件兼容性，重定向到 MainTabView
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TimeEntry.self, inMemory: true)
}
