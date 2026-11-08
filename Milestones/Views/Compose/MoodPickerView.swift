//
//  MoodPickerView.swift
//  Milestones
//
//  "How are you feeling?" — the scale of faces. Picking one starts the journal entry.
//
//  REM: His TestFlight feedback, build 21, 2026-11-08 06:43–06:44 (Mood.swift has his words).
//  REM: Sizes ride Dynamic Type from an 18 pt body (his 18 pt minimum rule); every face is a button
//  REM: with a one-word VoiceOver name and an identifier, so the robot can drive it with no eyes.
//

import SwiftUI

struct MoodPickerView: View {
    /// Called with the face picked; the sheet closes itself.
    let onPick: (Mood) -> Void

    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .title) private var titleSize: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .largeTitle) private var faceSize: CGFloat = 44

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Text("How are you feeling?")
                    .font(.system(size: titleSize, weight: .bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(Date.now.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: bodySize))
                    .foregroundStyle(.secondary)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { faces }
                    // REM: At the largest text sizes five faces don't fit in a row — they stack instead.
                    VStack(spacing: 12) { faces }
                }
                .padding(.horizontal)
                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                        .accessibilityIdentifier("moodCancel")
                }
            }
        }
    }

    @ViewBuilder private var faces: some View {
        ForEach(Mood.allCases) { mood in
            Button {
                dismiss()
                onPick(mood)
            } label: {
                VStack(spacing: 6) {
                    Text(mood.emoji)
                        .font(.system(size: faceSize))
                        .frame(minWidth: faceSize * 1.4, minHeight: faceSize * 1.4)
                        // REM: A colored RING, not a pale fill — the robot's contrast audit failed the faces on
                        // REM: pastel circles (2026-11-08). The word below names the face, so the emoji is hidden.
                        .background(Circle().fill(.background))
                        .overlay(Circle().strokeBorder(mood.color, lineWidth: 4))
                        .accessibilityHidden(true)
                    Text(mood.name)
                        .font(.system(size: bodySize, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(mood.name)
            .accessibilityIdentifier("mood_\(mood.rawValue)")
        }
    }
}

#Preview {
    MoodPickerView { _ in }
}
