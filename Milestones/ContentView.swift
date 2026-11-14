//
//  ContentView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import SwiftData

/// Root tab navigator — like a physical book: TOC, Journal, About, Index.
struct ContentView: View {

    // REM: line 002.1 — the name is asked once, at first launch, over the journal (NameAskView).
    @AppStorage(UserNameKeys.asked) private var askedForName = false
    // REM: line 010.2 — the lock is offered right after the name, once (JournalLock.swift).
    @AppStorage(JournalLockKeys.asked) private var askedForLock = false
    // REM: amber B-031 — the Microphone card follows the lock card, once (MicrophoneOfferView).
    @AppStorage(MicrophoneAccess.askedKey) private var askedForMicrophone = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    /// The tab showing. Contents first, as before.
    @State private var tab: MainTab = .contents
    /// REM: amber B-031.3 / B-031.5 — the newest entry made from a share, waiting for the Journal tab to open it.
    @State private var sharedEntry: MilestoneEntry?

    private enum MainTab: Hashable { case contents, journal, about, index, settings }

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
            // REM: line 010.1 — the journal hides when you leave and opens with biometric authorization (JournalLock.swift).
            .journalLock()
            // REM: line 032.2 — the reminder's repeats are rebuilt each time you come back (a new day, a written entry).
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    takeShares()
                    Task { await ReminderService.refresh() }
                }
            }
            .task { takeShares() }
    }

    /// REM: amber B-031.3 — shared text "opens it as a new entry for the person to edit and save"; B-031.5 — shared
    /// photos arrive as "the photo stack" with what you wrote about them. Every share waiting in the inbox becomes a
    /// saved entry (ShareInbox+Import.swift); the Journal tab comes forward and opens the newest one to edit.
    private func takeShares() {
        guard let entry = ShareInbox.takeAll(into: modelContext) else { return }
        tab = .journal
        sharedEntry = entry
        // REM: line 032.2 — an entry written today stops today's reminder repeats, the same as one made with +.
        if Calendar.current.isDateInToday(entry.createdAt) {
            Task { await ReminderService.entryWritten() }
        }
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            TableOfContentsView()
                .tabItem {
                    Label("Contents", systemImage: "list.bullet")
                }
                .tag(MainTab.contents)

            JournalTimelineView(sharedEntry: $sharedEntry)
                .tabItem {
                    Label("Journal", systemImage: "book")
                }
                .tag(MainTab.journal)

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(MainTab.about)

            // REM: amber B-183.8, his word 2026-11-09 19:3x: "yes replace it with the index index sounds more natural."
            // "The Appendix goes; an Index by sense and glyph takes its place". Same place in the tab bar.
            IndexTab()
                .tabItem {
                    Label("Index", systemImage: "list.bullet.indent")
                }
                .tag(MainTab.index)

            // REM: line 001.12 — Settings holds Access Location. On the Mac it is the Settings
            // window (Command-comma) instead, see MilestonesApp.
            #if !os(macOS)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(MainTab.settings)
            #endif
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MilestoneEntry.self, inMemory: true)
}
