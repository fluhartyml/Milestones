//
//  JournalLock.swift
//  Milestones
//
//  The journal lock: biometric authorization (whatever sensor the device has; passcode/password as the fallback), offered at setup, switched in
//  Settings (amber sheet lines 010.1 and 010.2).
//
//  REM: his word 2026-11-06, line 010.1: Milestones gets a Face ID lock — his "keylock on a journal you hide under your bed
//  so your parents dont read your deepest darkest secrets." The journal "is the server": everything stays on your devices
//  and in your iCloud. "The switch is in Settings. When it's on, the journal hides as soon as you leave the app and opens
//  with Face ID or your passcode."
//  REM: his word 2026-11-06, line 010.2: "yes offer it at setup and has the revoking option in settings" — a "Lock your
//  journal" card after the name card (002.1), and Settings can turn it off or back on at any time (002.2).
//  REM: Claude's calls, noted on the sheet: turning the lock OFF asks for biometric authorization too (otherwise anyone holding the unlocked
//  phone could switch it off); the journal is covered the moment the app leaves the screen, so the app switcher's
//  picture never shows a page; "Not Now" never comes back (his build-251 rule for Mediaworks: setup is never mandatory).
//  REM: text is 18 pt at the default size and grows with your text size (his 18 pt rule).
//

import LocalAuthentication
import SwiftUI

enum JournalLockKeys {
    static let on = "journalLockOn"
    static let asked = "askedForJournalLock"
}

enum JournalLock {
    /// "Biometric Authorization" on any device with a biometric sensor — or "your passcode" when the device has none set up.
    /// REM: his word 2026-11-14 09:0x: "Bio Metric authorization" — the lock is never named after one sensor (the iPhone
    /// Duo only has Touch ID). The sensor's own icon still shows beside it (symbol below).
    static var methodName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID, .touchID, .opticID: return "Biometric Authorization"
        default:
            #if os(macOS)
            return "your password"
            #else
            return "your passcode"
            #endif
        }
    }

    static var symbol: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "lock.fill"
        }
    }

    /// Asks for biometric authorization (or the passcode/password as the fallback). True when it is you.
    static func confirm(_ reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return false }
        return (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) ?? false
    }

    /// Whether this device can lock at all (a passcode or password is set).
    static var available: Bool { LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) }
}

// MARK: - The lock over the whole app

struct JournalLockGate: ViewModifier {
    @AppStorage(JournalLockKeys.on) private var lockOn = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var locked = UserDefaults.standard.bool(forKey: JournalLockKeys.on)
    @State private var covered = false
    @State private var asking = false

    func body(content: Content) -> some View {
        content
            // REM: amber B-031.3 / B-031.5 — a shared entry waits until the journal is open; it never shows over the lock.
            .environment(\.journalLocked, lockOn && (locked || covered))
            .overlay {
                if lockOn && (locked || covered) {
                    LockScreen(asking: asking, unlock: unlock)
                        .transition(.opacity)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                guard lockOn else { covered = false; locked = false; return }
                switch phase {
                case .background: locked = true; covered = true
                case .inactive: covered = true          // the app switcher's picture shows the cover, never a page
                case .active:
                    covered = false
                    if locked { unlock() }
                @unknown default: break
                }
            }
            .task { if lockOn && locked { unlock() } }
    }

    private func unlock() {
        guard !asking else { return }
        asking = true
        Task {
            let ok = await JournalLock.confirm("Open your journal.")
            asking = false
            if ok { withAnimation { locked = false } }
        }
    }
}

private struct LockScreen: View {
    let asking: Bool
    let unlock: () -> Void
    // REM: B-182.2, his "code it" 2026-11-14 — with Locking Strap on, the lock screen is the closed diary, strapped shut;
    // the key (biometric authorization) opens it. Tapping the clasp works too (DiaryStyle.swift).
    @AppStorage(DiaryKeys.strap) private var legacyStrap = false
    @AppStorage(DiaryKeys.closure) private var storedClosure: DiaryClosure = .none
    @AppStorage(DiaryKeys.stamp) private var stamp = ""
    private var closure: DiaryClosure { DiaryClosure.current(storedClosure, legacyStrap: legacyStrap) }
    private var strap: Bool { closure != .none }
    @AppStorage(DiaryKeys.cover) private var cover: DiaryCover = .blackMarble
    @AppStorage(DiaryKeys.binding) private var binding: DiaryBinding = .clothTape
    @ScaledMetric(relativeTo: .body) private var diaryHeight: CGFloat = 300
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .title) private var titleSize: CGFloat = 28
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 56

    var body: some View {
        ZStack {
            Rectangle().fill(.background).ignoresSafeArea()
            VStack(spacing: 20) {
                if strap {
                    Button(action: unlock) {
                        ClosedDiaryView(cover: cover, binding: binding, closure: closure, stamp: stamp)
                            .frame(maxHeight: diaryHeight)
                    }
                    .buttonStyle(.plain)
                    .disabled(asking)
                    .accessibilityLabel("Your diary, strapped shut")
                    .accessibilityHint("Opens it with \(JournalLock.methodName).")
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: iconSize))
                        .foregroundStyle(SettingsView.buttonBlue)
                        .accessibilityHidden(true)
                }
                Text(strap ? "Your diary is locked" : "Your journal is locked")
                    .font(.system(size: titleSize, weight: .bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Button(action: unlock) {
                    Label("Unlock with \(JournalLock.methodName)", systemImage: strap ? "key.fill" : JournalLock.symbol)
                        .font(.system(size: bodySize, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(LockOfferView.fill, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(asking)
                .accessibilityIdentifier("unlockJournal")
            }
            .padding(24)
            .frame(maxWidth: 520)
        }
    }
}

extension View {
    /// Covers the journal while it is locked (JournalLock.swift).
    func journalLock() -> some View { modifier(JournalLockGate()) }
}

extension EnvironmentValues {
    /// True while the lock screen covers the journal.
    @Entry var journalLocked = false
}

// MARK: - The setup card (010.2)

struct LockOfferView: View {
    @AppStorage(JournalLockKeys.on) private var lockOn = false
    @AppStorage(JournalLockKeys.asked) private var asked = false
    @State private var problem: String?
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .title) private var titleSize: CGFloat = 28
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 56

    static let fill = Color(red: 0.0, green: 0.30, blue: 0.75)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: iconSize))
                    .foregroundStyle(SettingsView.buttonBlue)
                    .accessibilityHidden(true)
                Text("Lock your journal with \(JournalLock.methodName)?")
                    .font(.system(size: titleSize, weight: .bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text("When it's on, your journal hides as soon as you leave Milestones, and opens only with \(JournalLock.methodName). You can turn it off any time in Settings.")
                    .font(.system(size: bodySize))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if let problem {
                    Text(problem).font(.system(size: bodySize)).multilineTextAlignment(.center)
                }
                Button {
                    Task {
                        if await JournalLock.confirm("Turn on the journal lock.") { lockOn = true; asked = true }
                        else { problem = JournalLock.available ? "The lock is still off. Try again, or choose Not Now." : "This device has no passcode set, so Milestones can't lock it. You can turn the lock on later in Settings." }
                    }
                } label: {
                    Text("Turn On Lock")
                        .font(.system(size: bodySize, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Self.fill, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("lockOn")
                .accessibilityHint("Asks for \(JournalLock.methodName) once, then locks the journal whenever you leave.")
                Button { asked = true } label: {
                    Text("Not Now")
                        .font(.system(size: bodySize))
                        .foregroundStyle(SettingsView.buttonBlue)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("lockSkip")
                .accessibilityHint("Leaves the journal unlocked. You can turn the lock on later in Settings.")
            }
            .padding(24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 420)
        #endif
        .interactiveDismissDisabled()
    }
}

// MARK: - Settings (010.2: "the revoking option in settings")

struct JournalLockSection: View {
    @AppStorage(JournalLockKeys.on) private var lockOn = false
    @State private var problem: String?
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .headline) private var headingSize: CGFloat = 20

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text("Journal Lock").font(.system(size: headingSize, weight: .semibold))
                } icon: {
                    Image(systemName: "lock.fill").foregroundStyle(.tint)
                }
                Toggle(isOn: Binding(get: { lockOn }, set: { change(to: $0) })) {
                    Text("Lock with \(JournalLock.methodName)").font(.system(size: bodySize))
                }
                .accessibilityIdentifier("journalLockToggle")
                Text(lockOn ? "Your journal hides as soon as you leave Milestones. Turning this off asks for \(JournalLock.methodName) first."
                            : "Off — your journal opens without \(JournalLock.methodName).")
                    .font(.system(size: bodySize))
                    .foregroundStyle(.secondary)
                if let problem { Text(problem).font(.system(size: bodySize)) }
            }
            .padding(.vertical, 6)
        }
    }

    private func change(to on: Bool) {
        Task {
            let ok = await JournalLock.confirm(on ? "Turn on the journal lock." : "Turn off the journal lock.")
            if ok { lockOn = on; problem = nil }
            else { problem = JournalLock.available ? "Not changed — \(JournalLock.methodName) didn't confirm it was you." : "This device has no passcode set, so Milestones can't lock it." }
        }
    }
}
