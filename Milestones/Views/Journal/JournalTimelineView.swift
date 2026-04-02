//
//  JournalTimelineView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import SwiftData

/// The front of the journal — a chronological timeline of all entries. (9.1)
struct JournalTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MilestoneEntry.eventDate, order: .reverse) private var entries: [MilestoneEntry]
    @State private var showingCompose = false

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCompose = true
                    } label: {
                        Label("New Entry", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCompose) {
                ComposeEntryView()
            }
        }
    }

    // MARK: - Subviews

    private var entryList: some View {
        List {
            ForEach(entries) { entry in
                NavigationLink(destination: EntryDetailView(entry: entry)) {
                    EntryRowView(entry: entry)
                }
            }
            .onDelete(perform: deleteEntries)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Entries Yet", systemImage: "book")
        } description: {
            Text("Tap + to capture your first milestone.")
        }
    }

    // MARK: - Actions

    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
        }
    }
}
