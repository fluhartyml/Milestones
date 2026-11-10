//
//  EntrySticker.swift
//  Milestones
//
//  REM: amber B-183.7.3 (locked 2026-11-09), his idea 2026-11-07: "a glyph works like a sticker. It stamps the entry,
//  you move it anywhere on the page, and you write around it or leave it." B-183.7: "Tapping one embeds the glyph in
//  the journal entry". B-183.8: the Index lists glyphs too — "tap 'Dog' → every entry with Dog" — so each sticker
//  keeps the glyph's name and its sense. Every field has a default and the relationship is optional, so stores written
//  before this build open unchanged (a lightweight migration).
//

import Foundation
import SwiftData

@Model
final class EntrySticker {
    /// The SF Symbol shown.
    var symbol: String = ""
    /// The glyph's name ("Dog") — what the Index lists.
    var name: String = ""
    /// The sense whose sheet it came from (a SenseType raw value, or a sense you made).
    var sense: String = ""
    var senseName: String = ""
    /// Where it sits on the entry, as a fraction of the entry's width and height (0 to 1), so it stays put on any
    /// screen size.
    var x: Double = 0.85
    var y: Double = 0.25
    var createdAt: Date = Date()
    var entry: MilestoneEntry?

    init(glyph: SenseGlyph, sense: SenseButton, x: Double, y: Double) {
        self.symbol = glyph.symbol
        self.name = glyph.name
        self.sense = sense.id
        self.senseName = sense.name
        self.x = x
        self.y = y
        self.createdAt = Date()
    }
}

extension EntrySticker {
    // REM: MF-001, his words: "There are only five senses" — a sticker stored under Balance / Body reads as Touch.
    /// The sense name shown for this sticker ("Touch" for the retired Balance / Body).
    var shownSenseName: String {
        if SenseType(rawValue: sense) == nil, let folded = SenseType(stored: sense) { return folded.displayName }
        return senseName
    }
}
