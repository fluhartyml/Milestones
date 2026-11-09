//
//  WritingRings.swift
//  Milestones
//
//  The day-by-day header and the monthly ring — writing streaks (amber 007 / 007.1, 022, 022.1).
//
//  REM: his word 2026-11-06, lines 007 / 007.1 ("both apps"): a day-by-day header, "Today, Fri 11/6", back and forward
//  REM: arrows and a row of seven small day rings (ActivityTracker, IMG_0778) — "Milestones: each ring shows whether you
//  REM: wrote an entry that day." Line 022 ("yes for both apps"): a monthly ring (IMG_0783). Line 022.1: "Milestones'
//  REM: rings (007 and 022) are logging streaks, counting the days you wrote an entry. Milestones gets no habit
//  REM: tracking" (habits are a separate ADL app, not built).
//  REM: Claude's calls, noted on the sheet: a day counts by when you WROTE (createdAt), not the date the entry is about
//  REM: (eventDate) — a milestone can be about any day. Tapping a ring shows the entries written that day; tap it again
//  REM: or Show All for the whole journal. The month's goal is 12 days, the same as Legend's Monthly Challenge (Legend 98).
//  REM: Rings are 44-point tap targets with a spoken label; text is 18 pt and grows with your text size (his 18 pt rule).
//

import SwiftUI

struct WritingRings: View {
    /// When each entry was written.
    let writtenDays: Set<Date>
    @Binding var selectedDay: Date?
    @State private var weekEnd = Calendar.current.startOfDay(for: .now)

    static let monthGoal = 12

    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .headline) private var headingSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var ringSize: CGFloat = 32

    private var calendar: Calendar { .current }
    private var today: Date { calendar.startOfDay(for: .now) }
    private var week: [Date] { (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: weekEnd) } }
    private var shownDay: Date { selectedDay ?? weekEnd }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button { move(-7) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .accessibilityLabel("Earlier week")
                Spacer()
                Text(title(for: shownDay))
                    .font(.system(size: headingSize, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("dayHeader")
                Spacer()
                Button { move(7) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                    .disabled(weekEnd >= today)
                    .accessibilityLabel("Later week")
            }
            .buttonStyle(.plain)
            .foregroundStyle(SettingsView.buttonBlue)

            HStack(spacing: 0) {
                ForEach(week, id: \.self) { day in dayRing(day) }
            }

            monthRing

            if selectedDay != nil {
                Button("Show All Entries") { selectedDay = nil }
                    .font(.system(size: bodySize))
                    .foregroundStyle(SettingsView.buttonBlue)
                    .frame(minHeight: 44)
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("showAllEntries")
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 6)
    }

    private func dayRing(_ day: Date) -> some View {
        let wrote = writtenDays.contains(day)
        let chosen = selectedDay == day
        return Button {
            selectedDay = chosen ? nil : day
        } label: {
            VStack(spacing: 4) {
                Text(day.formatted(.dateTime.weekday(.narrow)))
                    .font(.system(size: bodySize))
                    .foregroundStyle(.secondary)
                ZStack {
                    Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 3)
                    if wrote { Circle().fill(Color.green) ; Image(systemName: "checkmark").font(.system(size: ringSize * 0.45, weight: .bold)).foregroundStyle(.white) }
                }
                .frame(width: ringSize, height: ringSize)
                .overlay { if chosen { Circle().stroke(SettingsView.buttonBlue, lineWidth: 3).padding(-4) } }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(day > today)
        .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide).month().day())), \(wrote ? "you wrote" : "nothing written")")
        .accessibilityHint(chosen ? "Shows all entries again." : "Shows the entries you wrote that day.")
        .accessibilityIdentifier("dayRing")
    }

    private var monthRing: some View {
        let month = calendar.dateInterval(of: .month, for: today)
        let count = writtenDays.filter { month?.contains($0) ?? false }.count
        let monthName = today.formatted(.dateTime.month(.wide))
        return HStack(spacing: 12) {
            ZStack {
                Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 6)
                Circle().trim(from: 0, to: min(1, Double(count) / Double(Self.monthGoal)))
                    .stroke(count >= Self.monthGoal ? Color.green : SettingsView.buttonBlue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: ringSize * 1.4, height: ringSize * 1.4)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Write on \(Self.monthGoal) days in \(monthName)").font(.system(size: bodySize, weight: .semibold))
                Text("\(count)/\(Self.monthGoal)").font(.system(size: bodySize)).monospacedDigit().foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("monthRing")
        }
    }

    private func title(for day: Date) -> String {
        let date = day.formatted(.dateTime.weekday(.abbreviated).month(.defaultDigits).day())
        return calendar.isDate(day, inSameDayAs: today) ? "Today, \(date)" : date
    }

    private func move(_ days: Int) {
        guard let next = calendar.date(byAdding: .day, value: days, to: weekEnd) else { return }
        weekEnd = min(next, today)
        selectedDay = nil
    }
}
