//
//  ComposeEntryView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import SwiftData
import PhotosUI

/// The compose sheet for creating a new journal entry. (1.0.3, 7.1)
struct ComposeEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Core Fields

    @State private var title = ""
    @State private var bodyText = ""
    @State private var eventDate = Date()
    @State private var isMilestone = false

    // MARK: - Senses

    @State private var activeSenses: Set<SenseType> = []

    // Sight
    @State private var sightPhotoItems: [PhotosPickerItem] = []
    @State private var sightPhotoData: [Data] = []

    // Touch
    @State private var touchDescription = ""

    // Smell
    @State private var smellDescription = ""
    @State private var smellPhotoItem: PhotosPickerItem?
    @State private var smellPhotoData: Data?

    // Taste
    @State private var tasteDescription = ""
    @State private var tastePhotoItem: PhotosPickerItem?
    @State private var tastePhotoData: Data?

    // MARK: - Services

    private let locationService = LocationService()
    private let weatherService = WeatherService()

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Core Section

                Section("Entry") {
                    TextField("Title", text: $title)

                    DatePicker("Date", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])

                    TextField("Write about this moment...", text: $bodyText, axis: .vertical)
                        .lineLimit(4...12)
                }

                // MARK: - Senses Section

                Section("Senses") {
                    SensePicker(activeSenses: $activeSenses)
                        .padding(.vertical, 4)
                }

                // MARK: - Active Sense Inputs

                if activeSenses.contains(.sight) {
                    Section {
                        SightInputView(
                            selectedPhotos: $sightPhotoItems,
                            photoData: $sightPhotoData
                        )
                    }
                }

                if activeSenses.contains(.touch) {
                    Section {
                        TouchInputView(description: $touchDescription)
                    }
                }

                if activeSenses.contains(.smell) {
                    Section {
                        SmellInputView(
                            description: $smellDescription,
                            photoItem: $smellPhotoItem,
                            photoData: $smellPhotoData
                        )
                    }
                }

                if activeSenses.contains(.taste) {
                    Section {
                        TasteInputView(
                            description: $tasteDescription,
                            photoItem: $tastePhotoItem,
                            photoData: $tastePhotoData
                        )
                    }
                }

                // MARK: - Milestone Toggle (1.0.18)

                Section {
                    Toggle(isOn: $isMilestone) {
                        Label("Add to Index", systemImage: "star.fill")
                    }
                    .tint(.orange)
                }
            }
            .navigationTitle("New Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEntry() }
                        .disabled(title.isEmpty)
                }
            }
            .onAppear {
                locationService.requestPermission()
                locationService.requestLocation()
            }
        }
    }

    // MARK: - Save

    private func saveEntry() {
        let entry = MilestoneEntry(
            eventDate: eventDate,
            title: title,
            body: bodyText,
            isMilestone: isMilestone
        )

        // Senses
        entry.activeSenses = activeSenses.map(\.rawValue)

        // Sight
        if !sightPhotoData.isEmpty {
            entry.sightPhotos = sightPhotoData
        }

        // Touch
        if !touchDescription.isEmpty {
            entry.touchDescription = touchDescription
        }

        // Smell
        if !smellDescription.isEmpty {
            entry.smellDescription = smellDescription
        }
        entry.smellPhoto = smellPhotoData

        // Taste
        if !tasteDescription.isEmpty {
            entry.tasteDescription = tasteDescription
        }
        entry.tastePhoto = tastePhotoData

        // Insert first so SwiftData tracks it
        modelContext.insert(entry)

        // Location + Weather (async, stamps after insert)
        Task {
            await locationService.stampEntry(entry)

            if let location = locationService.currentLocation {
                await weatherService.stampWeather(on: entry, at: location)
            }
        }

        dismiss()
    }
}
