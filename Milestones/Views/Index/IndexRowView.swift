//
//  IndexRowView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI

/// A single row in the milestone index. (4.3)
struct IndexRowView: View {
    let entry: MilestoneEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Filing date
            DateStampView(date: entry.eventDate)

            // Title
            Text(entry.title)
                .font(.headline)

            // Weather + location
            HStack(spacing: 12) {
                WeatherBadgeView(entry: entry)

                if let location = entry.locationName {
                    HStack(spacing: 2) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(location)
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }

                Spacer()

                SenseIconsView(activeSenses: entry.activeSenses)
            }
        }
        .padding(.vertical, 4)
    }
}
