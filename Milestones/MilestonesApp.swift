//
//  MilestonesApp.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import SwiftData

@main
struct MilestonesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MilestoneEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)

        #if os(macOS)
        // REM: line 001.12 — Access Location lives in the Mac's Settings window (Command-comma).
        Settings {
            SettingsView()
        }
        #endif
    }
}
