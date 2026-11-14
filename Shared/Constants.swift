//
//  Constants.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import Foundation

// REM: amber B-031.5 — the Share extension downsizes shared photos with the same size and quality the app uses, so this
// file is in both targets (Shared/). nonisolated so the extension can read it while it works off the main thread.
nonisolated enum AppConstants {

    /// App display name
    static let appName = "Milestones"

    /// Tagline
    static let tagline = "Because your life isn't one moment — it's all of them."

    /// Maximum photo size in pixels before compression
    static let maxPhotoSize: CGFloat = 2048

    /// JPEG compression quality for stored photos
    static let photoCompressionQuality: CGFloat = 0.8

    /// Default milestone suggestions for new users
    static let suggestedMilestones: [(title: String, description: String)] = [
        ("Birthday", "The day you were born"),
        ("Today", "The day you started your journal"),
    ]
}
