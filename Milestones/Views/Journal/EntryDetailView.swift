//
//  EntryDetailView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import PhotosUI

/// Full detail view for a single journal entry. All fields auto-save via SwiftData.
struct EntryDetailView: View {
    @Bindable var entry: MilestoneEntry

    // MARK: - Photo State

    @State private var sightPhotoItems: [PhotosPickerItem] = []
    @State private var smellPhotoItem: PhotosPickerItem?
    @State private var tastePhotoItem: PhotosPickerItem?

    // Track which senses are active
    @State private var activeSenses: Set<SenseType> = []
    @State private var hasLoadedSenses = false

    var body: some View {
        Form {
            // MARK: - Core

            Section("Entry") {
                TextField("Title", text: $entry.title)

                DatePicker("Date", selection: $entry.eventDate, displayedComponents: [.date, .hourAndMinute])

                TextField("Write about this moment...", text: $entry.body, axis: .vertical)
                    .lineLimit(4...20)
            }

            // MARK: - Filing Stamp

            Section {
                DateStampView(date: entry.eventDate)
            }

            // MARK: - Weather

            if entry.hasWeather {
                Section("Weather") {
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

            // MARK: - Location

            if let location = entry.locationName {
                Section("Location") {
                    Label(location, systemImage: "location.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Senses

            Section("Senses") {
                SensePicker(activeSenses: $activeSenses)
                    .padding(.vertical, 4)
                    .onChange(of: activeSenses) { _, newValue in
                        entry.activeSenses = newValue.map(\.rawValue)
                    }
            }

            // MARK: - Active Sense Inputs

            if activeSenses.contains(.sight) {
                Section {
                    sightSection
                }
            }

            if activeSenses.contains(.touch) {
                Section {
                    TouchInputView(description: Binding(
                        get: { entry.touchDescription ?? "" },
                        set: { entry.touchDescription = $0.isEmpty ? nil : $0 }
                    ))
                }
            }

            if activeSenses.contains(.smell) {
                Section {
                    SmellInputView(
                        description: Binding(
                            get: { entry.smellDescription ?? "" },
                            set: { entry.smellDescription = $0.isEmpty ? nil : $0 }
                        ),
                        photoItem: $smellPhotoItem,
                        photoData: Binding(
                            get: { entry.smellPhoto },
                            set: { entry.smellPhoto = $0 }
                        )
                    )
                }
            }

            if activeSenses.contains(.taste) {
                Section {
                    TasteInputView(
                        description: Binding(
                            get: { entry.tasteDescription ?? "" },
                            set: { entry.tasteDescription = $0.isEmpty ? nil : $0 }
                        ),
                        photoItem: $tastePhotoItem,
                        photoData: Binding(
                            get: { entry.tastePhoto },
                            set: { entry.tastePhoto = $0 }
                        )
                    )
                }
            }

            // MARK: - Appendix Toggle

            Section {
                Toggle(isOn: $entry.isMilestone) {
                    Label("Add as Significant to Appendix", systemImage: "star.fill")
                }
                .tint(.orange)
            }
        }
        .navigationTitle("Entry")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            if !hasLoadedSenses {
                activeSenses = Set(entry.activeSenses.compactMap { SenseType(rawValue: $0) })
                hasLoadedSenses = true
            }
        }
    }

    // MARK: - Sight Section

    @ViewBuilder
    private var sightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sight — What do you see?", systemImage: "eye")
                .font(.subheadline.bold())

            PhotosPicker(
                selection: $sightPhotoItems,
                maxSelectionCount: 5,
                matching: .images
            ) {
                Label("Choose Photos", systemImage: "photo.on.rectangle")
            }
            .onChange(of: sightPhotoItems) { _, newItems in
                Task {
                    var photos: [Data] = []
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            photos.append(data)
                        }
                    }
                    entry.sightPhotos = photos.isEmpty ? nil : photos
                }
            }

            // Show existing photos
            if let photos = entry.sightPhotos, !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(photos.indices, id: \.self) { index in
                            #if os(macOS)
                            if let image = NSImage(data: photos[index]) {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            #else
                            if let image = UIImage(data: photos[index]) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            #endif
                        }
                    }
                }
            }
        }
    }
}
