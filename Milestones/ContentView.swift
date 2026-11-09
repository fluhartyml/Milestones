//
//  ContentView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import SwiftData

/// Root tab navigator — like a physical book: TOC, Journal, About, Appendix.
struct ContentView: View {

    // REM: line 002.1 — the name is asked once, at first launch, over the journal (NameAskView).
    @AppStorage(UserNameKeys.asked) private var askedForName = false
    // REM: line 010.2 — the lock is offered right after the name, once (JournalLock.swift).
    @AppStorage(JournalLockKeys.asked) private var askedForLock = false
    // REM: amber B-031 — the Microphone card follows the lock card, once (MicrophoneOfferView).
    @AppStorage(MicrophoneAccess.askedKey) private var askedForMicrophone = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        tabs
            .sheet(isPresented: Binding(get: { !askedForName }, set: { _ in })) {
                NameAskView()
            }
            .sheet(isPresented: Binding(get: { askedForName && !askedForLock }, set: { _ in })) {
                LockOfferView()
            }
            .sheet(isPresented: Binding(get: { askedForName && askedForLock && !askedForMicrophone }, set: { _ in })) {
                MicrophoneOfferView()
            }
            // REM: line 010.1 — the journal hides when you leave and opens with Face ID (JournalLock.swift).
            .journalLock()
            // REM: line 032.2 — the reminder's repeats are rebuilt each time you come back (a new day, a written entry).
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await ReminderService.refresh() } }
            }
    }

    private var tabs: some View {
        TabView {
            TableOfContentsView()
                .tabItem {
                    Label("Contents", systemImage: "list.bullet")
                }

            JournalTimelineView()
                .tabItem {
                    Label("Journal", systemImage: "book")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }

            AppendixView()
                .tabItem {
                    Label("Appendix", systemImage: "star")
                }

            // REM: line 001.12 — Settings holds Access Location. On the Mac it is the Settings
            // window (Command-comma) instead, see MilestonesApp.
            #if !os(macOS)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
            #endif
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MilestoneEntry.self, inMemory: true)
}
