//
//  SenseType.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import Foundation

/// The five senses that can be tagged on a journal entry.
// REM: MF-001 / MF-005, his words (TestFlight build 30): "There are only five senses" / "only five human sinces exist
// the last two are too clinical for this app and fall under one of the five other sences". Balance and Body
// (vestibular / proprioception) are no longer senses anywhere you can see or pick one. You can still make your own
// sense in Edit Senses (SenseBarStore.addSense); the app just never ships those two as built-ins.
enum SenseType: String, CaseIterable, Identifiable, Codable {
    case sight
    case hearing
    case touch
    case smell
    case taste

    var id: String { rawValue }

    // REM: MF-001 — "fall under one of the five other sences". Anything stored under the two old ids (an entry's
    // activeSenses, an addendum's or a sticker's sense) is kept exactly as stored and shown under Touch, the closest of
    // the five: "Body" asked "How does your body feel?" and "Balance" asked "How are you moving?" — both are felt.
    // Claude's call (the conservative one): fold both into Touch; nothing stored is rewritten or deleted.
    static let retiredIDs: [String: SenseType] = ["vestibular": .touch, "proprioception": .touch]

    /// A stored sense id, read as one of the five (the two retired ids fold into Touch). Nil for a sense you made.
    init?(stored raw: String) {
        if let sense = SenseType(rawValue: raw) {
            self = sense
        } else if let folded = Self.retiredIDs[raw] {
            self = folded
        } else {
            return nil
        }
    }

    /// The id a stored sense is shown under: the retired ids become "touch"; everything else is unchanged.
    static func shownID(_ raw: String) -> String {
        retiredIDs[raw]?.rawValue ?? raw
    }

    var displayName: String {
        switch self {
        case .sight: "Sight"
        case .hearing: "Hearing"
        case .touch: "Touch"
        case .smell: "Smell"
        case .taste: "Taste"
        }
    }

    var icon: String {
        switch self {
        case .sight: "eye"
        case .hearing: "ear"
        case .touch: "hand.raised"
        case .smell: "nose"
        case .taste: "mouth"
        }
    }

    var description: String {
        switch self {
        case .sight: "What do you see?"
        case .hearing: "What do you hear?"
        case .touch: "What do you feel?"
        case .smell: "What do you smell?"
        case .taste: "What do you taste?"
        }
    }
}
