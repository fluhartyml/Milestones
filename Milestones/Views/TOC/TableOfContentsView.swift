//
//  TableOfContentsView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import SwiftData

/// The front of the journal — auto-generated table of contents grouped by month/year.
struct TableOfContentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MilestoneEntry.eventDate, order: .reverse) private var entries: [MilestoneEntry]

    @State private var showingEntry = false
    @State private var activeEntry: MilestoneEntry?

    private let locationService = LocationService()
    private let weatherService = WeatherService()

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    tocList
                }
            }
            .navigationTitle("Contents")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        createNewEntry()
                    } label: {
                        Label("New Entry", systemImage: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingEntry) {
                if let entry = activeEntry {
                    NavigationStack {
                        EntryDetailView(entry: entry)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") {
                                        showingEntry = false
                                    }
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

    // MARK: - Grouped entries by month/year

    private var groupedEntries: [(String, [MilestoneEntry])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM"

        let grouped = Dictionary(grouping: entries) { entry in
            formatter.string(from: entry.eventDate).uppercased()
        }

        return grouped.sorted { a, b in
            a.key > b.key
        }
    }

    // MARK: - Subviews

    private var tocList: some View {
        List {
            ForEach(groupedEntries, id: \.0) { section, sectionEntries in
                Section(section) {
                    ForEach(sectionEntries) { entry in
                        Button {
                            activeEntry = entry
                            showingEntry = true
                        } label: {
                            tocRow(entry)
                        }
                        .tint(.primary)
                    }
                }
            }
        }
    }

    private func tocRow(_ entry: MilestoneEntry) -> some View {
        HStack(spacing: 10) {
            if entry.isMilestone {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.eventDate.filingStamp)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)

                Text(entry.title.isEmpty ? "Untitled" : entry.title)
                    .font(.subheadline)
                    .lineLimit(1)
            }

            Spacer()

            if !entry.activeSenses.isEmpty {
                Text("\(entry.activeSenses.count)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(.secondary))
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Entries Yet", systemImage: "list.bullet")
        } description: {
            Text("Your table of contents will build itself as you add journal entries.")
        }
    }

    // MARK: - Actions

    private func createNewEntry() {
        let entry = MilestoneEntry(
            eventDate: Date(),
            title: ""
        )
        modelContext.insert(entry)

        locationService.requestLocation()
        Task {
            try? await Task.sleep(for: .seconds(1))
            await locationService.stampEntry(entry)
            if let location = locationService.currentLocation {
                await weatherService.stampWeather(on: entry, at: location)
            }
        }

        activeEntry = entry
        showingEntry = true
    }
}
