//
//  NameAskView.swift
//  Milestones
//
//  "What should we call you?" — asked once, at first launch (amber sheet line 002.1).
//
//  REM: his word 2026-11-06, line 002.1 ("yes for both apps"): "Milestones asks 'What should we call
//  you?' at first launch and greets you by name at the top of the journal ... In both apps you can
//  change the name in Settings." Idea from Daylio (IMG_0787–0788), reference only, nothing copied.
//  REM: "Not Now" is there so nobody is trapped behind a name they don't want to give; the sheet then
//  never comes back, and Settings still holds the name field (his 002.2 rule: you can always change
//  your mind in Settings).
//  REM: the name stays on this device (UserDefaults). It is never sent anywhere.
//  REM: text is 18 pt at the default size and grows with your text size (his 18 pt rule).
//

import SwiftUI

/// Where the name lives. One place, so the sheet, the journal greeting and Settings agree.
enum UserNameKeys {
    static let name = "userName"
    static let asked = "askedForName"
}

struct NameAskView: View {

    @AppStorage(UserNameKeys.name) private var name = ""
    @AppStorage(UserNameKeys.asked) private var asked = false
    @State private var draft = ""
    @FocusState private var focused: Bool

    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .title) private var titleSize: CGFloat = 28
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 56

    private var trimmed: String { draft.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: iconSize))
                    .foregroundStyle(SettingsView.buttonBlue)
                    .accessibilityHidden(true)

                Text("What should we call you?")
                    .font(.system(size: titleSize, weight: .bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("Milestones greets you by this name at the top of your journal. You can change it any time in Settings.")
                    .font(.system(size: bodySize))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                nameField

                // REM: a solid deep blue with white text, in light and dark mode alike, so the contrast
                // check passes (the system blue fill with white text falls short).
                Button(action: save) {
                    Text("Continue")
                        .font(.system(size: bodySize, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Self.continueFill.opacity(trimmed.isEmpty ? 0.45 : 1),
                                    in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(trimmed.isEmpty)
                .accessibilityIdentifier("nameContinue")
                .accessibilityHint("Saves your name and opens Milestones.")

                Button {
                    asked = true
                } label: {
                    Text("Not Now")
                        .font(.system(size: bodySize))
                        .foregroundStyle(SettingsView.buttonBlue)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("nameSkip")
                .accessibilityHint("Skips the name. You can add it later in Settings.")
            }
            .padding(24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 420)
        #endif
        .interactiveDismissDisabled()
        .onAppear { focused = true }
    }

    private var nameField: some View {
        TextField("Your name", text: $draft)
            .font(.system(size: bodySize))
            .textFieldStyle(.roundedBorder)
            #if os(iOS) || os(visionOS)
            .textContentType(.givenName)
            #endif
            .submitLabel(.done)
            .focused($focused)
            .onSubmit(save)
            .accessibilityIdentifier("nameField")
    }

    private func save() {
        guard !trimmed.isEmpty else { return }
        name = trimmed
        asked = true
    }

    private static let continueFill = Color(red: 0.0, green: 0.30, blue: 0.75)
}

#Preview {
    NameAskView()
}
