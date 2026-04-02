//
//  SenseType.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import Foundation

/// The seven senses that can be tagged on a journal entry.
enum SenseType: String, CaseIterable, Identifiable, Codable {
    case sight
    case hearing
    case touch
    case smell
    case taste
    case vestibular
    case proprioception

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sight: "Sight"
        case .hearing: "Hearing"
        case .touch: "Touch"
        case .smell: "Smell"
        case .taste: "Taste"
        case .vestibular: "Vestibular"
        case .proprioception: "Proprioception"
        }
    }

    var icon: String {
        switch self {
        case .sight: "eye"
        case .hearing: "ear"
        case .touch: "hand.raised"
        case .smell: "nose"
        case .taste: "mouth"
        case .vestibular: "figure.walk"
        case .proprioception: "heart"
        }
    }

    var description: String {
        switch self {
        case .sight: "What do you see?"
        case .hearing: "What do you hear?"
        case .touch: "What do you feel?"
        case .smell: "What do you smell?"
        case .taste: "What do you taste?"
        case .vestibular: "How are you moving?"
        case .proprioception: "How does your body feel?"
        }
    }

    /// Which senses are available in v1.0 (user-input senses)
    static var v1Senses: [SenseType] {
        [.sight, .touch, .smell, .taste]
    }

    /// Which senses require hardware/frameworks beyond v1.0
    static var futureSenses: [SenseType] {
        [.hearing, .vestibular, .proprioception]
    }
}
