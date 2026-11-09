//
//  NaggingAlarms.swift
//  Milestones
//
//  Amber B-032.2 / B-032.3: Nagging — with Persistent on, a real alarm (Apple's AlarmKit) at a short interval after the
//  daily reminder, until today's entry is written. It sounds on silent and through Focus.
//
// REM: HIS DESIGN 2026-11-06 (B-032.2): "Also shown when Persistent is on: Nagging (off/on). When it's on, a Nagging
// REM: time picker appears below it, a shorter interval." Nagging time 1, 2, 5, 10, 15 (starts at 15, Claude's pick).
// REM: HIS WORD (B-032.3): "if AlarmKit sounds like it can handle both as much as we need" — AlarmKit, no Critical
// REM: Alerts application. "Each app gets an Alarms setup card and an Access Alarms button in Settings (002.2)."
// REM: APPLE'S DOCS (read 2026-11-09, developer.apple.com AlarmKit): iOS / iPadOS 26 and Mac Catalyst only. A plain
// REM: alarm needs no widget extension (that is only for a countdown's Live Activity). NSAlarmKitUsageDescription must be
// REM: in Info.plist or nothing can be scheduled. So Nagging shows on iPhone and iPad (iOS 26+) only; the Mac and Vision
// REM: Pro builds keep Persistent and Snooze.
// REM: Claude's calls (2026-11-09), noted on the sheet: the Alarms card appears the moment Nagging is switched on (when
// REM: the reason is plain — Apple's question follows), not at first launch; today's nags are fixed alarms from the
// REM: reminder time, every Nagging interval, at most 12, rebuilt with the reminder and cancelled when you write.
//

#if os(iOS)
import AlarmKit
import SwiftUI

enum NaggingKeys {
    static let on = "dailyReminderNagging"
    static let minutes = "dailyReminderNaggingMinutes"
    static let scheduled = "dailyReminderNaggingIDs"
}

struct MilestonesNag: AlarmMetadata {}

@available(iOS 26.0, *)
@MainActor
enum NaggingAlarms {
    static let choices = [1, 2, 5, 10, 15]
    static let maxPerDay = 12

    static var minutes: Int {
        let m = UserDefaults.standard.integer(forKey: NaggingKeys.minutes)
        return choices.contains(m) ? m : 15
    }

    enum Access { case notAsked, allowed, denied }

    static var access: Access {
        switch AlarmManager.shared.authorizationState {
        case .authorized: .allowed
        case .denied: .denied
        default: .notAsked
        }
    }

    /// Apple's Alarms question. True when allowed.
    @discardableResult
    static func request() async -> Bool {
        (try? await AlarmManager.shared.requestAuthorization()) == .authorized
    }

    private static var scheduledIDs: [UUID] {
        get { (UserDefaults.standard.stringArray(forKey: NaggingKeys.scheduled) ?? []).compactMap(UUID.init) }
        set { UserDefaults.standard.set(newValue.map(\.uuidString), forKey: NaggingKeys.scheduled) }
    }

    static func cancelAll() {
        for id in scheduledIDs { try? AlarmManager.shared.cancel(id: id) }
        scheduledIDs = []
    }

    /// Today's nags, from the reminder time, every Nagging interval — or none (written today, off, or not allowed).
    static func rebuild(reminderAt start: Date?, writtenToday: Bool) async {
        cancelAll()
        guard let start, !writtenToday, UserDefaults.standard.bool(forKey: NaggingKeys.on), access == .allowed else { return }
        let end = Calendar.current.startOfDay(for: start).addingTimeInterval(24 * 3600)
        let stop = AlarmButton(text: "Done", textColor: .white, systemImageName: "checkmark.circle")
        let alert = AlarmPresentation.Alert(title: "Time to write today\u{2019}s entry.", stopButton: stop)
        let attributes = AlarmAttributes<MilestonesNag>(presentation: AlarmPresentation(alert: alert), tintColor: .orange)
        var ids: [UUID] = []
        for n in 1...maxPerDay {
            let at = start.addingTimeInterval(TimeInterval(n * minutes * 60))
            guard end > at, at > Date.now else { continue }
            let id = UUID()
            if (try? await AlarmManager.shared.schedule(id: id, configuration: .alarm(schedule: .fixed(at), attributes: attributes))) != nil {
                ids.append(id)
            }
        }
        scheduledIDs = ids
    }
}

/// Settings: Nagging under Persistent, its time, and Access Alarms (002.2: see it, and take it back).
@available(iOS 26.0, *)
struct NaggingSection: View {
    @AppStorage(NaggingKeys.on) private var nagging = false
    @AppStorage(NaggingKeys.minutes) private var minutes = 15
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var access = NaggingAlarms.access
    @State private var showCard = false
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18

    var body: some View {
        Toggle(isOn: Binding(get: { nagging }, set: { turn($0) })) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Nagging").font(.system(size: bodySize, weight: .semibold))
                Text("A real alarm, even on silent, until you write today\u{2019}s entry.").font(.system(size: bodySize))
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("reminderNagging")
        if nagging {
            Picker(selection: Binding(get: { NaggingAlarms.choices.contains(minutes) ? minutes : 15 },
                                      set: { minutes = $0; Task { await ReminderService.refresh() } })) {
                ForEach(NaggingAlarms.choices, id: \.self) { m in
                    Text("\(m) min").font(.system(size: bodySize)).tag(m)
                }
            } label: {
                Text("Nagging time").font(.system(size: bodySize))
            }
            .accessibilityIdentifier("reminderNaggingTime")
        }
        VStack(alignment: .leading, spacing: 8) {
            Label(access == .allowed ? "Alarms are on" : access == .denied ? "Alarms are off" : "Alarms not asked yet",
                  systemImage: access == .allowed ? "checkmark.circle.fill" : access == .denied ? "xmark.circle.fill" : "questionmark.circle")
                .font(.system(size: bodySize, weight: .semibold))
                .foregroundStyle(access == .allowed ? Color.green : Color.secondary)
                .accessibilityIdentifier("alarmsStatus")
            Button(action: accessAlarms) {
                Text("Access Alarms").font(.system(size: bodySize, weight: .semibold))
                    .foregroundStyle(SettingsView.buttonBlue)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("accessAlarms")
            .accessibilityHint(access == .notAsked ? "Brings up Apple's Alarms question." : "Opens the Settings app.")
        }
        .sheet(isPresented: $showCard) { AlarmsOfferView { allowed in
            showCard = false
            access = NaggingAlarms.access
            if allowed { nagging = true; Task { await ReminderService.refresh() } }
        } }
        .onChange(of: scenePhase) { _, phase in if phase == .active { access = NaggingAlarms.access } }
    }

    private func turn(_ on: Bool) {
        guard on else { nagging = false; Task { await ReminderService.refresh() }; return }
        if NaggingAlarms.access == .allowed { nagging = true; Task { await ReminderService.refresh() } }
        else if NaggingAlarms.access == .notAsked { showCard = true }
        else { accessAlarms() }
    }

    private func accessAlarms() {
        if NaggingAlarms.access == .notAsked {
            Task { await NaggingAlarms.request(); access = NaggingAlarms.access }
            return
        }
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
    }
}

/// The Alarms setup card (B-032.3) — shown when Nagging is first switched on.
@available(iOS 26.0, *)
struct AlarmsOfferView: View {
    let done: (Bool) -> Void
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .title) private var titleSize: CGFloat = 28
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 56

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "alarm.fill")
                    .font(.system(size: iconSize))
                    .foregroundStyle(SettingsView.buttonBlue)
                    .accessibilityHidden(true)
                Text("Let Milestones set alarms?")
                    .font(.system(size: titleSize, weight: .bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text("Nagging uses a real alarm. It sounds even on silent and during Focus, every few minutes until you write today\u{2019}s entry. Apple asks first, and you can change it any time in Settings.")
                    .font(.system(size: bodySize))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    Task { done(await NaggingAlarms.request()) }
                } label: {
                    Text("Allow Alarms")
                        .font(.system(size: bodySize, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(LockOfferView.fill, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("alarmsOn")
                Button { done(false) } label: {
                    Text("Not Now")
                        .font(.system(size: bodySize))
                        .foregroundStyle(SettingsView.buttonBlue)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("alarmsSkip")
            }
            .padding(24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }
}
#endif
