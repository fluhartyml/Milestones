//
//  Badges.swift
//  Milestones
//
//  Journal → Badges: round embroidered patches that light up when you earn them, and a pop-up the moment you earn one.
//
//  REM: amber A-023 / A-023.1, his word 2026-11-06: "both apps and we could use image playground and or image producer to
//  REM: make them" — "Milestones: first entry, writing streaks, entry counts." A-023.2, his idea 2026-11-06: Milestones'
//  REM: badges are "scouts inspired": round embroidered merit-badge patches, as "a whimsical bonus." Shipped art and text
//  REM: stay generic — no scouting organization's name, emblem or badge designs (trademarks).
//  REM: The patch is drawn: a colored disc, a dashed "stitched" ring inside its edge, a thick rolled border. The middle
//  REM: shows an Apple symbol until his Image Playground art goes in its slot (never stock or brand art; his files placed
//  REM: byte for byte). Same pattern as Legend 99 (Legend Badges.swift).
//  REM: Claude's calls, noted on the sheet: the list is First Entry, 3-, 7- and 30-day writing streaks, 10 and 100
//  REM: entries, and Full Monthly Ring (the 12-day goal from WritingRings.swift). A day counts by when you wrote (createdAt).
//  REM: Earned badges are kept on this device and stay earned even if entries are deleted.
//  REM: Text is 18 pt at the default size and grows with your text size (his 18 pt rule).
//

import SwiftData
import SwiftUI

enum JournalBadge: String, CaseIterable, Identifiable {
    case firstEntry, streak3, streak7, streak30, entries10, entries100, fullMonth
    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstEntry: "First Entry"
        case .streak3: "3-Day Streak"
        case .streak7: "7-Day Streak"
        case .streak30: "30-Day Streak"
        case .entries10: "10 Entries"
        case .entries100: "100 Entries"
        case .fullMonth: "Full Monthly Ring"
        }
    }
    var how: String {
        switch self {
        case .firstEntry: "Write your first entry."
        case .streak3: "Write on 3 days in a row."
        case .streak7: "Write on 7 days in a row."
        case .streak30: "Write on 30 days in a row."
        case .entries10: "Write 10 entries."
        case .entries100: "Write 100 entries."
        case .fullMonth: "Write on \(WritingRings.monthGoal) days in one month."
        }
    }
    var symbol: String {
        switch self {
        case .firstEntry: "pencil"
        case .streak3: "flame"
        case .streak7: "flame.fill"
        case .streak30: "sun.max.fill"
        case .entries10: "book.closed.fill"
        case .entries100: "books.vertical.fill"
        case .fullMonth: "moon.stars.fill"
        }
    }
    /// The patch's cloth color.
    var cloth: Color {
        switch self {
        case .firstEntry: Color(red: 0.16, green: 0.42, blue: 0.24)
        case .streak3, .streak7, .streak30: Color(red: 0.62, green: 0.20, blue: 0.12)
        case .entries10, .entries100: Color(red: 0.10, green: 0.25, blue: 0.55)
        case .fullMonth: Color(red: 0.38, green: 0.18, blue: 0.50)
        }
    }

    static let storageKey = "earnedJournalBadges"

    /// The badges these entries earn right now.
    static func earned(by entries: [MilestoneEntry]) -> Set<JournalBadge> {
        var set: Set<JournalBadge> = []
        if !entries.isEmpty { set.insert(.firstEntry) }
        if entries.count >= 10 { set.insert(.entries10) }
        if entries.count >= 100 { set.insert(.entries100) }
        let days = Set(entries.map { Calendar.current.startOfDay(for: $0.createdAt) })
        let streak = longestStreak(days)
        if streak >= 3 { set.insert(.streak3) }
        if streak >= 7 { set.insert(.streak7) }
        if streak >= 30 { set.insert(.streak30) }
        let byMonth = Dictionary(grouping: days) { Calendar.current.dateInterval(of: .month, for: $0)?.start ?? $0 }
        if byMonth.values.contains(where: { $0.count >= WritingRings.monthGoal }) { set.insert(.fullMonth) }
        return set
    }

    /// The most days in a row with at least one entry written.
    static func longestStreak(_ days: Set<Date>) -> Int {
        let cal = Calendar.current
        var best = 0
        for day in days {
            guard let before = cal.date(byAdding: .day, value: -1, to: day), !days.contains(before) else { continue }
            var run = 1, next = day
            while let after = cal.date(byAdding: .day, value: 1, to: next), days.contains(after) { run += 1; next = after }
            best = max(best, run)
        }
        return best
    }

    static func decode(_ stored: String) -> Set<JournalBadge> { Set(stored.split(separator: ",").compactMap { JournalBadge(rawValue: String($0)) }) }
    static func encode(_ set: Set<JournalBadge>) -> String { allCases.filter(set.contains).map(\.rawValue).joined(separator: ",") }
}

/// One round embroidered patch.
struct BadgePatch: View {
    let badge: JournalBadge
    let earned: Bool
    @ScaledMetric(relativeTo: .title) private var size: CGFloat = 110

    var body: some View {
        let cloth = earned ? badge.cloth : Color.gray.opacity(0.35)
        ZStack {
            Circle().fill(cloth)
            // The rolled border.
            Circle().stroke(earned ? Color(red: 0.85, green: 0.72, blue: 0.35) : Color.gray.opacity(0.5), lineWidth: size * 0.07)
            // The stitches just inside it.
            Circle().inset(by: size * 0.11)
                .stroke(Color.white.opacity(earned ? 0.75 : 0.35), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
            Image(systemName: badge.symbol)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(.white.opacity(earned ? 1 : 0.5))
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(earned ? 0.25 : 0), radius: 3, y: 2)
        .accessibilityHidden(true)
    }
}

/// Watches for newly earned badges and shows the pop-up. Attach to the Journal.
struct JournalBadgeWatcher: ViewModifier {
    let entries: [MilestoneEntry]
    @AppStorage(JournalBadge.storageKey) private var stored = ""
    @State private var justEarned: JournalBadge?

    func body(content: Content) -> some View {
        content
            .task(id: entries.count) { check() }
            .alert(justEarned.map { "You earned \($0.title)" } ?? "",
                   isPresented: Binding(get: { justEarned != nil }, set: { if !$0 { justEarned = nil } })) {
                Button("OK") { justEarned = nil }
            } message: {
                Text(justEarned?.how ?? "")
            }
    }

    private func check() {
        let had = JournalBadge.decode(stored)
        let now = had.union(JournalBadge.earned(by: entries))
        guard now != had else { return }
        stored = JournalBadge.encode(now)
        justEarned = JournalBadge.allCases.last { now.contains($0) && !had.contains($0) }
    }
}

struct JournalBadgesScreen: View {
    @AppStorage(JournalBadge.storageKey) private var stored = ""
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18

    var body: some View {
        let earned = JournalBadge.decode(stored)
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 20) {
                ForEach(JournalBadge.allCases) { badge in
                    let on = earned.contains(badge)
                    VStack(spacing: 8) {
                        BadgePatch(badge: badge, earned: on)
                        Text(badge.title).font(.system(size: bodySize, weight: .semibold)).multilineTextAlignment(.center)
                        Text(on ? "Earned" : badge.how).font(.system(size: bodySize)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("badge-\(badge.rawValue)")
                }
            }
            .padding()
        }
        .navigationTitle("Badges")
    }
}
