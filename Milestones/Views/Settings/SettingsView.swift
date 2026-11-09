//
//  SettingsView.swift
//  Milestones
//
//  Settings: the Access Location button (amber sheet line 001.12) and its status.
//
//  REM: his word 2026-11-06, line 001.12: "ask for Location when the app first launches. If you tap
//  Don't Allow by accident, Settings has an Access Location button." The first-launch ask already
//  happens: the Contents tab is the first screen and calls requestPermission() on appear.
//  REM: his rule 2026-11-06, line 002.2, every app: "in settings you should always be able to change
//  your mind and take back a permission." So the button works in every state, not only after a no:
//    - not asked yet  -> brings up Apple's pop-up
//    - on, or off     -> opens Milestones' page in the Settings app (iPhone, iPad, Vision Pro) or
//                        Location Services in System Settings (Mac), where you flip it yourself.
//  REM: why it can't flip Location itself: Apple lets an app open its own Settings page, never the
//  Location switch, and never turn its own permission off. Once you've said no, Apple won't show the
//  pop-up again, so opening Settings is the only path back.
//  REM: where Settings lives: a tab on iPhone, iPad and Vision Pro; the Settings window (Command-comma)
//  on the Mac, Apple's standard place for an app's settings there.
//  REM: text is 18 pt at the default size and grows with your text size (his 18 pt rule).
//

import CoreLocation
import UserNotifications
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {

    @State private var location = LocationService()
    // REM: line 002.1 — "In both apps you can change the name in Settings." Edits save as you type.
    @AppStorage(UserNameKeys.name) private var userName = ""
    // REM: line 032 — the daily reminder. 8 PM to start (Claude's pick); you change it here.
    @AppStorage(ReminderKeys.on) private var reminderOn = false
    @AppStorage(ReminderKeys.hour) private var reminderHour = 20
    @AppStorage(ReminderKeys.minute) private var reminderMinute = 0
    @AppStorage(ReminderKeys.persistent) private var reminderPersistent = false
    @AppStorage(ReminderKeys.snoozeMinutes) private var snoozeMinutes = 60
    @State private var notificationsOff = false
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .headline) private var headingSize: CGFloat = 20

    var body: some View {
        #if os(macOS)
        form
            .frame(minWidth: 460, minHeight: 300)
        #else
        NavigationStack {
            form
                .navigationTitle("Settings")
        }
        #endif
    }

    private var form: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("Location").font(.system(size: headingSize, weight: .semibold))
                    } icon: {
                        Image(systemName: "location.fill").foregroundStyle(.tint)
                    }

                    Text("Milestones uses your location to mark where each entry was written and to add the local weather.")
                        .font(.system(size: bodySize))

                    Label(state.words, systemImage: state.symbol)
                        .font(.system(size: bodySize, weight: .semibold))
                        .foregroundStyle(state.isOn ? Color.green : Color.secondary)
                        .accessibilityIdentifier("locationStatus")

                    // REM: 2026-11-07 the robot's contrast audit failed the system blue text on the gray
                    // bordered button. A deeper blue in light mode (bright in dark) passes; this button only,
                    // the app's accent color is untouched.
                    Button(action: accessLocation) {
                        Text("Access Location").font(.system(size: bodySize, weight: .semibold))
                            .foregroundStyle(Self.buttonBlue)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("accessLocation")
                    .accessibilityHint(state.hint)

                    Text(state.footnote)
                        .font(.system(size: bodySize))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            // REM: after Location on purpose — the robot's Location checks find that section first.
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("Your Name").font(.system(size: headingSize, weight: .semibold))
                    } icon: {
                        Image(systemName: "person.fill").foregroundStyle(.tint)
                    }
                    Text("Milestones greets you by this name at the top of your journal. Leave it empty for no greeting.")
                        .font(.system(size: bodySize))
                    TextField("Your name", text: $userName)
                        .font(.system(size: bodySize))
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("settingsName")
                }
                .padding(.vertical, 6)
            }

            reminderSection

            // REM: amber B-031 — Access Microphone, for voice memos (MicrophoneAccessViews.swift).
            MicrophoneSection()

            // REM: line 010.2 — "the revoking option in settings" (JournalLock.swift).
            JournalLockSection()
        }
        #if os(macOS)
        .formStyle(.grouped)
        #endif
        // Back from the Settings app: show what changed there.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { location.refreshStatus(); Task { await refreshNotifications() } }
        }
        .task { await refreshNotifications() }
    }

    // MARK: - Daily reminder (line 032)

    private var reminderSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text("Daily Reminder").font(.system(size: headingSize, weight: .semibold))
                } icon: {
                    Image(systemName: "bell.fill").foregroundStyle(.tint)
                }
                Text("Each day at the time you pick, Milestones reminds you: \u{201C}Time to write today\u{2019}s entry.\u{201D}")
                    .font(.system(size: bodySize))
                Toggle(isOn: Binding(get: { reminderOn }, set: { turnReminder($0) })) {
                    Text("Remind Me Each Day").font(.system(size: bodySize, weight: .semibold))
                }
                .accessibilityIdentifier("reminderToggle")
                if reminderOn {
                    DatePicker(selection: reminderTime, displayedComponents: .hourAndMinute) {
                        Text("Time").font(.system(size: bodySize))
                    }
                    .accessibilityIdentifier("reminderTime")
                    // REM: line 032.2, his design: Persistent, and when it's on, the Snooze time below it.
                    Toggle(isOn: Binding(get: { reminderPersistent },
                                         set: { reminderPersistent = $0; Task { await ReminderService.refresh() } })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Persistent").font(.system(size: bodySize, weight: .semibold))
                            Text("Keeps reminding you until you write today\u{2019}s entry.").font(.system(size: bodySize))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("reminderPersistent")
                    if reminderPersistent {
                        Picker(selection: Binding(get: { snoozeMinutes },
                                                  set: { snoozeMinutes = $0; Task { await ReminderService.refresh() } })) {
                            ForEach(ReminderService.snoozeChoices, id: \.self) { m in
                                Text("\(m) min").font(.system(size: bodySize)).tag(m)
                            }
                        } label: {
                            Text("Snooze").font(.system(size: bodySize))
                        }
                        .accessibilityIdentifier("reminderSnooze")
                        // REM: B-032.2 / 032.3 — Nagging below Snooze, iPhone and iPad on iOS 26+ (AlarmKit).
                        #if os(iOS)
                        if #available(iOS 26.0, *) { NaggingSection() }
                        #endif
                    }
                }
                if notificationsOff {
                    // REM: his 002.2 rule — after a no, the way back is the Settings app; this button opens it.
                    Text("Notifications are off for Milestones, so the reminder can't show. Turn them on in \(settingsAppName).")
                        .font(.system(size: bodySize))
                        .foregroundStyle(.secondary)
                    Button(action: openNotificationSettings) {
                        Text("Access Notifications").font(.system(size: bodySize, weight: .semibold))
                            .foregroundStyle(Self.buttonBlue)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("accessNotifications")
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: { Calendar.current.date(from: DateComponents(hour: reminderHour, minute: reminderMinute)) ?? .now },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                reminderHour = parts.hour ?? 20
                reminderMinute = parts.minute ?? 0
                Task { await ReminderService.apply(on: reminderOn, hour: reminderHour, minute: reminderMinute) }
            })
    }

    private func turnReminder(_ on: Bool) {
        Task {
            if on, !(await ReminderService.requestPermission()) {
                reminderOn = false
                notificationsOff = true
                return
            }
            reminderOn = on
            await ReminderService.apply(on: on, hour: reminderHour, minute: reminderMinute)
            await refreshNotifications()
        }
    }

    private func refreshNotifications() async {
        notificationsOff = await ReminderService.status() == .denied
    }

    private func openNotificationSettings() {
        #if os(macOS)
        let address = "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
        #else
        let address = UIApplication.openNotificationSettingsURLString
        #endif
        if let url = URL(string: address) { openURL(url) }
    }

    /// Deeper blue in light mode, bright blue in dark mode, so the button text clears the contrast check.
    static var buttonBlue: Color {
        #if canImport(UIKit)
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.45, green: 0.70, blue: 1.0, alpha: 1)
                : UIColor(red: 0.0, green: 0.30, blue: 0.75, alpha: 1)
        })
        #else
        Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.45, green: 0.70, blue: 1.0, alpha: 1)
                : NSColor(red: 0.0, green: 0.30, blue: 0.75, alpha: 1)
        })
        #endif
    }

    // MARK: - State

    private struct LocationState {
        let words: String
        let symbol: String
        let isOn: Bool
        let hint: String
        let footnote: String
    }

    private var state: LocationState {
        switch location.authorizationStatus {
        case .notDetermined:
            return LocationState(
                words: "Not asked yet",
                symbol: "questionmark.circle",
                isOn: false,
                hint: "Brings up Apple's Location question.",
                footnote: "Tap Access Location and Apple asks whether Milestones may use your location.")
        case .restricted:
            return LocationState(
                words: "Location is off",
                symbol: "xmark.circle.fill",
                isOn: false,
                hint: "Opens \(settingsAppName).",
                footnote: "Location is turned off for this device, for example by Screen Time. It can only be turned on in \(settingsAppName).")
        case .denied:
            return LocationState(
                words: "Location is off",
                symbol: "xmark.circle.fill",
                isOn: false,
                hint: "Opens \(settingsAppName).",
                footnote: "Apple won't ask again after a no. Tap Access Location to turn it on in \(settingsAppName)\(settingsPathSuffix).")
        default:
            return LocationState(
                words: "Location is on",
                symbol: "checkmark.circle.fill",
                isOn: true,
                hint: "Opens \(settingsAppName).",
                footnote: "To turn it off, tap Access Location and change it in \(settingsAppName)\(settingsPathSuffix).")
        }
    }

    private var settingsAppName: String {
        #if os(macOS)
        "System Settings"
        #else
        "the Settings app"
        #endif
    }

    private var settingsPathSuffix: String {
        #if os(macOS)
        ", under Privacy & Security, Location Services"
        #else
        ", under Location"
        #endif
    }

    // MARK: - Action

    private func accessLocation() {
        if location.authorizationStatus == .notDetermined {
            location.requestPermission()
            return
        }
        #if os(macOS)
        let address = "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"
        #else
        let address = UIApplication.openSettingsURLString
        #endif
        if let url = URL(string: address) { openURL(url) }
    }
}

#Preview {
    SettingsView()
}
