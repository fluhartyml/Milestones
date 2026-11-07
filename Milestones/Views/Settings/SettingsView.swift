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
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {

    @State private var location = LocationService()
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
        }
        #if os(macOS)
        .formStyle(.grouped)
        #endif
        // Back from the Settings app: show what changed there.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { location.refreshStatus() }
        }
    }

    /// Deeper blue in light mode, bright blue in dark mode, so the button text clears the contrast check.
    private static var buttonBlue: Color {
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
