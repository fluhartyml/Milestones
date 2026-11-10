//
//  MilestonesApp.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct MilestonesApp: App {
    init() {
        // REM: line 032.1 — the reminder's Snooze / Keep Reminding Me buttons are answered by ReminderDelegate.
        UNUserNotificationCenter.current().delegate = ReminderDelegate.shared
        ReminderService.registerCategories()
        #if DEBUG
        // REM: the robot's "first launch" switch (line 002.1): clears the name so the ask shows again.
        // Debug builds only — a TestFlight or App Store build never reads it.
        if ProcessInfo.processInfo.arguments.contains("-UITestFreshStart") {
            UserDefaults.standard.removeObject(forKey: UserNameKeys.name)
            UserDefaults.standard.removeObject(forKey: UserNameKeys.asked)
            UserDefaults.standard.removeObject(forKey: JournalLockKeys.asked)
            UserDefaults.standard.removeObject(forKey: JournalLockKeys.on)
            UserDefaults.standard.removeObject(forKey: MicrophoneAccess.askedKey)
        }
        #endif
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MilestoneEntry.self,
            // REM: amber B-183.2 — addenda (sub-entries), new in this build; optional, so older stores open unchanged.
            Addendum.self,
            // REM: amber B-183.7.3 — glyphs stamped on an entry like stickers; optional, so older stores open unchanged.
            EntrySticker.self,
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
