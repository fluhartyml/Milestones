//
//  MilestoneEntry.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class MilestoneEntry {

    // MARK: - Core (1.0.1, 1.0.2, 1.0.3)

    /// The event date — past, present, or future. The arbiter of truth.
    var eventDate: Date

    /// User's title or description for the entry
    var title: String

    /// User's journal text — the body of the entry
    var body: String

    /// When the entry was actually created (distinct from eventDate)
    var createdAt: Date

    // MARK: - Location (3.3, 3.4)

    var latitude: Double?
    var longitude: Double?
    var locationName: String?

    // MARK: - Weather (3.1, 3.2)

    var weatherCondition: String?
    var weatherTemperature: Double?
    var weatherHumidity: Double?
    var weatherWindSpeed: Double?
    var weatherUVIndex: Int?
    var weatherDescription: String?

    // MARK: - Sight (2.1)

    /// Photo attachments stored as JPEG data
    @Attribute(.externalStorage)
    var sightPhotos: [Data]?

    // MARK: - Touch (2.3)

    var touchDescription: String?

    // MARK: - Smell (2.4)

    var smellDescription: String?

    @Attribute(.externalStorage)
    var smellPhoto: Data?

    // MARK: - Taste (2.5)

    var tasteDescription: String?

    @Attribute(.externalStorage)
    var tastePhoto: Data?

    // MARK: - Voice Memo (amber B-031)

    /// The voice memo, an .m4a file's bytes. Optional: older entries have none (a lightweight migration).
    @Attribute(.externalStorage)
    var voiceMemo: Data?

    // MARK: - Drawing (amber B-183.7)

    /// What you drew on the entry card (a PKDrawing's data). Optional: older entries have none (a lightweight migration).
    /// REM: B-183.7 "so you can type or draw near it with Apple Pencil".
    @Attribute(.externalStorage)
    var drawing: Data?

    // MARK: - Index / Milestone (1.0.5, 4.1)

    /// Whether this entry has been promoted to a milestone in the index
    var isMilestone: Bool

    /// Which senses the user tagged on this entry
    var activeSenses: [String]

    // MARK: - Feeling (TestFlight feedback, build 21)

    /// The face picked to start the entry (Mood raw value). Optional: older entries have none.
    var mood: String?

    // MARK: - Addenda (amber B-183.2, F-M1)

    /// Sub-entries added to this entry, oldest first by createdAt. Optional with a default, so older stores
    /// open unchanged (lightweight migration). Deleting the entry deletes its addenda.
    @Relationship(deleteRule: .cascade, inverse: \Addendum.entry)
    var addenda: [Addendum]? = []

    // MARK: - Stickers (amber B-183.7.3)

    /// Glyphs stamped on the entry like stickers. Optional with a default (lightweight migration); deleted with the entry.
    @Relationship(deleteRule: .cascade, inverse: \EntrySticker.entry)
    var stickers: [EntrySticker]? = []

    // MARK: - Page layers (his design 2026-11-14, PageLayers.swift)

    /// This page's own background picture (JPEG), the bottom layer. Nil = the all-pages picture, or none.
    @Attribute(.externalStorage) var pageBackground: Data?
    /// The Apple Pencil ink over the whole screen (a PencilKit drawing), the top layer.
    @Attribute(.externalStorage) var pageInk: Data?

    // MARK: - Taped in (amber B-182.4)

    /// Tickets, photos and washi tape laid on the entry. Optional with a default (lightweight migration).
    @Relationship(deleteRule: .cascade, inverse: \TapedItem.entry)
    var tapedItems: [TapedItem]? = []

    /// Oldest first, so a newer one lies on top.
    var sortedTapedItems: [TapedItem] {
        (tapedItems ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    // MARK: - Init

    init(
        eventDate: Date,
        title: String,
        body: String = "",
        isMilestone: Bool = false
    ) {
        self.eventDate = eventDate
        self.title = title
        self.body = body
        self.createdAt = Date()
        self.isMilestone = isMilestone
        self.activeSenses = []
    }
}

// MARK: - Computed Properties

extension MilestoneEntry {

    /// Formatted filing name: YYYY MMM DD HHMM Title
    var filingName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM dd HHmm"
        let stamp = formatter.string(from: eventDate).uppercased()
        // REM: MF-004 "Should never be an 'untitled' entry" — the filing name uses the shown title too.
        return "\(stamp) \(displayTitle)"
    }

    /// Whether this entry has any weather data
    var hasWeather: Bool {
        weatherCondition != nil || weatherTemperature != nil
    }

    /// Whether this entry has any location data
    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    /// The addenda in the order they were added (B-183.2: "New ones add at the bottom of this block", F-M1 model).
    var sortedAddenda: [Addendum] {
        (addenda ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    /// The stickers, oldest first, so a newer one sits on top.
    var sortedStickers: [EntrySticker] {
        (stickers ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    /// Every sense this entry used: the old sense tiles, its addenda, its stickers (rows and the Index read this).
    var senseIDsUsed: [String] {
        var seen: [String] = []
        // REM: MF-001 "There are only five senses" — the retired Balance / Body ids are counted as Touch.
        for raw in activeSenses + sortedAddenda.map(\.sense) + sortedStickers.map(\.sense) {
            let id = SenseType.shownID(raw)
            guard !id.isEmpty, !seen.contains(id) else { continue }
            seen.append(id)
        }
        return seen
    }

    /// Whether this entry has any photos attached
    var hasPhotos: Bool {
        if let photos = sightPhotos, !photos.isEmpty { return true }
        if smellPhoto != nil { return true }
        if tastePhoto != nil { return true }
        return false
    }
}

// MARK: - Display title (MF-004)

extension MilestoneEntry {
    // REM: MF-004, his words (TestFlight build 30): "Should never be an 'untitled' entry" / "the user gives so much
    // information there is no reason to leave an untitled entry". The title you write always wins. Empty, the title
    // shown is worked out from what the entry has, in his order: the first words of the entry text; else its sticker
    // names or first addendum title; else the senses it used; else its town and the day ("Surfside Beach, Monday").
    // The stored title is never written — this is only what is shown (rows, the title bar, the Index).
    /// The title to show: yours, or one made from what the entry holds. Never "Untitled".
    var displayTitle: String {
        let own = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !own.isEmpty { return own }

        // 1. The entry text (and what older entries wrote in the old Touch / Smell / Taste boxes).
        for words in [body, touchDescription ?? "", smellDescription ?? "", tasteDescription ?? ""] {
            if let opening = Self.openingWords(of: words) { return opening }
        }

        // 2. Sticker names, else the first addendum title (else the first words of an addendum).
        var stickerNames: [String] = []
        for sticker in sortedStickers {
            let name = sticker.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty && !stickerNames.contains(name) { stickerNames.append(name) }
        }
        if !stickerNames.isEmpty { return Array(stickerNames.prefix(3)).formatted(.list(type: .and)) }
        for addendum in sortedAddenda {
            let heading = addendum.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !heading.isEmpty { return heading }
        }
        for addendum in sortedAddenda {
            if let opening = Self.openingWords(of: addendum.text) { return opening }
        }

        // 3. The senses it used.
        var senseNames: [String] = []
        for id in senseIDsUsed {
            let name = SenseType(stored: id)?.displayName
                ?? sortedAddenda.first { $0.sense == id }?.senseName
                ?? sortedStickers.first { $0.sense == id }?.senseName
                ?? ""
            if !name.isEmpty && !senseNames.contains(name) { senseNames.append(name) }
        }
        if !senseNames.isEmpty { return senseNames.formatted(.list(type: .and)) }

        // 4. The town and the day ("Surfside Beach, Monday"); with no town, the day and date.
        let day = eventDate.formatted(.dateTime.weekday(.wide))
        if let town = locationName?.split(separator: ",").first?.trimmingCharacters(in: .whitespaces), !town.isEmpty {
            return "\(town), \(day)"
        }
        // REM: MF-004 — no words, glyphs, senses or town: the day and date still name it (never "Untitled").
        return eventDate.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    /// The first line of some writing, cut to its first eight words. Nil when there is nothing written.
    private static func openingWords(of writing: String) -> String? {
        guard let line = writing.split(whereSeparator: \.isNewline)
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .first(where: { !$0.isEmpty }) else { return nil }
        let words = line.split(whereSeparator: \.isWhitespace)
        return words.count > 8 ? words.prefix(8).joined(separator: " ") : line
    }
}
