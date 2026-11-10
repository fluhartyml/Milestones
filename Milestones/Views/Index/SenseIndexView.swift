//
//  SenseIndexView.swift
//  Milestones
//
//  REM: amber B-183.8 (locked 2026-11-09), his word: "yes replace it with the index index sounds more natural."
//  "The Appendix goes; an Index by sense and glyph takes its place" — "tap 'Dog' → every entry with Dog".
//  F-M1: "Index in the top bar." Entries carry senses today (MilestoneEntry.activeSenses) and addenda carry theirs
//  (Addendum.sense); the ready-made glyphs (Dog, Movies or TV…) come with the sense sheets, the next piece, so for
//  now the Index lists the senses that are actually used — never an empty sense. The entry screen shows the Index
//  button only when there is something in it (SenseIndex.hasAnything).
//

import SwiftUI
import SwiftData

/// One line of the Index: a sense (or, later, a glyph) and every entry that has it.
struct SenseIndexItem: Identifiable {
    let id: String
    let name: String
    let glyph: String
    let entries: [MilestoneEntry]
}

enum SenseIndex {
    /// Senses used by entries or their addenda, in the app's sense order, each with its entries newest first.
    static func items(from entries: [MilestoneEntry]) -> [SenseIndexItem] {
        var byID: [String: (name: String, glyph: String, entries: [MilestoneEntry])] = [:]
        var order: [String] = []
        func add(_ id: String, _ name: String, _ glyph: String, _ entry: MilestoneEntry) {
            guard !id.isEmpty else { return }
            if byID[id] == nil { byID[id] = (name, glyph, []); order.append(id) }
            if !(byID[id]!.entries.contains { $0.persistentModelID == entry.persistentModelID }) {
                byID[id]!.entries.append(entry)
            }
        }
        for entry in entries {
            for raw in entry.activeSenses {
                if let sense = SenseType(rawValue: raw) { add(sense.rawValue, sense.displayName, sense.icon, entry) }
            }
            for addendum in entry.addenda ?? [] {
                add(addendum.sense, addendum.senseName, addendum.glyph, entry)
            }
        }
        let known = SenseType.allCases.map(\.rawValue)
        order.sort { (known.firstIndex(of: $0) ?? .max, $0) < (known.firstIndex(of: $1) ?? .max, $1) }
        return order.compactMap { id in
            guard let item = byID[id] else { return nil }
            return SenseIndexItem(id: id, name: item.name, glyph: item.glyph,
                                  entries: item.entries.sorted { $0.eventDate > $1.eventDate })
        }
    }

    static func hasAnything(in entries: [MilestoneEntry]) -> Bool {
        entries.contains { !$0.activeSenses.isEmpty || !($0.addenda ?? []).isEmpty }
    }
}

/// The Index: every sense you've used, with its glyph. Tap one to see every entry that has it.
struct SenseIndexView: View {
    @Query(sort: \MilestoneEntry.eventDate, order: .reverse) private var entries: [MilestoneEntry]
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18

    var body: some View {
        List(SenseIndex.items(from: entries)) { item in
            NavigationLink {
                SenseIndexEntriesView(item: item)
            } label: {
                HStack {
                    Label(item.name, systemImage: item.glyph)
                        .font(.system(size: bodySize, weight: .semibold))
                    Spacer()
                    Text("\(item.entries.count)")
                        .font(.system(size: bodySize))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityLabel(item.name)
            .accessibilityValue(item.entries.count == 1 ? "1 entry" : "\(item.entries.count) entries")
            .accessibilityHint("Shows every entry with \(item.name).")
        }
        .navigationTitle("Index")
    }
}

/// Every entry that has one sense; tap one to open it.
struct SenseIndexEntriesView: View {
    let item: SenseIndexItem
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18

    var body: some View {
        List(item.entries) { entry in
            NavigationLink {
                EntryDetailView(entry: entry)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title.isEmpty ? "Entry" : entry.title)
                        .font(.system(size: bodySize, weight: .semibold))
                    Text(entry.eventDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: bodySize))
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityHint("Opens this entry.")
        }
        .navigationTitle(item.name)
    }
}
