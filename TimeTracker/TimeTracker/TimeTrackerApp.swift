//
//  TimeTrackerApp.swift
//  TimeTracker
//
//  柳比歇夫时间统计法 - App 入口
//

import SwiftUI
import SwiftData

@main
struct TimeTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TimeEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
