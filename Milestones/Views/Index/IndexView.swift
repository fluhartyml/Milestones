//
//  IndexView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import SwiftData

/// The back of the journal — the milestone index. (4.1, 9.2)
struct IndexView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<MilestoneEntry> { $0.isMilestone },
        sort: \MilestoneEntry.eventDate,
        order: .reverse
    ) private var milestones: [MilestoneEntry]

    @State private var showingAddMilestone = false

    var body: some View {
        NavigationStack {
            Group {
                if milestones.isEmpty {
                    emptyState
                } else {
                    milestoneList
                }
            }
            .navigationTitle("Index")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddMilestone = true
                    } label: {
                        Label("Add Milestone", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMilestone) {
                AddMilestoneView()
            }
        }
    }

    // MARK: - Subviews

    private var milestoneList: some View {
        List {
            ForEach(milestones) { milestone in
                NavigationLink(destination: EntryDetailView(entry: milestone)) {
                    IndexRowView(entry: milestone)
                }
            }
            .onDelete(perform: deleteMilestones)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Milestones Yet", systemImage: "star")
        } description: {
            Text("Add significant dates to build your life's index.")
        }
    }

    // MARK: - Actions

    private func deleteMilestones(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                // Remove milestone flag, don't delete the entry
                milestones[index].isMilestone = false
            }
        }
    }
}
