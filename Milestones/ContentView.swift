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

    var body: some View {
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
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MilestoneEntry.self, inMemory: true)
}
