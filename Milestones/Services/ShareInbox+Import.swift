//
//  ShareInbox+Import.swift
//  Milestones
//
//  REM: amber B-031.3 / B-031.5 — the app's half of the Share extension (see Shared/ShareInbox.swift).
//  B-031.3: shared text "opens it as a new entry for the person to edit and save" — the words become the entry text.
//  B-031.5: "if a group of photos, even if just one photo, you get to add an entry or description of the photo
//  stack" — the photos become the entry's photo stack (sightPhotos, the same stack the Sight box shows) and what you
//  wrote about them is the entry text. Same MilestoneEntry model as every other entry; no second model.
//

import Foundation
import SwiftData

extension ShareInbox {

    /// Turns every waiting share into a new entry, saved. Returns the newest one (to open), nil when none waited.
    @MainActor
    static func takeAll(into context: ModelContext) -> MilestoneEntry? {
        var newest: MilestoneEntry?
        for pending in pending() {
            let entry = MilestoneEntry(eventDate: pending.item.sharedAt, title: "", body: pending.item.text)
            // The day you shared it is the day you wrote it (the writing rings count it there).
            entry.createdAt = pending.item.sharedAt
            let photos = photos(of: pending)
            if !photos.isEmpty { entry.sightPhotos = photos }
            context.insert(entry)
            do {
                try context.save()
            } catch {
                // Not saved: the share stays in the inbox and is tried again next time the app comes to the front.
                context.delete(entry)
                break
            }
            remove(pending)
            newest = entry
        }
        return newest
    }
}
