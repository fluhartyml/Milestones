//
//  AddMilestoneView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import SwiftData

/// Quick-add a milestone directly to the index. (4.2, 4.6, 4.7)
struct AddMilestoneView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var eventDate = Date()
    @State private var bodyText = ""

    private let weatherService = WeatherService()
    private let locationService = LocationService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Milestone") {
                    TextField("Title", text: $title)

                    DatePicker("Date", selection: $eventDate, displayedComponents: [.date])

                    TextField("Description (optional)", text: $bodyText, axis: .vertical)
                        .lineLimit(2...6)
                }

                // Suggestions (4.4)
                Section("Suggestions") {
                    ForEach(AppConstants.suggestedMilestones, id: \.title) { suggestion in
                        Button {
                            title = suggestion.title
                            bodyText = suggestion.description
                        } label: {
                            VStack(alignment: .leading) {
                                Text(suggestion.title)
                                    .font(.subheadline.bold())
                                Text(suggestion.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(.primary)
                    }
                }
            }
            .navigationTitle("Add Milestone")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveMilestone() }
                        .disabled(title.isEmpty)
                }
            }
            .onAppear {
                locationService.requestPermission()
                locationService.requestLocation()
            }
        }
    }

    private func saveMilestone() {
        let entry = MilestoneEntry(
            eventDate: eventDate,
            title: title,
            body: bodyText,
            isMilestone: true
        )

        modelContext.insert(entry)

        // Stamp location + weather for historical date (4.5)
        Task {
            await locationService.stampEntry(entry)

            if let location = locationService.currentLocation {
                await weatherService.stampWeather(on: entry, at: location)
            }
        }

        dismiss()
    }
}
