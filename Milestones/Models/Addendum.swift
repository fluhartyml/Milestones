//
//  Addendum.swift
//  Milestones
//
//  REM: amber B-183.2 / B-183.2.1 / B-183.2.2 (locked 2026-11-09). "each sense button adds an addendum (a sub-entry)
//  to the current entry" · "each addendum is stamped at its top with the glyph of the sense button that made it" ·
//  "an addendum's heading is the title you write; its subheading is the sense". The sense sheets' tool tiles
//  (B-183.7.1, AddendumEditorView) make them. Every field has a default and the relationship is
//  optional, so stores written before this build open unchanged (a lightweight migration; CloudKit-safe if turned on).
//

import Foundation
import SwiftData

@Model
final class Addendum {
    /// The sense's id (a SenseType raw value today; a sense you make yourself later, B-183.5).
    var sense: String = ""
    /// The sense's name as shown on the card's subheading ("Sight", "Hearing"…), kept with the addendum so a
    /// renamed or removed sense (B-183.5) doesn't change what an old addendum says.
    var senseName: String = ""
    /// The SF Symbol stamped at the card's top (B-183.2.1).
    var glyph: String = ""
    /// The title you write — the card's heading (B-183.2.2).
    var title: String = ""
    var text: String = ""
    @Attribute(.externalStorage) var photo: Data?
    @Attribute(.externalStorage) var audio: Data?
    /// How long the recording is, for the card's "Hearing · 0:42" (F-M1 mockup). 0 when there is no recording.
    var audioSeconds: Double = 0
    var createdAt: Date = Date()
    /// The entry this addendum belongs to (inverse of MilestoneEntry.addenda).
    var entry: MilestoneEntry?

    init(sense: SenseType, title: String = "") {
        self.sense = sense.rawValue
        self.senseName = sense.displayName
        self.glyph = sense.icon
        self.title = title
        self.createdAt = Date()
    }

    /// REM: B-183.2 piece 2 — made by a sense button's tool tile; a sense you made yourself (B-183.5) has no SenseType.
    init(senseID: String, senseName: String, glyph: String, title: String = "") {
        self.sense = senseID
        self.senseName = senseName
        self.glyph = glyph
        self.title = title
        self.createdAt = Date()
    }
}
