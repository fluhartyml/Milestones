//
//  SenseIndexView.swift
//  Milestones
//
//  REM: amber B-183.8 (locked 2026-11-09), his word: "yes replace it with the index index sounds more natural."
//  "The Appendix goes; an Index by sense and glyph takes its place" — "tap 'Dog' → every entry with Dog".
//  F-M1: "Index in the top bar." The Index is also the tab where the Appendix was (ContentView).
//  Senses come from what entries used: the old sense tiles (MilestoneEntry.activeSenses), addenda (Addendum.sense)
//  and stickers (EntrySticker.sense). Glyphs come from the stickers stamped on entries (B-183.7.3), by name, so
//  "Dog" lists every entry with a Dog sticker. Only what is actually used is listed — never an empty line.
//

import SwiftUI
import SwiftData

/// One line of the Index: a sense or a glyph, and every entry that has it.
struct SenseIndexItem: Identifiable {
    let id: String
    let name: String
    let glyph: String
    let entries: [MilestoneEntry]
}

enum SenseIndex {
    /// Collects lines in first-seen order, each entry once per line.
    private struct Collector {
        var byID: [String: (name: String, glyph: String, entries: [MilestoneEntry])] = [:]
        var order: [String] = []

        mutating func add(_ id: String, _ name: String, _ glyph: String, _ entry: MilestoneEntry) {
            guard !id.isEmpty else { return }
            if byID[id] == nil { byID[id] = (name, glyph, []); order.append(id) }
            if !(byID[id]!.entries.contains { $0.persistentModelID == entry.persistentModelID }) {
                byID[id]!.entries.append(entry)
            }
        }

        func items() -> [SenseIndexItem] {
            order.compactMap { id in
                guard let item = byID[id] else { return nil }
                return SenseIndexItem(id: id, name: item.name, glyph: item.glyph,
                                      entries: item.entries.sorted { $0.eventDate > $1.eventDate })
            }
        }
    }

    /// Senses used by entries, their addenda and their stickers, in the senses bar's order, each with its entries
    /// newest first.
    static func senses(from entries: [MilestoneEntry], bar: [SenseButton]) -> [SenseIndexItem] {
        var collector = Collector()
        for entry in entries {
            // REM: MF-001 / MF-005, his words: "There are only five senses" — anything stored under the retired
            // Balance / Body ids is listed under Touch (SenseType.shownID); the stored ids are left as they are.
            for raw in entry.activeSenses {
                if let sense = SenseType(stored: raw) { collector.add(sense.rawValue, sense.displayName, sense.icon, entry) }
            }
            for addendum in entry.addenda ?? [] {
                collector.add(SenseType.shownID(addendum.sense), addendum.shownSenseName, addendum.shownGlyph, entry)
            }
            for sticker in entry.stickers ?? [] {
                let id = SenseType.shownID(sticker.sense)
                let button = bar.first { $0.id == id }
                collector.add(id, button?.name ?? sticker.shownSenseName,
                              button?.glyph ?? SenseType(stored: sticker.sense)?.icon ?? "sparkles", entry)
            }
        }
        let known = bar.map(\.id) + SenseType.allCases.map(\.rawValue)
        collector.order.sort { (known.firstIndex(of: $0) ?? .max, $0) < (known.firstIndex(of: $1) ?? .max, $1) }
        return collector.items()
    }

    /// Glyphs stamped on entries, by name (two Dog stickers from different senses are one "Dog"), A to Z.
    static func glyphs(from entries: [MilestoneEntry]) -> [SenseIndexItem] {
        var collector = Collector()
        for entry in entries {
            for sticker in entry.sortedStickers {
                let name = sticker.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { continue }
                collector.add("glyph:" + name.lowercased(), name, sticker.symbol, entry)
            }
        }
        return collector.items().sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func hasAnything(in entries: [MilestoneEntry]) -> Bool {
        entries.contains {
            !$0.activeSenses.isEmpty || !($0.addenda ?? []).isEmpty || !($0.stickers ?? []).isEmpty
        }
    }
}

/// The Index: every sense and glyph you've used. Tap one to see every entry that has it.
struct SenseIndexView: View {
    @Query(sort: \MilestoneEntry.eventDate, order: .reverse) private var entries: [MilestoneEntry]
    @State private var store = SenseBarStore.shared
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18

    var body: some View {
        let senses = SenseIndex.senses(from: entries, bar: store.buttons)
        let glyphs = SenseIndex.glyphs(from: entries)
        Group {
            if senses.isEmpty && glyphs.isEmpty {
                ContentUnavailableView {
                    Label("Nothing Indexed Yet", systemImage: "list.bullet.indent")
                } description: {
                    Text("Tap a sense at the bottom of an entry and stamp a glyph or add a picture, a recording or words. It shows up here.")
                        .font(.system(size: bodySize))
                }
            } else {
                List {
                    if !senses.isEmpty {
                        Section {
                            ForEach(senses) { row($0) }
                        } header: {
                            Text("Senses").font(.system(size: bodySize))
                        }
                    }
                    if !glyphs.isEmpty {
                        Section {
                            ForEach(glyphs) { row($0) }
                        } header: {
                            Text("Glyphs").font(.system(size: bodySize))
                        }
                    }
                }
            }
        }
        .navigationTitle("Index")
    }

    private func row(_ item: SenseIndexItem) -> some View {
        NavigationLink {
            SenseIndexEntriesView(item: item)
        } label: {
            HStack {
                Label(item.name, systemImage: item.glyph.isEmpty ? "sparkles" : item.glyph)
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
}

/// The Index tab, where the Appendix tab was (B-183.8).
struct IndexTab: View {
    var body: some View {
        NavigationStack {
            SenseIndexView()
        }
    }
}

/// Every entry that has one sense or glyph; tap one to open it.
struct SenseIndexEntriesView: View {
    let item: SenseIndexItem
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18

    var body: some View {
        List(item.entries) { entry in
            NavigationLink {
                EntryDetailView(entry: entry)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.displayTitle)
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
