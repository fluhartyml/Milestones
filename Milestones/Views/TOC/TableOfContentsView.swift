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
    // REM: HIS TESTFLIGHT FEEDBACK, build 21, 2026-11-08 06:43: the home page is "one button with an emoji and a plus
    // REM: that asks how are you feeling" → the scale of faces (MoodPickerView) → the face picked starts the entry.
    // REM: It replaces the toolbar "+"; the entry opens only after the faces sheet has closed (onDismiss), because
    // REM: SwiftUI drops a cover presented while another sheet is still leaving.
    @State private var showingFeelings = false
    @State private var pickedMood: Mood?
    @ScaledMetric(relativeTo: .title2) private var askSize: CGFloat = 24
    @ScaledMetric(relativeTo: .largeTitle) private var faceSize: CGFloat = 40
    @ScaledMetric(relativeTo: .body) private var rowSize: CGFloat = 18

    private let locationService = LocationService()
    private let weatherService = WeatherService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                feelingButton
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                Group {
                    if entries.isEmpty {
                        emptyState
                    } else {
                        tocList
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .navigationTitle("Contents")
            .sheet(isPresented: $showingFeelings, onDismiss: {
                if let mood = pickedMood {
                    pickedMood = nil
                    createNewEntry(mood: mood)
                }
            }) {
                MoodPickerView { pickedMood = $0 }
            }
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

    /// The one button on the home page: a face with a plus, asking how you feel.
    private var feelingButton: some View {
        Button {
            showingFeelings = true
        } label: {
            HStack(spacing: 16) {
                Text("🙂")
                    .font(.system(size: faceSize))
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: faceSize * 0.45))
                            .foregroundStyle(.white, .green)
                            .offset(x: 6, y: 6)
                    }
                Text("How are you feeling?")
                    .font(.system(size: askSize, weight: .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 22).fill(Color.green.opacity(0.18)))
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("How are you feeling?")
        .accessibilityHint("Pick a face to start a new entry")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("newEntry")
        .keyboardShortcut("n", modifiers: .command)
    }

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
            if let feeling = entry.feeling {
                Text(feeling.emoji)
                    .accessibilityLabel(feeling.name)
            }
            // REM: amber B-183.8 — the star is off list rows (the Appendix is gone; isMilestone stays stored).
            // F-M2, "yes drop it" — the gray "2026 NOV 07 0933" stamp is gone; the date is in words.
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.eventDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()))
                    .font(.system(size: rowSize))
                    .foregroundStyle(.secondary)

                Text(entry.title.isEmpty ? "Untitled" : entry.title)
                    .font(.system(size: rowSize, weight: .semibold))
                    .lineLimit(1)
            }

            Spacer()

            if !entry.senseIDsUsed.isEmpty {
                Text("\(entry.senseIDsUsed.count)")
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

    private func createNewEntry(mood: Mood) {
        let entry = MilestoneEntry(
            eventDate: Date(),
            title: ""
        )
        entry.feeling = mood
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
