//
//  AboutView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI

/// About screen with credits, attributions, and compliance. Easter egg included.
struct AboutView: View {

    var body: some View {
        NavigationStack {
            List {
                // MARK: - App Identity

                Section {
                    VStack(spacing: 8) {
                        Image("AppIcon")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18))

                        Text("Milestones")
                            .font(.title.bold())

                        Text("Because your life isn't one moment — it's all of them.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Text("v1.0")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }

                // MARK: - Credits

                Section("Credits") {
                    creditRow(
                        title: "Developed by",
                        detail: "Michael Lee Fluharty"
                    )

                    creditRow(
                        title: "Engineered with",
                        detail: "Claude by Anthropic"
                    )

                    creditRow(
                        title: "License",
                        detail: "GPL v3 — Share and share alike with attribution required"
                    )
                }

                // MARK: - Data Sources & Attributions

                Section("Data Sources") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "cloud.sun.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Apple Weather")
                                    .font(.subheadline.bold())
                                Text("Current and historical weather conditions powered by Apple WeatherKit.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                WeatherAttributionView()
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    attributionRow(
                        icon: "location.fill",
                        title: "Apple CoreLocation",
                        detail: "Location services provided by Apple CoreLocation.",
                        footnote: "Geotag and reverse geocoding for every journal entry."
                    )

                    attributionRow(
                        icon: "photo.on.rectangle",
                        title: "Apple PhotosUI",
                        detail: "Photo access provided by Apple PhotosUI.",
                        footnote: "Camera roll access for Sight, Smell, and Taste senses."
                    )
                }

                Section("Coming in Future Versions") {
                    attributionRow(
                        icon: "shazam.logo",
                        title: "Apple ShazamKit",
                        detail: "Song identification powered by Shazam.",
                        footnote: "Identify songs playing around you. Coming in v1.1."
                    )

                    attributionRow(
                        icon: "music.note",
                        title: "Apple MusicKit",
                        detail: "Music playback powered by Apple Music.",
                        footnote: "Play Shazam-identified songs from your journal. Coming in v1.1."
                    )

                    attributionRow(
                        icon: "heart.fill",
                        title: "Apple HealthKit",
                        detail: "Health data provided by Apple HealthKit.",
                        footnote: "Steps, heart rate, activity, and workout data from Apple Watch. Coming in v1.1."
                    )

                    attributionRow(
                        icon: "calendar",
                        title: "Apple EventKit",
                        detail: "Calendar integration provided by Apple EventKit.",
                        footnote: "Import holidays and contact birthdays as milestones. Coming in v1.4."
                    )

                    attributionRow(
                        icon: "book.closed",
                        title: "Apple JournalKit",
                        detail: "Journaling suggestions powered by Apple.",
                        footnote: "Smart journaling prompts from iOS. Coming in v1.4."
                    )
                }

                // MARK: - Storage

                Section("Storage & Sync") {
                    attributionRow(
                        icon: "externaldrive.fill",
                        title: "Apple SwiftData",
                        detail: "Local data persistence powered by SwiftData.",
                        footnote: "All journal entries stored on-device."
                    )

                    attributionRow(
                        icon: "icloud.fill",
                        title: "Apple CloudKit",
                        detail: "Cloud sync powered by Apple iCloud.",
                        footnote: "Your journal syncs across all your devices via iCloud."
                    )
                }

                // MARK: - Privacy

                Section("Privacy") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No ads. No tracking. All data stays on your device and in your iCloud.")
                            .font(.subheadline)
                        Text("Milestones never sends your data to third-party servers. Your memories are yours.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("About")
        }
    }

    // MARK: - Row Builders

    private func creditRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(detail)
                .font(.subheadline)
        }
        .padding(.vertical, 2)
    }

    private func attributionRow(icon: String, title: String, detail: String, footnote: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(footnote)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
