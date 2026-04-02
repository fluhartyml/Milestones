//
//  EntryDetailView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI

/// Full detail view for a single journal entry.
struct EntryDetailView: View {
    @Bindable var entry: MilestoneEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Header

                VStack(alignment: .leading, spacing: 8) {
                    DateStampView(date: entry.eventDate)

                    Text(entry.title)
                        .font(.title.bold())

                    HStack(spacing: 12) {
                        if let location = entry.locationName {
                            Label(location, systemImage: "location.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        WeatherBadgeView(entry: entry)
                    }
                }

                Divider()

                // MARK: - Photos (Sight)

                if let photos = entry.sightPhotos, !photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(photos.indices, id: \.self) { index in
                                if let uiImage = platformImage(from: photos[index]) {
                                    Image(platformImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                }

                // MARK: - Body Text

                if !entry.body.isEmpty {
                    Text(entry.body)
                        .font(.body)
                }

                // MARK: - Senses Detail

                if !entry.activeSenses.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Senses")
                            .font(.headline)

                        // Touch
                        if let touch = entry.touchDescription, !touch.isEmpty {
                            senseRow(type: .touch, text: touch)
                        }

                        // Smell
                        if let smell = entry.smellDescription, !smell.isEmpty {
                            senseRow(type: .smell, text: smell)
                        }

                        // Taste
                        if let taste = entry.tasteDescription, !taste.isEmpty {
                            senseRow(type: .taste, text: taste)
                        }
                    }
                }

                // MARK: - Weather Detail

                if entry.hasWeather {
                    weatherDetailSection
                }

                // MARK: - Milestone Toggle

                Toggle(isOn: $entry.isMilestone) {
                    Label("Add as Significant to Appendix", systemImage: "star.fill")
                }
                .tint(.orange)

                Spacer()
            }
            .padding()
        }
        .navigationTitle(entry.filingName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Subviews

    private func senseRow(type: SenseType, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: type.icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading) {
                Text(type.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.subheadline)
            }
        }
    }

    @ViewBuilder
    private var weatherDetailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weather")
                .font(.headline)

            HStack(spacing: 16) {
                if let temp = entry.weatherTemperature {
                    Label("\(Int(temp))°F", systemImage: "thermometer.medium")
                }
                if let humidity = entry.weatherHumidity {
                    Label("\(Int(humidity))%", systemImage: "humidity.fill")
                }
                if let wind = entry.weatherWindSpeed {
                    Label("\(Int(wind)) mph", systemImage: "wind")
                }
                if let uv = entry.weatherUVIndex {
                    Label("UV \(uv)", systemImage: "sun.max.fill")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            WeatherAttributionView()
        }
    }

    // MARK: - Platform Image Helper

    #if os(macOS)
    private func platformImage(from data: Data) -> NSImage? {
        NSImage(data: data)
    }
    #else
    private func platformImage(from data: Data) -> UIImage? {
        UIImage(data: data)
    }
    #endif
}

// MARK: - Platform Image Extension

#if os(macOS)
extension Image {
    init(platformImage: NSImage) {
        self.init(nsImage: platformImage)
    }
}
#else
extension Image {
    init(platformImage: UIImage) {
        self.init(uiImage: platformImage)
    }
}
#endif
