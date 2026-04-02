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
    @State private var editingEntry: MilestoneEntry?

    private let locationService = LocationService()
    private let weatherService = WeatherService()

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
                        createNewEntry()
                    } label: {
                        Label("New Entry", systemImage: "plus")
                    }
                }
            }
            .fullScreenCover(item: $editingEntry) { entry in
                NavigationStack {
                    EntryDetailView(entry: entry)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    editingEntry = nil
                                }
                            }
                        }
                }
            }
            .onAppear {
                locationService.requestPermission()
            }
        }
    }

    // MARK: - Subviews

    private var entryList: some View {
        List {
            ForEach(entries) { entry in
                Button {
                    editingEntry = entry
                } label: {
                    EntryRowView(entry: entry)
                }
                .tint(.primary)
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

    private func createNewEntry() {
        let entry = MilestoneEntry(
            eventDate: Date(),
            title: ""
        )
        modelContext.insert(entry)

        // Stamp location + weather
        locationService.requestLocation()
        Task {
            try? await Task.sleep(for: .seconds(1))
            await locationService.stampEntry(entry)
            if let location = locationService.currentLocation {
                await weatherService.stampWeather(on: entry, at: location)
            }
        }

        // Open the entry full screen
        editingEntry = entry
    }

    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
        }
    }
}
