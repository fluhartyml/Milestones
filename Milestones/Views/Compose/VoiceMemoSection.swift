//
//  VoiceMemoSection.swift
//  Milestones
//
//  Amber B-031: the voice memo on an entry — Record / Stop, play it back, remove it. A finished recording is written
//  out as text on the device and added to the entry's words, where you can edit it.
//

import SwiftUI

struct VoiceMemoSection: View {
    /// The entry's memo — bound so the compose screen and an open entry both keep it.
    @Binding var memo: Data?
    /// The entry's words — the transcript is added to the end.
    @Binding var text: String

    @State private var recorder = VoiceMemoRecorder()
    @State private var player = VoiceMemoPlayer()
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                if recorder.isRecording {
                    Label("Recording  \(VoiceMemoRecorder.clock(recorder.seconds))", systemImage: "record.circle")
                        .font(.system(size: bodySize, weight: .semibold))
                        .foregroundStyle(.red)
                        .monospacedDigit()
                        .accessibilityIdentifier("memoRecording")
                    button("Stop", symbol: "stop.fill", id: "memoStop", hint: "Stops recording and writes the memo out as text.") {
                        Task {
                            if let words = await recorder.stop() {
                                text = text.isEmpty ? words : text + "\n\n" + words
                            }
                            memo = recorder.memo
                        }
                    }
                } else if let memo {
                    HStack(spacing: 12) {
                        button(player.isPlaying ? "Stop" : "Play Memo", symbol: player.isPlaying ? "stop.fill" : "play.fill",
                               id: "memoPlay", hint: "Plays the voice memo.") { player.toggle(memo) }
                        button("Remove", symbol: "trash", id: "memoRemove", hint: "Removes the voice memo. The words stay.") {
                            if player.isPlaying { player.toggle(memo) }
                            recorder.remove()
                            self.memo = nil
                        }
                    }
                } else {
                    button("Record Voice Memo", symbol: "mic.fill", id: "memoRecord",
                           hint: "Records your voice. When you stop, it's written out as text in the entry.") {
                        Task { await recorder.start() }
                    }
                }
                if recorder.isTranscribing {
                    ProgressView("Writing it out…").font(.system(size: bodySize))
                }
                if let problem = recorder.problem {
                    Text(problem).font(.system(size: bodySize)).foregroundStyle(.secondary)
                        .accessibilityIdentifier("memoProblem")
                }
            }
            .padding(.vertical, 4)
        } header: {
            // REM: 18 pt minimum (his rule) — the header was the system's small caption size.
            Text("Voice Memo").font(.system(size: bodySize))
        } footer: {
            Text("Written out as text on this device. Nothing is sent anywhere.")
                .font(.system(size: bodySize))
        }
    }

    private func button(_ title: String, symbol: String, id: String, hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: bodySize, weight: .semibold))
                .foregroundStyle(SettingsView.buttonBlue)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier(id)
        .accessibilityHint(hint)
    }
}
