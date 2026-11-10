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
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .headline) private var headingSize: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // REM: amber B-183.8, his word 2026-11-09: "yes replace it with the index" — the star comes off (the
            // Appendix is gone; isMilestone stays stored). F-M2, "yes drop it": the gray "2026 NOV 07 0933" stamp is
            // gone from the app; the row says the date in words instead, like the entry's Date card.
            Text(entry.eventDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year().hour().minute()))
                .font(.system(size: bodySize))
                .foregroundStyle(.secondary)

            // Title
            // REM: MF-004, his words: "Should never be an 'untitled' entry" — the shown title comes from the entry.
            Text(entry.displayTitle)
                .font(.system(size: headingSize, weight: .semibold))
                .lineLimit(1)

            // Body preview
            if !entry.body.isEmpty {
                Text(entry.body)
                    .font(.system(size: bodySize))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Bottom row: senses + weather + location
            HStack(spacing: 12) {
                SenseIconsView(activeSenses: entry.senseIDsUsed)

                WeatherBadgeView(entry: entry)

                Spacer()

                if let location = entry.locationName {
                    HStack(spacing: 2) {
                        // REM: MF-005, his words: "Should be a location pin" — a map pin, not the location arrow.
                        Image(systemName: "mappin")
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
