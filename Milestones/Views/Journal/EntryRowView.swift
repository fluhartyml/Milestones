//
//  EntryRowView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI

/// A single row in the journal timeline list.
struct EntryRowView: View {
    let entry: MilestoneEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Filing timestamp
            HStack {
                DateStampView(date: entry.eventDate)

                Spacer()

                if entry.isMilestone {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            // Title
            Text(entry.title)
                .font(.headline)
                .lineLimit(1)

            // Body preview
            if !entry.body.isEmpty {
                Text(entry.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Bottom row: senses + weather + location
            HStack(spacing: 12) {
                SenseIconsView(activeSenses: entry.activeSenses)

                WeatherBadgeView(entry: entry)

                Spacer()

                if let location = entry.locationName {
                    HStack(spacing: 2) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(location)
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
