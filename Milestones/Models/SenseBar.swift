//
//  SenseBar.swift
//  Milestones
//
//  The sense buttons at the bottom of an entry, their tools, and their glyphs.
//
//  REM: amber B-183.3.1 (locked 2026-11-09): "the defaults are the five senses" — Sight, Hearing, Touch, Smell, Taste.
//  REM: B-183.5: "you can move, add, rename or remove the sense buttons. A new one gets a glyph you choose and a title
//  REM: you write." Kept in this device's settings (UserDefaults), not in the journal store: the buttons are how the
//  REM: app is set up, not something you wrote. What an entry used is copied onto the entry (Addendum.senseName,
//  REM: EntrySticker.name), so renaming or removing a button never changes what an old entry says.
//  REM: B-183.7.1, his word 2026-11-09 19:3x: "use the camera glyph to unify the glyph motife." — each sense's tool is a
//  REM: glyph tile in its sheet: a camera on Sight, a microphone on Hearing, a keyboard on Touch, camera + keyboard on
//  REM: Smell and Taste. B-183.7 / 183.7.2: each page holds ready-made glyphs (activities, like Daylio) and you add
//  REM: your own ("a furry sweater, your dog").
//

import Foundation
import Observation
import SwiftUI  // Array.move(fromOffsets:toOffset:) for the Edit Senses list

/// One button on the senses bar.
struct SenseButton: Codable, Identifiable, Hashable {
    /// A SenseType raw value for the five senses, "custom-<uuid>" for one you made.
    var id: String
    var name: String
    var glyph: String

    var senseType: SenseType? { SenseType(rawValue: id) }

    /// REM: B-183.7.1 — the tools in this sense's sheet. A sense you make yourself gets camera + keyboard (Claude's
    /// call: the spec gives new senses a glyph and a title, not a tool; picture + typing covers the most).
    var tools: [SenseTool] {
        switch senseType {
        case .sight: [.camera]
        case .hearing: [.microphone]
        case .touch: [.keyboard]
        case .smell, .taste: [.camera, .keyboard]
        default: [.camera, .keyboard]
        }
    }

    /// The question at the top of its sheet.
    var prompt: String { senseType?.description ?? "What do you notice?" }
}

/// A tool tile in a sense's sheet: using one adds an addendum (B-183.2).
enum SenseTool: String, Identifiable {
    case camera, microphone, keyboard
    var id: String { rawValue }

    var glyph: String {
        switch self {
        case .camera: "camera.fill"
        case .microphone: "mic.fill"
        case .keyboard: "keyboard"
        }
    }

    /// The tile's words — what happens when you tap it.
    var name: String {
        switch self {
        #if os(iOS)
        case .camera: "Take Picture"
        #else
        // The Mac and Vision Pro don't hand the camera to apps the way iPhone does; the tile picks a photo instead.
        case .camera: "Add Picture"
        #endif
        case .microphone: "Record"
        case .keyboard: "Type"
        }
    }
}

/// A glyph you can stamp on an entry like a sticker (B-183.7.3).
struct SenseGlyph: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var symbol: String
}

@MainActor
@Observable
final class SenseBarStore {
    static let shared = SenseBarStore()

    private static let buttonsKey = "senseBarButtons"
    private static let ownGlyphsKey = "senseOwnGlyphs"

    private(set) var buttons: [SenseButton]
    /// Glyphs you added, by sense id.
    private(set) var ownGlyphs: [String: [SenseGlyph]]

    private init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: Self.buttonsKey),
           let saved = try? JSONDecoder().decode([SenseButton].self, from: data) {
            buttons = saved
        } else {
            buttons = Self.fiveSenses
        }
        if let data = defaults.data(forKey: Self.ownGlyphsKey),
           let saved = try? JSONDecoder().decode([String: [SenseGlyph]].self, from: data) {
            ownGlyphs = saved
        } else {
            ownGlyphs = [:]
        }
    }

    static var fiveSenses: [SenseButton] {
        [SenseType.sight, .hearing, .touch, .smell, .taste].map {
            SenseButton(id: $0.rawValue, name: $0.displayName, glyph: $0.icon)
        }
    }

    func button(_ id: String) -> SenseButton? { buttons.first { $0.id == id } }

    /// Ready-made glyphs, then your own.
    func glyphs(for sense: SenseButton) -> [SenseGlyph] {
        Self.readyMade(for: sense.id) + (ownGlyphs[sense.id] ?? [])
    }

    // MARK: Editing (B-183.5)

    func move(_ id: String, by step: Int) {
        guard let from = buttons.firstIndex(where: { $0.id == id }) else { return }
        let to = from + step
        guard buttons.indices.contains(to) else { return }
        buttons.swapAt(from, to)
        save()
    }

    func move(fromOffsets: IndexSet, toOffset: Int) {
        buttons.move(fromOffsets: fromOffsets, toOffset: toOffset)
        save()
    }

    func rename(_ id: String, to name: String) {
        guard let i = buttons.firstIndex(where: { $0.id == id }) else { return }
        buttons[i].name = name
        save()
    }

    func setGlyph(_ id: String, to glyph: String) {
        guard let i = buttons.firstIndex(where: { $0.id == id }) else { return }
        buttons[i].glyph = glyph
        save()
    }

    func remove(_ id: String) {
        buttons.removeAll { $0.id == id }
        save()
    }

    @discardableResult
    func addSense(name: String, glyph: String) -> SenseButton {
        let made = SenseButton(id: "custom-\(UUID().uuidString)", name: name, glyph: glyph)
        buttons.append(made)
        save()
        return made
    }

    /// Puts back any of the five senses you removed, at the end, without touching the ones you made.
    func restoreFiveSenses() {
        for sense in Self.fiveSenses where !buttons.contains(where: { $0.id == sense.id }) {
            buttons.append(sense)
        }
        save()
    }

    var isMissingAFiveSense: Bool {
        Self.fiveSenses.contains { sense in !buttons.contains { $0.id == sense.id } }
    }

    func addGlyph(to senseID: String, name: String, symbol: String) {
        ownGlyphs[senseID, default: []].append(SenseGlyph(id: "own-\(UUID().uuidString)", name: name, symbol: symbol))
        save()
    }

    func removeGlyph(_ glyphID: String, from senseID: String) {
        ownGlyphs[senseID]?.removeAll { $0.id == glyphID }
        save()
    }

    private func save() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(buttons) { defaults.set(data, forKey: Self.buttonsKey) }
        if let data = try? JSONEncoder().encode(ownGlyphs) { defaults.set(data, forKey: Self.ownGlyphsKey) }
    }

    // MARK: Ready-made glyphs (B-183.7)

    /// REM: B-183.7: "Daylio-style ready-made glyphs (activities) ... (Sight: Movies or TV…)". Every symbol name
    /// was checked against the system's SF Symbols list (CoreGlyphs name_availability) and is in iOS 17 / macOS 14,
    /// the app's oldest systems.
    static func readyMade(for senseID: String) -> [SenseGlyph] {
        let list: [(String, String)]
        switch SenseType(rawValue: senseID) {
        case .sight:
            list = [("Movies", "film"), ("TV", "tv"), ("Reading", "book"), ("Sunset", "sunset"),
                    ("Nature", "leaf"), ("Art", "paintpalette"), ("Night Sky", "moon.stars"), ("Mountains", "mountain.2")]
        case .hearing:
            list = [("Music", "music.note"), ("Listening", "headphones"), ("Talking", "bubble.left.and.bubble.right"),
                    ("Birds", "bird"), ("Rain", "cloud.rain"), ("Singing", "music.mic"), ("Phone Call", "phone"),
                    ("Bells", "bell")]
        case .touch:
            list = [("Dog", "dog"), ("Cat", "cat"), ("Hug", "figure.2.arms.open"), ("Clothes", "tshirt"),
                    ("Cold", "snowflake"), ("Warm Sun", "sun.max"), ("Water", "drop"), ("Bed", "bed.double")]
        case .smell:
            list = [("Coffee", "cup.and.saucer"), ("Flowers", "camera.macro"), ("Trees", "tree"), ("Campfire", "flame"),
                    ("Ocean", "water.waves"), ("Rain", "cloud.drizzle"), ("Baking", "oven"), ("Laundry", "washer")]
        case .taste:
            list = [("Meal", "fork.knife"), ("Cake", "birthday.cake"), ("Vegetables", "carrot"),
                    ("Takeout", "takeoutbag.and.cup.and.straw"), ("Tea", "mug"), ("Fish", "fish"),
                    ("Popcorn", "popcorn"), ("Cooking", "frying.pan")]
        default:
            list = []
        }
        return list.map { SenseGlyph(id: "\(senseID).\($0.1)", name: $0.0, symbol: $0.1) }
    }

    /// The glyphs you can choose from for a sense or a glyph you make, each with the 1–3 words VoiceOver reads and
    /// the name filled in when you pick it (every symbol checked in the SF Symbols list, iOS 17 / macOS 14).
    static let choosable: [SenseGlyph] = [
        SenseGlyph(id: "dog", name: "Dog", symbol: "dog"),
        SenseGlyph(id: "cat", name: "Cat", symbol: "cat"),
        SenseGlyph(id: "pawprint", name: "Paw Print", symbol: "pawprint"),
        SenseGlyph(id: "hare", name: "Rabbit", symbol: "hare"),
        SenseGlyph(id: "tortoise", name: "Turtle", symbol: "tortoise"),
        SenseGlyph(id: "bird", name: "Bird", symbol: "bird"),
        SenseGlyph(id: "fish", name: "Fish", symbol: "fish"),
        SenseGlyph(id: "ladybug", name: "Ladybug", symbol: "ladybug"),
        SenseGlyph(id: "ant", name: "Ant", symbol: "ant"),
        SenseGlyph(id: "lizard", name: "Lizard", symbol: "lizard"),
        SenseGlyph(id: "tshirt", name: "Shirt", symbol: "tshirt"),
        SenseGlyph(id: "shoe", name: "Shoe", symbol: "shoe"),
        SenseGlyph(id: "backpack", name: "Backpack", symbol: "backpack"),
        SenseGlyph(id: "handbag", name: "Handbag", symbol: "handbag"),
        SenseGlyph(id: "eyeglasses", name: "Glasses", symbol: "eyeglasses"),
        SenseGlyph(id: "sunglasses", name: "Sunglasses", symbol: "sunglasses"),
        SenseGlyph(id: "teddybear", name: "Teddy Bear", symbol: "teddybear"),
        SenseGlyph(id: "gift", name: "Gift", symbol: "gift"),
        SenseGlyph(id: "balloon", name: "Balloon", symbol: "balloon"),
        SenseGlyph(id: "party.popper", name: "Party", symbol: "party.popper"),
        SenseGlyph(id: "heart", name: "Heart", symbol: "heart"),
        SenseGlyph(id: "sparkles", name: "Sparkles", symbol: "sparkles"),
        SenseGlyph(id: "star", name: "Star", symbol: "star"),
        SenseGlyph(id: "crown", name: "Crown", symbol: "crown"),
        SenseGlyph(id: "face.smiling", name: "Smile", symbol: "face.smiling"),
        SenseGlyph(id: "hands.clap", name: "Clapping", symbol: "hands.clap"),
        SenseGlyph(id: "figure.2.arms.open", name: "Hug", symbol: "figure.2.arms.open"),
        SenseGlyph(id: "figure.walk", name: "Walk", symbol: "figure.walk"),
        SenseGlyph(id: "figure.run", name: "Run", symbol: "figure.run"),
        SenseGlyph(id: "bicycle", name: "Bike", symbol: "bicycle"),
        SenseGlyph(id: "car", name: "Car", symbol: "car"),
        SenseGlyph(id: "bus", name: "Bus", symbol: "bus"),
        SenseGlyph(id: "tram", name: "Train", symbol: "tram"),
        SenseGlyph(id: "airplane", name: "Airplane", symbol: "airplane"),
        SenseGlyph(id: "sailboat", name: "Boat", symbol: "sailboat"),
        SenseGlyph(id: "tent", name: "Tent", symbol: "tent"),
        SenseGlyph(id: "beach.umbrella", name: "Beach", symbol: "beach.umbrella"),
        SenseGlyph(id: "house", name: "Home", symbol: "house"),
        SenseGlyph(id: "building.2", name: "City", symbol: "building.2"),
        SenseGlyph(id: "tree", name: "Tree", symbol: "tree"),
        SenseGlyph(id: "leaf", name: "Leaf", symbol: "leaf"),
        SenseGlyph(id: "camera.macro", name: "Flower", symbol: "camera.macro"),
        SenseGlyph(id: "sun.max", name: "Sun", symbol: "sun.max"),
        SenseGlyph(id: "moon", name: "Moon", symbol: "moon"),
        SenseGlyph(id: "moon.stars", name: "Night Sky", symbol: "moon.stars"),
        SenseGlyph(id: "cloud.sun", name: "Partly Sunny", symbol: "cloud.sun"),
        SenseGlyph(id: "cloud.rain", name: "Rain", symbol: "cloud.rain"),
        SenseGlyph(id: "snowflake", name: "Snow", symbol: "snowflake"),
        SenseGlyph(id: "wind", name: "Wind", symbol: "wind"),
        SenseGlyph(id: "rainbow", name: "Rainbow", symbol: "rainbow"),
        SenseGlyph(id: "flame", name: "Fire", symbol: "flame"),
        SenseGlyph(id: "drop", name: "Water", symbol: "drop"),
        SenseGlyph(id: "water.waves", name: "Waves", symbol: "water.waves"),
        SenseGlyph(id: "music.note", name: "Music", symbol: "music.note"),
        SenseGlyph(id: "headphones", name: "Headphones", symbol: "headphones"),
        SenseGlyph(id: "guitars", name: "Guitar", symbol: "guitars"),
        SenseGlyph(id: "pianokeys", name: "Piano", symbol: "pianokeys"),
        SenseGlyph(id: "bell", name: "Bell", symbol: "bell"),
        SenseGlyph(id: "radio", name: "Radio", symbol: "radio"),
        SenseGlyph(id: "speaker.wave.2", name: "Speaker", symbol: "speaker.wave.2"),
        SenseGlyph(id: "tv", name: "TV", symbol: "tv"),
        SenseGlyph(id: "film", name: "Movie", symbol: "film"),
        SenseGlyph(id: "book", name: "Book", symbol: "book"),
        SenseGlyph(id: "newspaper", name: "Newspaper", symbol: "newspaper"),
        SenseGlyph(id: "gamecontroller", name: "Video Game", symbol: "gamecontroller"),
        SenseGlyph(id: "puzzlepiece", name: "Puzzle", symbol: "puzzlepiece"),
        SenseGlyph(id: "dice", name: "Dice", symbol: "dice"),
        SenseGlyph(id: "theatermasks", name: "Theater", symbol: "theatermasks"),
        SenseGlyph(id: "ticket", name: "Ticket", symbol: "ticket"),
        SenseGlyph(id: "paintpalette", name: "Paints", symbol: "paintpalette"),
        SenseGlyph(id: "paintbrush", name: "Paintbrush", symbol: "paintbrush"),
        SenseGlyph(id: "pencil.and.scribble", name: "Drawing", symbol: "pencil.and.scribble"),
        SenseGlyph(id: "scissors", name: "Scissors", symbol: "scissors"),
        SenseGlyph(id: "hammer", name: "Hammer", symbol: "hammer"),
        SenseGlyph(id: "graduationcap", name: "School", symbol: "graduationcap"),
        SenseGlyph(id: "stethoscope", name: "Doctor", symbol: "stethoscope"),
        SenseGlyph(id: "bandage", name: "Bandage", symbol: "bandage"),
        SenseGlyph(id: "fork.knife", name: "Meal", symbol: "fork.knife"),
        SenseGlyph(id: "cup.and.saucer", name: "Coffee", symbol: "cup.and.saucer"),
        SenseGlyph(id: "mug", name: "Mug", symbol: "mug"),
        SenseGlyph(id: "birthday.cake", name: "Cake", symbol: "birthday.cake"),
        SenseGlyph(id: "carrot", name: "Carrot", symbol: "carrot"),
        SenseGlyph(id: "popcorn", name: "Popcorn", symbol: "popcorn"),
        SenseGlyph(id: "takeoutbag.and.cup.and.straw", name: "Takeout", symbol: "takeoutbag.and.cup.and.straw"),
        SenseGlyph(id: "frying.pan", name: "Frying Pan", symbol: "frying.pan"),
        SenseGlyph(id: "oven", name: "Oven", symbol: "oven"),
        SenseGlyph(id: "washer", name: "Laundry", symbol: "washer"),
        SenseGlyph(id: "shower", name: "Shower", symbol: "shower"),
        SenseGlyph(id: "bathtub", name: "Bath", symbol: "bathtub"),
        SenseGlyph(id: "bubbles.and.sparkles", name: "Soap", symbol: "bubbles.and.sparkles"),
        SenseGlyph(id: "bed.double", name: "Bed", symbol: "bed.double"),
        SenseGlyph(id: "basketball", name: "Basketball", symbol: "basketball"),
        SenseGlyph(id: "soccerball", name: "Soccer", symbol: "soccerball"),
        SenseGlyph(id: "football", name: "Football", symbol: "football"),
        SenseGlyph(id: "tennis.racket", name: "Tennis", symbol: "tennis.racket"),
        SenseGlyph(id: "eye", name: "Eye", symbol: "eye"),
        SenseGlyph(id: "ear", name: "Ear", symbol: "ear"),
        SenseGlyph(id: "hand.raised", name: "Hand", symbol: "hand.raised"),
        SenseGlyph(id: "nose", name: "Nose", symbol: "nose"),
        SenseGlyph(id: "mouth", name: "Mouth", symbol: "mouth"),
    ]
}
