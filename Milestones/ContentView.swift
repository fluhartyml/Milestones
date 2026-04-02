//
//  ContentView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import SwiftData

/// Root tab navigator — front of journal (timeline) and back of journal (index). (9.1, 9.2)
struct ContentView: View {

    var body: some View {
        TabView {
            JournalTimelineView()
                .tabItem {
                    Label("Journal", systemImage: "book")
                }

            IndexView()
                .tabItem {
                    Label("Index", systemImage: "star")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MilestoneEntry.self, inMemory: true)
}
