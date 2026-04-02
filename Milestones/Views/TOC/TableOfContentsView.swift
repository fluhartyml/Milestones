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
    @Query(sort: \MilestoneEntry.eventDate, order: .reverse) private var entries: [MilestoneEntry]

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
            // Sort sections reverse chronological
            a.key > b.key
        }
    }

    // MARK: - Subviews

    private var tocList: some View {
        List {
            ForEach(groupedEntries, id: \.0) { section, sectionEntries in
                Section(section) {
                    ForEach(sectionEntries) { entry in
                        NavigationLink(destination: EntryDetailView(entry: entry)) {
                            tocRow(entry)
                        }
                    }
                }
            }
        }
    }

    private func tocRow(_ entry: MilestoneEntry) -> some View {
        HStack(spacing: 10) {
            // Milestone star
            if entry.isMilestone {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                // Filing stamp
                Text(entry.eventDate.filingStamp)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)

                // Title
                Text(entry.title)
                    .font(.subheadline)
                    .lineLimit(1)
            }

            Spacer()

            // Sense count badge
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
}
