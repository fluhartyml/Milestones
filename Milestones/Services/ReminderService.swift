//
//  ReminderService.swift
//  Milestones
//
//  The daily reminder: "Time to write today's entry." at a time you set (amber sheet line 032).
//
//  REM: his word 2026-11-06, line 032: "A daily reminder at a time you set, with more reminders addable later, all
//  editable in Settings. Milestones: 'Time to write today's entry.'" This is the first piece: one daily reminder.
//  Snooze, Persistent and Nagging (032.1–032.3, AlarmKit) come next, each its own build (his one-piece-at-a-time rule).
//  REM: Apple's notification permission is asked the moment you turn the reminder on — that's when the reason is plain.
//  REM: everything stays on this device; the reminder is a local notification, nothing is sent anywhere.
//

import Foundation
import UserNotifications

enum ReminderKeys {
    static let on = "dailyReminderOn"
    static let hour = "dailyReminderHour"
    static let minute = "dailyReminderMinute"
    static let persistent = "dailyReminderPersistent"
    static let snoozeMinutes = "dailyReminderSnoozeMinutes"
    /// The last day an entry was written ("2026-11-07"), so the repeats know to stop.
    static let writtenDay = "dailyReminderWrittenDay"
}

@MainActor
enum ReminderService {
    static let identifier = "milestones.dailyReminder"

    /// The permission as Apple reports it.
    static func status() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Asks Apple's question if it hasn't been asked. True when reminders may be shown.
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        if await status() == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
        let now = await status()
        #if os(macOS)
        return now == .authorized || now == .provisional
        #else
        return now == .authorized || now == .provisional || now == .ephemeral
        #endif
    }

    // MARK: - 032.1 / 032.2 — Snooze and Persistent
    // REM: his revise 2026-11-06 (032.1): "should have a snooze and it can ask if the user wants a persistent reminder after
    // REM: the snooze." His design (032.2): Persistent (off/on); when on, a Snooze time picker appears below it, and the
    // REM: reminder comes back at that interval until you've written. Snooze times 5, 10, 15, 30, 60 (starts at 60).
    // REM: "until you've written" = an entry dated today exists. Repeats are dated one-offs for today and tomorrow (iOS keeps
    // REM: at most 64 waiting), at most 12 a day, rebuilt whenever the app comes to the front or you write an entry.

    static let snoozeChoices = [5, 10, 15, 30, 60]
    static let category = "milestones.reminder"
    static let snoozedCategory = "milestones.reminder.snoozed"
    static let snoozeAction = "milestones.snooze"
    static let keepRemindingAction = "milestones.keepReminding"
    private static let followUpPrefix = "milestones.followUp."
    private static let snoozedID = "milestones.snoozed"
    private static let maxPerDay = 12

    private static var defaults: UserDefaults { .standard }
    private static var persistent: Bool { defaults.bool(forKey: ReminderKeys.persistent) }
    private static var snoozeMinutes: Int {
        let m = defaults.integer(forKey: ReminderKeys.snoozeMinutes); return snoozeChoices.contains(m) ? m : 60
    }

    /// The Snooze button on the reminder; Keep Reminding Me on a snoozed one (it's the "ask" of 032.1).
    static func registerCategories() {
        let snooze = UNNotificationAction(identifier: snoozeAction, title: "Snooze")
        let keep = UNNotificationAction(identifier: keepRemindingAction, title: "Keep Reminding Me")
        UNUserNotificationCenter.current().setNotificationCategories([
            UNNotificationCategory(identifier: category, actions: [snooze], intentIdentifiers: []),
            UNNotificationCategory(identifier: snoozedCategory, actions: [snooze, keep], intentIdentifiers: []),
        ])
    }

    private static func content(snoozed: Bool) -> UNMutableNotificationContent {
        let c = UNMutableNotificationContent()
        c.title = "Milestones"
        c.body = snoozed ? "Time to write today's entry. Want Milestones to keep reminding you until you do?"
                         : "Time to write today's entry."
        c.sound = .default
        c.categoryIdentifier = snoozed ? snoozedCategory : category
        return c
    }

    /// Snooze tapped: the reminder comes back in the snooze time, and asks about Persistent.
    static func snooze() async {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(snoozeMinutes * 60), repeats: false)
        try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: snoozedID, content: content(snoozed: true), trigger: trigger))
    }

    /// Keep Reminding Me tapped: Persistent goes on (Settings shows it, and can turn it off — 002.2).
    static func keepReminding() async {
        defaults.set(true, forKey: ReminderKeys.persistent)
        await refresh(writtenToday: false)
    }

    /// Today's date as a key, so "written today" survives relaunches.
    private static var todayKey: String { Date.now.formatted(.iso8601.year().month().day()) }

    /// You wrote an entry: today's repeats stop (tomorrow's stay).
    static func entryWritten() async {
        defaults.set(todayKey, forKey: ReminderKeys.writtenDay)
        await refresh(writtenToday: true)
    }

    /// Rebuilds the reminder and its repeats from Settings. Call at launch, on return to the app, and on any change.
    static func refresh(writtenToday: Bool? = nil) async {
        let on = defaults.bool(forKey: ReminderKeys.on)
        let hour = defaults.object(forKey: ReminderKeys.hour) as? Int ?? 20
        let minute = defaults.integer(forKey: ReminderKeys.minute)
        let written = writtenToday ?? (defaults.string(forKey: ReminderKeys.writtenDay) == todayKey)
        let center = UNUserNotificationCenter.current()
        let old = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(followUpPrefix) || $0 == identifier }
        center.removePendingNotificationRequests(withIdentifiers: old)
        if written { center.removePendingNotificationRequests(withIdentifiers: [snoozedID]) }
        guard on else { center.removePendingNotificationRequests(withIdentifiers: [snoozedID]); return }

        // The daily reminder itself, every day.
        let daily = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: minute), repeats: true)
        try? await center.add(UNNotificationRequest(identifier: identifier, content: content(snoozed: false), trigger: daily))

        guard persistent else { return }
        let calendar = Calendar.current
        for dayOffset in 0...1 {
            if dayOffset == 0 && written { continue }
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: .now)),
                  let start = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  let end = calendar.date(byAdding: .day, value: 1, to: day) else { continue }
            for n in 1...maxPerDay {
                let at = start.addingTimeInterval(TimeInterval(n * snoozeMinutes * 60))
                guard end > at, at > Date.now else { continue }
                let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: at)
                let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
                try? await center.add(UNNotificationRequest(identifier: "\(followUpPrefix)\(dayOffset).\(n)",
                                                            content: content(snoozed: false), trigger: trigger))
            }
        }
    }

    /// Kept for Settings: the switch and time call this.
    static func apply(on: Bool, hour: Int, minute: Int) async { await refresh() }

    /// Whether the daily reminder is waiting in the system (for the robot and for Settings to show the truth).
    static func isScheduled() async -> Bool {
        await UNUserNotificationCenter.current().pendingNotificationRequests().contains { $0.identifier == identifier }
    }
}

/// Answers the reminder's buttons, and shows reminders even while Milestones is open.
final class ReminderDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ReminderDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        switch response.actionIdentifier {
        case ReminderService.snoozeAction: await ReminderService.snooze()
        case ReminderService.keepRemindingAction: await ReminderService.keepReminding()
        default: break
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions { [.banner, .sound] }
}
