//
//  EntryDetailView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import SwiftData
import PhotosUI
import MapKit

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

    @Query private var allEntries: [MilestoneEntry]
    @State private var showingDatePicker = false
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .headline) private var headingSize: CGFloat = 20
    @ScaledMetric(relativeTo: .title2) private var glyphSize: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var mapHeight: CGFloat = 160

    var body: some View {
        // REM: F-M1, his word 2026-11-09: "i guess it looks okay as presented" — "Date, Entry, Addenda, Location in
        // one VStack". The Form keeps that order top to bottom, each section a card; the rest of the entry follows.
        Form {
            // MARK: - Date (B-183)

            // REM: B-183, his layout: "the date is #1 on the screen, at the top." F-M2: "yes drop it." — the gray
            // "2026 NOV 07 0933" stamp card is gone from this screen; this Date card shows the date instead.
            Section {
                dateCard
            }

            // MARK: - Entry (F-M3)

            // REM: F-M3: "The title box has no 'Entry' label above it. Empty, it shows a gray 'Entry title' hint".
            Section {
                TextField(text: $entry.title, prompt: Text("Entry title")) {
                    Text("Entry title")
                }
                .labelsHidden()
                .font(.system(size: headingSize, weight: .semibold))
                .accessibilityLabel("Entry title")
                .accessibilityIdentifier("entryTitle")

                TextField(text: $entry.body, prompt: Text("Write about this moment..."), axis: .vertical) {
                    Text("Entry text")
                }
                .labelsHidden()
                .lineLimit(4...20)
                .accessibilityLabel("Entry text")

                // REM: The face picked to start the entry (his TestFlight feedback, build 21) — changeable here.
                Picker("Feeling", selection: $entry.feeling) {
                    Text("None").tag(Mood?.none)
                    ForEach(Mood.allCases) { mood in
                        Text("\(mood.emoji) \(mood.name)").tag(Optional(mood))
                    }
                }
                .accessibilityIdentifier("entryFeeling")
            }

            // MARK: - Addenda (F-M1, B-183.2.1, B-183.2.2)

            // REM: F-M1: "addenda are one block right under the entry". Only shown when the entry has some; the sense
            // sheets that add them are the next piece.
            if !entry.sortedAddenda.isEmpty {
                Section {
                    ForEach(entry.sortedAddenda) { addendum in
                        addendumCard(addendum)
                    }
                }
            }

            // MARK: - Location (B-183.1)

            if entry.hasLocation || entry.locationName != nil {
                Section {
                    locationCard
                }
            }

            // MARK: - Weather

            if entry.hasWeather {
                Section {
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
                    .font(.system(size: bodySize))
                    .foregroundStyle(.secondary)

                    WeatherAttributionView()
                } header: {
                    Text("Weather").font(.system(size: bodySize))
                }
            }

            VoiceMemoSection(memo: $entry.voiceMemo, text: $entry.body)

            // MARK: - Senses

            Section {
                SensePicker(activeSenses: $activeSenses)
                    .padding(.vertical, 4)
                    .onChange(of: activeSenses) { _, newValue in
                        entry.activeSenses = newValue.map(\.rawValue)
                    }
            } header: {
                Text("Senses").font(.system(size: bodySize))
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

            // REM: B-183.8, his word 2026-11-09: "yes replace it with the index" — "the star toggle comes off
            // entries". The Appendix row and star are gone from the entry; isMilestone stays in the store untouched
            // (the Appendix tab still reads it). The Index is the top-bar button below.
        }
        .font(.system(size: bodySize))
        // REM: F-M3: "the title bar shows the entry's own title instead of 'Entry', and it changes as you type ...
        // Empty ... the bar falls back to 'Entry'."
        .navigationTitle(entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Entry" : entry.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            // REM: F-M1 "Index in the top bar" / B-183.8. Shown only when some entry has a sense to index — no empty
            // Index screen.
            if SenseIndex.hasAnything(in: allEntries) {
                ToolbarItem(placement: .navigation) {
                    NavigationLink {
                        SenseIndexView()
                    } label: {
                        Label("Index", systemImage: "list.bullet.indent")
                    }
                    .accessibilityLabel("Index")
                    .accessibilityHint("Lists your senses. Tap one to see every entry with it.")
                    .accessibilityIdentifier("indexButton")
                }
            }
        }
        .onAppear {
            if !hasLoadedSenses {
                activeSenses = Set(entry.activeSenses.compactMap { SenseType(rawValue: $0) })
                hasLoadedSenses = true
            }
        }
    }

    // MARK: - Date Card

    /// Tap the date to change it; tap again to put the calendar away.
    @ViewBuilder
    private var dateCard: some View {
        let shown = entry.eventDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().year().hour().minute())
        Button {
            withAnimation { showingDatePicker.toggle() }
        } label: {
            HStack {
                Text(shown)
                    .font(.system(size: headingSize, weight: .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: showingDatePicker ? "chevron.up" : "calendar")
                    .font(.system(size: bodySize))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showingDatePicker ? "Hide calendar" : "Change date")
        .accessibilityValue(shown)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("entryDate")

        if showingDatePicker {
            DatePicker("Date", selection: $entry.eventDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .labelsHidden()
                .accessibilityLabel("Entry date")
        }
    }

    // MARK: - Addendum Card

    /// REM: B-183.2.1 "stamped at its top with the glyph of the sense button that made it"; B-183.2.2 "heading is the
    /// title you write; its subheading is the sense". Mockup: HStack { glyph, VStack { title, sense } }.
    private func addendumCard(_ addendum: Addendum) -> some View {
        let heading = addendum.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: addendum.glyph.isEmpty ? "sparkles" : addendum.glyph)
                .font(.system(size: glyphSize))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(heading.isEmpty ? addendum.senseName : heading)
                    .font(.system(size: headingSize, weight: .semibold))
                if !heading.isEmpty {
                    Text(addendum.senseName)
                        .font(.system(size: bodySize))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Location Card

    /// REM: B-183.1: "Location shows a location pin (a small map with a pin), not just the town name." Uses the
    /// latitude/longitude already stamped on the entry; the map doesn't move under your finger, so the screen scrolls.
    @ViewBuilder
    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.system(size: headingSize, weight: .semibold))
                .accessibilityAddTraits(.isHeader)
            if let name = entry.locationName {
                Text(name)
                    .font(.system(size: bodySize))
                    .foregroundStyle(.secondary)
            }
            if let latitude = entry.latitude, let longitude = entry.longitude {
                let spot = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                Map(initialPosition: .region(MKCoordinateRegion(center: spot,
                                                                latitudinalMeters: 1500,
                                                                longitudinalMeters: 1500)),
                    interactionModes: []) {
                    Marker(entry.locationName ?? "Location", coordinate: spot)
                }
                .id("\(latitude),\(longitude)")
                .frame(height: mapHeight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Location map")
                .accessibilityValue(entry.locationName ?? "")
            }
        }
        .padding(.vertical, 4)
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
