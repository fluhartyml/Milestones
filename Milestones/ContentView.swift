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

    var body: some View {
        tabs
            .sheet(isPresented: Binding(get: { !askedForName }, set: { _ in })) {
                NameAskView()
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
