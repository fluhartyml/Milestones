//
//  TapedItem.swift
//  Milestones
//
//  REM: amber B-182.4 (locked 2026-11-09), his revise 2026-11-07: "the freedom of paper ... taped-in photos, tickets ...
//  washi tape". His design 2026-11-14, mapped in chat: "a ticket from a movie or sports venue even a canceled (used)
//  airline ticket you scanned it with the phone camera then you could paste it at any angle 180 or any angular degree
//  and place it with washi tape like embellishments" + "maybe you can pinch zoom / resize it too?" — "code it".
//  One model for all three: a ticket (scanned), a photo (picked), or a loose strip of washi tape. Where it sits is a
//  fraction of the entry card (like EntrySticker), plus its turn in degrees and its size. Every field has a default and
//  the relationship is optional, so older stores open unchanged (a lightweight migration) and iCloud can carry it.
//

import Foundation
import SwiftData

@Model
final class TapedItem {
    /// "ticket", "photo" or "tape".
    var kind: String = "photo"
    /// The picture (JPEG), kept outside the database file. Empty for a strip of tape.
    @Attribute(.externalStorage) var imageData: Data?
    /// Width ÷ height of the picture, so it draws at its own shape before the image loads.
    var aspect: Double = 1.5
    /// The washi pattern (WashiPattern raw value): for tape, its look; for a ticket or photo, the strips on its corners
    /// ("" = no tape).
    var tape: String = ""
    var x: Double = 0.5
    var y: Double = 0.4
    /// Turn in degrees, any angle.
    var rotation: Double = 0
    /// 1 = the starting size.
    var scale: Double = 1
    var createdAt: Date = Date()
    var entry: MilestoneEntry?

    init(kind: String, imageData: Data?, aspect: Double, tape: String, x: Double, y: Double, rotation: Double) {
        self.kind = kind
        self.imageData = imageData
        self.aspect = aspect
        self.tape = tape
        self.x = x
        self.y = y
        self.rotation = rotation
        self.scale = 1
        self.createdAt = Date()
    }

    var name: String {
        switch kind {
        case "ticket": "Ticket"
        case "tape": "Washi Tape"
        default: "Photo"
        }
    }
}
