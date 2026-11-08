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

    /// Puts the daily reminder in place at `hour`:`minute`, replacing any earlier one; or removes it when `on` is false.
    static func apply(on: Bool, hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard on else { return }
        let content = UNMutableNotificationContent()
        content.title = "Milestones"
        content.body = "Time to write today's entry."
        content.sound = .default
        var when = DateComponents()
        when.hour = hour
        when.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    /// Whether the daily reminder is waiting in the system (for the robot and for Settings to show the truth).
    static func isScheduled() async -> Bool {
        await UNUserNotificationCenter.current().pendingNotificationRequests().contains { $0.identifier == identifier }
    }
}
