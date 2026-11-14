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

    // REM: MF-007, his words: "Why is hearing greyed out? It should have audio recording" — the old seven-tile grid
    // (SensePicker, which grayed out Hearing) and the unused compose sheet that held it are deleted; Hearing's tile in
    // its sense sheet is the microphone (SenseButton.tools), never gray.
    // REM: the old sense tiles (SensePicker) are gone — the senses bar replaces them (no duplicate UI). Entries
    // written with them keep what they hold: their Sight / Touch / Smell / Taste boxes still show when they have
    // something in them. Worked out once when the screen opens, so a box doesn't vanish while you clear it.
    @State private var legacySenses: Set<SenseType> = []
    @State private var hasLoadedSenses = false

    // MARK: - Senses bar state (B-183.7, 183.7.1, 183.7.3, 183.5)

    @Environment(\.modelContext) private var modelContext
    @State private var openSense: SenseButton?
    /// A tool tile tapped in the sense sheet; its addendum opens once that sheet has closed (SwiftUI drops a sheet
    /// presented while another is still leaving).
    @State private var pendingAddendum: AddendumTarget?
    @State private var addendumTarget: AddendumTarget?
    @State private var editingSenses = false
    @State private var selectedStickerID: PersistentIdentifier?
    /// B-183.7: drawing on the entry card (EntryDrawingView.swift).
    @State private var isDrawing = false
    @ScaledMetric(relativeTo: .body) private var drawingRoom: CGFloat = 260

    @Query private var allEntries: [MilestoneEntry]
    @State private var showingDatePicker = false
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .headline) private var headingSize: CGFloat = 20
    @ScaledMetric(relativeTo: .title2) private var glyphSize: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var mapHeight: CGFloat = 160
    @ScaledMetric(relativeTo: .body) private var thumbSize: CGFloat = 64

    var body: some View {
        // REM: F-M1, his word 2026-11-09: "i guess it looks okay as presented" — "Date, Entry, Addenda, Location in
        // one VStack". The Form keeps that order top to bottom, each section a card; the rest of the entry follows.
        // REM: B-182 / B-182.1: on the iPhone Duo, opened or standing, the entry lies like an open book with the hinge as
        // the spine — Date and Entry on the left page, the Addenda, Location and the rest on the right (OpenBook.swift).
        // Closed, and on every other device, it is the one page above, unchanged.
        OpenBook {
            leftPage
        } right: {
            rightPage
        }
        .font(.system(size: bodySize))
        // REM: B-182.3 "one day per page with the date printed at the top" — the open book prints this entry's day.
        .environment(\.diaryPageDate, entry.createdAt)
        // REM: F-M1 mockup: ".safeAreaInset(edge: .bottom) › HStack" — "The five senses sit in a bar pinned to the
        // bottom (.safeAreaInset), so they stay put while you scroll. Tapping one opens its sheet of glyphs, its tool
        // glyph included (B-183.7.1)."
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SenseBarView(onSense: { openSense = $0 }, onEdit: { editingSenses = true })
        }
        .sheet(item: $openSense, onDismiss: {
            if let pending = pendingAddendum {
                pendingAddendum = nil
                addendumTarget = pending
            }
        }) { sense in
            SenseSheetView(startSenseID: sense.id,
                           onTool: { sense, tool in
                               pendingAddendum = .new(sense, tool)
                               openSense = nil
                           },
                           onGlyph: { sense, glyph in
                               stamp(glyph, from: sense)
                               openSense = nil
                           })
        }
        .sheet(item: $addendumTarget) { target in
            switch target {
            case .new(let sense, let tool):
                AddendumEditorView(entry: entry, sense: sense, startTool: tool)
            case .existing(let addendum):
                AddendumEditorView(entry: entry, addendum: addendum)
            }
        }
        .sheet(isPresented: $editingSenses) {
            SenseEditorView()
        }
        // REM: F-M3: "the title bar shows the entry's own title instead of 'Entry', and it changes as you type".
        // REM: MF-004, his words: "Should never be an 'untitled' entry" / "the user gives so much information there is
        // no reason to leave an untitled entry" — empty, the bar shows a title made from the entry (displayTitle).
        .navigationTitle(entry.displayTitle)
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
                    .accessibilityHint("Lists your senses and glyphs. Tap one to see every entry with it.")
                    .accessibilityIdentifier("indexButton")
                }
            }
        }
        .onAppear {
            if !hasLoadedSenses {
                var old: Set<SenseType> = []
                if !(entry.sightPhotos ?? []).isEmpty { old.insert(.sight) }
                if !(entry.touchDescription ?? "").isEmpty { old.insert(.touch) }
                if !(entry.smellDescription ?? "").isEmpty || entry.smellPhoto != nil { old.insert(.smell) }
                if !(entry.tasteDescription ?? "").isEmpty || entry.tastePhoto != nil { old.insert(.taste) }
                legacySenses = old
                hasLoadedSenses = true
            }
        }
    }

    // MARK: - Pages (B-182.1)

    /// The left page of the open book: the Date card and the entry.
    @ViewBuilder
    private var leftPage: some View {
        // MARK: - Date (B-183)

        // REM: B-183, his layout: "the date is #1 on the screen, at the top." F-M2: "yes drop it." — the gray
        // "2026 NOV 07 0933" stamp card is gone from this screen; this Date card shows the date instead.
        Section {
            dateCard
        }

        // MARK: - Entry (F-M3)

        // REM: F-M3: "The title box has no 'Entry' label above it. Empty, it shows a gray 'Entry title' hint".
        Section {
            // REM: B-183.7.3: "It stamps the entry, you move it anywhere on the page, and you write around it or
            // leave it." The stickers ride on the entry card (title + text), above the words.
            VStack(alignment: .leading, spacing: 12) {
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
            }
            // REM: B-183.7 "so you can type or draw near it with Apple Pencil" — while you draw, the card is at least
            // drawingRoom tall so there is room around the glyphs; the drawing sits over the words, under the stickers.
            .frame(minHeight: isDrawing || entry.drawing != nil ? drawingRoom : nil, alignment: .top)
            .overlay {
                EntryDrawingLayer(entry: entry, isDrawing: isDrawing)
            }
            .overlay {
                StickerLayer(entry: entry, selectedID: $selectedStickerID)
                    .allowsHitTesting(!isDrawing)
            }

            if let sticker = selectedSticker, !isDrawing {
                stickerControls(sticker)
            }

            DrawingControls(entry: entry, isDrawing: $isDrawing)

            // REM: The face picked to start the entry (his TestFlight feedback, build 21) — changeable here.
            Picker("Feeling", selection: $entry.feeling) {
                Text("None").tag(Mood?.none)
                ForEach(Mood.allCases) { mood in
                    Text("\(mood.emoji) \(mood.name)").tag(Optional(mood))
                }
            }
            .accessibilityIdentifier("entryFeeling")
        }
    }

    /// The right page: the addenda, location, weather, voice memo and the old sense boxes.
    @ViewBuilder
    private var rightPage: some View {
        // MARK: - Addenda (F-M1, B-183.2.1, B-183.2.2)

        // REM: F-M1: "addenda are one block right under the entry". Only shown when the entry has some; the tool
        // tiles in the sense sheets add them (B-183.7.1). Tap one to look at it, play it, change it or remove it.
        if !entry.sortedAddenda.isEmpty {
            Section {
                ForEach(entry.sortedAddenda) { addendum in
                    Button {
                        addendumTarget = .existing(addendum)
                    } label: {
                        addendumCard(addendum)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens this addendum.")
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

        // MARK: - Senses written with the old sense tiles

        if legacySenses.contains(.sight) {
            Section {
                sightSection
            }
        }

        if legacySenses.contains(.touch) {
            Section {
                TouchInputView(description: Binding(
                    get: { entry.touchDescription ?? "" },
                    set: { entry.touchDescription = $0.isEmpty ? nil : $0 }
                ))
            }
        }

        if legacySenses.contains(.smell) {
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

        if legacySenses.contains(.taste) {
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
        // (nothing shows it now; the data is kept). The Index is the top-bar button below and its own tab.
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
            Image(systemName: addendum.shownGlyph.isEmpty ? "sparkles" : addendum.shownGlyph)
                .font(.system(size: glyphSize))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(heading.isEmpty ? addendum.shownSenseName : heading)
                    .font(.system(size: headingSize, weight: .semibold))
                    .foregroundStyle(.primary)
                // F-M1 mockup: "Hearing · 0:42" under a recording.
                let length = addendum.audio != nil && addendum.audioSeconds > 0
                    ? " · " + VoiceMemoRecorder.clock(addendum.audioSeconds) : ""
                if !heading.isEmpty || !length.isEmpty {
                    Text(addendum.shownSenseName + length)
                        .font(.system(size: bodySize))
                        .foregroundStyle(.secondary)
                }
                let words = addendum.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !words.isEmpty {
                    Text(words)
                        .font(.system(size: bodySize))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                }
            }
            Spacer(minLength: 0)
            if let photo = addendum.photo {
                JournalPhoto(data: photo)
                    .frame(width: thumbSize, height: thumbSize)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Stickers (B-183.7.3)

    private var selectedSticker: EntrySticker? {
        guard let selectedStickerID else { return nil }
        return entry.sortedStickers.first { $0.persistentModelID == selectedStickerID }
    }

    /// REM: B-183.7: "Tapping one embeds the glyph in the journal entry". It lands near the top right, each new one a
    /// little lower, so a new sticker doesn't hide the one before; then you drag it (or use the arrows) where you want.
    private func stamp(_ glyph: SenseGlyph, from sense: SenseButton) {
        let count = entry.sortedStickers.count
        let sticker = EntrySticker(glyph: glyph, sense: sense, x: 0.88, y: 0.18 + Double(count % 5) * 0.16)
        modelContext.insert(sticker)
        sticker.entry = entry
        selectedStickerID = nil
    }

    /// The button way to move or peel off a sticker (his rule: a drag is never the only way).
    private func stickerControls(_ sticker: EntrySticker) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(sticker.name.isEmpty ? "Sticker" : sticker.name, systemImage: sticker.symbol)
                .font(.system(size: bodySize, weight: .semibold))
            HStack(spacing: 8) {
                nudge("Move Left", symbol: "arrow.left", sticker) { $0.x -= 0.06 }
                nudge("Move Up", symbol: "arrow.up", sticker) { $0.y -= 0.06 }
                nudge("Move Down", symbol: "arrow.down", sticker) { $0.y += 0.06 }
                nudge("Move Right", symbol: "arrow.right", sticker) { $0.x += 0.06 }
            }
            HStack(spacing: 12) {
                Button(role: .destructive) {
                    selectedStickerID = nil
                    modelContext.delete(sticker)
                } label: {
                    Label("Remove Sticker", systemImage: "trash").font(.system(size: bodySize, weight: .semibold))
                }
                .accessibilityHint("Peels this sticker off your entry.")
                .accessibilityIdentifier("stickerRemove")
                Button {
                    selectedStickerID = nil
                } label: {
                    Text("Done").font(.system(size: bodySize, weight: .semibold))
                }
                .accessibilityHint("Leaves the sticker where it is.")
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }

    private func nudge(_ name: String, symbol: String, _ sticker: EntrySticker,
                       _ change: @escaping (EntrySticker) -> Void) -> some View {
        Button {
            change(sticker)
            sticker.x = min(max(sticker.x, 0.04), 0.96)
            sticker.y = min(max(sticker.y, 0.04), 0.96)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: bodySize, weight: .semibold))
                .frame(minWidth: 32, minHeight: 32)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(name)
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
                    // REM: MF-005, his words: "Should be a location pin" — a red map pin marker.
                    Marker(entry.locationName ?? "Location", systemImage: "mappin", coordinate: spot)
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

// MARK: - Addendum target

/// Which addendum the editor opens: a new one from a tool tile, or one already on the entry.
enum AddendumTarget: Identifiable {
    case new(SenseButton, SenseTool)
    case existing(Addendum)

    var id: String {
        switch self {
        case .new(let sense, let tool): "new-\(sense.id)-\(tool.rawValue)"
        case .existing(let addendum): "addendum-\(addendum.persistentModelID.hashValue)"
        }
    }
}

// MARK: - Sticker layer (B-183.7.3)

/// The stickers on the entry card. Only the stickers take touches; the rest of the card is the text underneath.
struct StickerLayer: View {
    let entry: MilestoneEntry
    @Binding var selectedID: PersistentIdentifier?

    var body: some View {
        GeometryReader { geo in
            ForEach(entry.sortedStickers) { sticker in
                StickerView(sticker: sticker, area: geo.size,
                            isSelected: sticker.persistentModelID == selectedID) {
                    selectedID = selectedID == sticker.persistentModelID ? nil : sticker.persistentModelID
                }
            }
        }
    }
}

struct StickerView: View {
    @Bindable var sticker: EntrySticker
    let area: CGSize
    let isSelected: Bool
    let onTap: () -> Void

    @State private var drag: CGSize = .zero
    @ScaledMetric(relativeTo: .title) private var glyphSize: CGFloat = 30

    var body: some View {
        Image(systemName: sticker.symbol.isEmpty ? "sparkles" : sticker.symbol)
            .font(.system(size: glyphSize))
            .foregroundStyle(Color.accentColor)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isSelected ? 3 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
            // Gestures sit before .position so only the sticker itself is touchable, not the whole card.
            .gesture(
                DragGesture(minimumDistance: 6)
                    .onChanged { drag = $0.translation }
                    .onEnded { value in
                        guard area.width > 0, area.height > 0 else { drag = .zero; return }
                        sticker.x = min(max(sticker.x + value.translation.width / area.width, 0.04), 0.96)
                        sticker.y = min(max(sticker.y + value.translation.height / area.height, 0.04), 0.96)
                        drag = .zero
                    }
            )
            .onTapGesture(perform: onTap)
            .accessibilityElement()
            .accessibilityLabel(sticker.name.isEmpty ? "Sticker" : sticker.name)
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint("Shows buttons to move or remove this sticker.")
            .offset(drag)
            .position(x: sticker.x * area.width, y: sticker.y * area.height)
    }
}
