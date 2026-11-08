//
//  Mood.swift
//  Milestones
//
//  The feelings scale an entry starts from.
//
//  REM: HIS TESTFLIGHT FEEDBACK, build 21, 2026-11-08 06:43: "The first page the home page needs yo be
//  REM: redesigned one button with an emoji and a plus that asks how are you feeling and when pressed shows
//  REM: you " the pain scale" of emojis and you pick one to start your journal entry". 06:44: "Their "pain
//  REM: scale"" — a row of five faces, best to worst. Our own words and colors, not a copy of that app.
//  REM: Stored on the entry as the raw value (MilestoneEntry.mood) — optional, so older entries and
//  REM: iCloud sync are untouched. Never rename a raw value: entries already written use it.
//

import SwiftUI

enum Mood: String, CaseIterable, Identifiable {
    case great, good, okay, low, awful

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .great: "😄"
        case .good:  "🙂"
        case .okay:  "😐"
        case .low:   "🙁"
        case .awful: "😣"
        }
    }

    /// The word under the face — and the VoiceOver name (one word, his three-word rule).
    var name: String {
        switch self {
        case .great: "Great"
        case .good:  "Good"
        case .okay:  "Okay"
        case .low:   "Low"
        case .awful: "Awful"
        }
    }

    var color: Color {
        switch self {
        case .great: .teal
        case .good:  .green
        case .okay:  .blue
        case .low:   .orange
        case .awful: .red
        }
    }
}

extension MilestoneEntry {
    /// The feeling picked when the entry was started, if any.
    var feeling: Mood? {
        get { mood.flatMap(Mood.init(rawValue:)) }
        set { mood = newValue?.rawValue }
    }
}
