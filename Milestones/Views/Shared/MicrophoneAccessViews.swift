//
//  MicrophoneAccessViews.swift
//  Milestones
//
//  Amber B-031: "A voice memo needs Microphone, so each app gets a Microphone setup card and an Access Microphone
//  button in Settings (002.2)." The card follows the lock card once; Settings shows on / off and can always take it back
//  (his rule, settled 11-06: re-asks if never answered, otherwise opens the Settings app's page).
//

import SwiftUI

/// The first-launch card: record voice memos? One ask for the Microphone, then Speech Recognition for the transcript.
struct MicrophoneOfferView: View {
    @AppStorage(MicrophoneAccess.askedKey) private var asked = false
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .title) private var titleSize: CGFloat = 28
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 56

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "mic.fill")
                    .font(.system(size: iconSize))
                    .foregroundStyle(SettingsView.buttonBlue)
                    .accessibilityHidden(true)
                Text("Add your voice to entries?")
                    .font(.system(size: titleSize, weight: .bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text("Record a voice memo on any entry. Milestones writes it out as text on this device, and you can edit the words. Apple asks for the Microphone, then for Speech Recognition. You can change both any time in Settings.")
                    .font(.system(size: bodySize))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    Task { await MicrophoneAccess.request(); asked = true }
                } label: {
                    Text("Allow Microphone")
                        .font(.system(size: bodySize, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(LockOfferView.fill, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("micOn")
                .accessibilityHint("Brings up Apple's Microphone question, then Speech Recognition's.")
                Button { asked = true } label: {
                    Text("Not Now")
                        .font(.system(size: bodySize))
                        .foregroundStyle(SettingsView.buttonBlue)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("micSkip")
                .accessibilityHint("Skips it. Apple asks the first time you record, or use Access Microphone in Settings.")
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

/// Settings: Microphone — on or off, and the Access Microphone button.
struct MicrophoneSection: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var state = MicrophoneAccess.state
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .headline) private var headingSize: CGFloat = 20

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text("Microphone").font(.system(size: headingSize, weight: .semibold))
                } icon: {
                    Image(systemName: "mic.fill").foregroundStyle(.tint)
                }
                Text("Milestones uses the microphone for voice memos on your entries, and writes them out as text on this device.")
                    .font(.system(size: bodySize))
                Label(words, systemImage: symbol)
                    .font(.system(size: bodySize, weight: .semibold))
                    .foregroundStyle(state == .allowed ? Color.green : Color.secondary)
                    .accessibilityIdentifier("microphoneStatus")
                Button(action: access) {
                    Text("Access Microphone").font(.system(size: bodySize, weight: .semibold))
                        .foregroundStyle(SettingsView.buttonBlue)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("accessMicrophone")
                .accessibilityHint(state == .notAsked ? "Brings up Apple's Microphone question." : "Opens \(settingsAppName).")
                Text(footnote).font(.system(size: bodySize)).foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
        .onChange(of: scenePhase) { _, phase in if phase == .active { state = MicrophoneAccess.state } }
    }

    private var words: String {
        switch state {
        case .allowed: "Microphone is on"
        case .denied: "Microphone is off"
        case .notAsked: "Not asked yet"
        }
    }

    private var symbol: String {
        switch state {
        case .allowed: "checkmark.circle.fill"
        case .denied: "xmark.circle.fill"
        case .notAsked: "questionmark.circle"
        }
    }

    private var footnote: String {
        switch state {
        case .notAsked: "Tap Access Microphone and Apple asks whether Milestones may use it."
        case .denied: "Apple won't ask again after a no. Tap Access Microphone to turn it on in \(settingsAppName)\(pathSuffix)."
        case .allowed: "To turn it off, tap Access Microphone and change it in \(settingsAppName)\(pathSuffix)."
        }
    }

    private var settingsAppName: String {
        #if os(macOS)
        "System Settings"
        #else
        "the Settings app"
        #endif
    }

    private var pathSuffix: String {
        #if os(macOS)
        ", under Privacy & Security, Microphone"
        #else
        ", under Milestones"
        #endif
    }

    private func access() {
        if state == .notAsked {
            Task { await MicrophoneAccess.request(); state = MicrophoneAccess.state }
            return
        }
        #if os(macOS)
        let address = "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        #else
        let address = UIApplication.openSettingsURLString
        #endif
        if let url = URL(string: address) { openURL(url) }
    }
}
