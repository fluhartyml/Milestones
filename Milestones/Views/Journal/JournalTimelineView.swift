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

    @State private var showingEntry = false
    // REM: line 002.1 — "greets you by name at the top of the journal". No name, no greeting.
    @AppStorage(UserNameKeys.name) private var userName = ""
    @ScaledMetric(relativeTo: .title3) private var greetingSize: CGFloat = 22
    @State private var activeEntry: MilestoneEntry?
    /// REM: lines 007 / 022.1 — the day ring tapped (WritingRings.swift); nil = every entry.
    @State private var selectedDay: Date?

    /// The days you wrote an entry (by when it was written, not the day it's about).
    private var writtenDays: Set<Date> { Set(entries.map { Calendar.current.startOfDay(for: $0.createdAt) }) }
    private var shownEntries: [MilestoneEntry] {
        guard let day = selectedDay else { return entries }
        return entries.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: day) }
    }

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
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    if !userName.isEmpty {
                        Text("Hello, \(userName)")
                            .font(.system(size: greetingSize, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("greeting")
                    }
                    // REM: lines 007 / 022 / 022.1 — the week of writing rings and the month's ring.
                    WritingRings(writtenDays: writtenDays, selectedDay: $selectedDay)
                }
                .background(.bar)
            }
            .navigationTitle("Journal")
            .toolbar {
                // REM: amber A-023 / A-023.2 — the badge patches (Badges.swift).
                ToolbarItem(placement: .navigation) {
                    NavigationLink { JournalBadgesScreen() } label: {
                        Label("Badges", systemImage: "rosette")
                    }
                    .accessibilityIdentifier("badgesButton")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        createNewEntry()
                    } label: {
                        Label("New Entry", systemImage: "plus")
                    }
                }
            }
            .modifier(JournalBadgeWatcher(entries: entries))
            .entryCover(isPresented: $showingEntry) {
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

    // MARK: - Subviews

    private var entryList: some View {
        List {
            ForEach(shownEntries) { entry in
                Button {
                    activeEntry = entry
                    showingEntry = true
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
        // REM: line 032.2 — writing today's entry stops today's reminder repeats.
        Task { await ReminderService.entryWritten() }

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
        activeEntry = entry
        showingEntry = true
    }

    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(shownEntries[index])
            }
        }
    }
}
