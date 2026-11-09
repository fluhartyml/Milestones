//
//  VoiceMemo.swift
//  Milestones
//
//  Amber B-031 / B-031.1 / B-031.2: one entry holds a note, a photo and a voice memo together, and the memo is
//  transcribed ON THE DEVICE into the entry's text, which you can then edit.
//
// REM: HIS WORDS, 2026-11-06 (amber B-031): "One entry screen that holds a quick note, a photo and a voice memo
// REM: together. Milestones: tell the moment in words, a picture and your voice." Revised (B-031.1): "transcription".
// REM: B-031.2 settled the source: only memos recorded in the app, transcribed on the device with Apple's own speech
// REM: recognition — nothing leaves the device (the journal "is the server"). Revisit if Apple opens Siri Recap to apps.
// REM: A memo needs the Microphone, so there is a Microphone setup card (MicrophoneOfferView) and an Access Microphone
// REM: row in Settings (his 11-06 rule: every permission gets an Access button that shows on/off).
// REM: FAIL-SAFE: if on-device recognition isn't available or speech access is off, the memo is still kept — the text
// REM: just isn't filled in, and the screen says why.
//

import AVFoundation
import Foundation
import Observation
import Speech

// MARK: - Permissions

enum MicrophoneAccess {
    enum State { case notAsked, allowed, denied }

    static let askedKey = "microphoneCardAsked"

    static var state: State {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return .allowed
        case .denied: return .denied
        default: return .notAsked
        }
    }

    /// Asks Apple's Microphone question, then Speech Recognition's (for the transcript). True when the microphone is on.
    @discardableResult
    static func request() async -> Bool {
        let mic = await AVAudioApplication.requestRecordPermission()
        if SFSpeechRecognizer.authorizationStatus() == .notDetermined {
            _ = await withCheckedContinuation { (done: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
                SFSpeechRecognizer.requestAuthorization { done.resume(returning: $0) }
            }
        }
        return mic
    }

    static var speechAllowed: Bool { SFSpeechRecognizer.authorizationStatus() == .authorized }
}

// MARK: - Recorder

@MainActor
@Observable
final class VoiceMemoRecorder {
    private(set) var isRecording = false
    private(set) var seconds: Double = 0
    /// The recorded memo, as an .m4a file's bytes.
    private(set) var memo: Data?
    private(set) var isTranscribing = false
    /// Why the transcript or the recording didn't happen — shown under the buttons.
    private(set) var problem: String?

    @ObservationIgnored private var recorder: AVAudioRecorder?
    @ObservationIgnored private var tick: Timer?
    @ObservationIgnored private var fileURL: URL?

    init(existing: Data? = nil) { memo = existing }

    func start() async {
        problem = nil
        guard await MicrophoneAccess.request() else {
            problem = "The microphone is off for Milestones. Turn it on with Access Microphone in Settings."
            return
        }
        #if os(iOS) || os(visionOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            problem = "The microphone couldn't start. Try again."
            return
        }
        #endif
        let url = FileManager.default.temporaryDirectory.appending(path: "memo-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        guard let made = try? AVAudioRecorder(url: url, settings: settings), made.record() else {
            problem = "The microphone couldn't start. Try again."
            return
        }
        recorder = made
        fileURL = url
        seconds = 0
        isRecording = true
        tick = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.seconds = self?.recorder?.currentTime ?? 0 }
        }
    }

    /// Stops, keeps the memo, and returns its transcript (nil when there is none).
    func stop() async -> String? {
        guard isRecording, let recorder, let url = fileURL else { return nil }
        recorder.stop()
        tick?.invalidate()
        isRecording = false
        self.recorder = nil
        #if os(iOS) || os(visionOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
        memo = try? Data(contentsOf: url)
        defer { try? FileManager.default.removeItem(at: url) }
        return await transcribe(url)
    }

    func remove() { memo = nil; problem = nil }

    private func transcribe(_ url: URL) async -> String? {
        guard MicrophoneAccess.speechAllowed else {
            problem = "The memo is saved. Speech Recognition is off for Milestones, so it wasn't written out as text."
            return nil
        }
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
            problem = "The memo is saved. This device can't write it out as text without the internet, so Milestones left it as audio."
            return nil
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        // REM: ON THE DEVICE ONLY (B-031.2) — never sent to Apple's servers.
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        request.addsPunctuation = true
        isTranscribing = true
        defer { isTranscribing = false }
        let text: String? = await withCheckedContinuation { done in
            let once = Once()
            recognizer.recognitionTask(with: request) { result, error in
                if let result, result.isFinal { if once.first() { done.resume(returning: result.bestTranscription.formattedString) } }
                else if error != nil { if once.first() { done.resume(returning: nil) } }
            }
        }
        if text?.isEmpty ?? true { problem = "The memo is saved. No words were heard in it." }
        return text?.isEmpty == true ? nil : text
    }

    static func clock(_ seconds: Double) -> String {
        let s = Int(seconds.rounded(.down))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

/// Resumes a continuation once, whichever callback arrives first.
nonisolated final class Once: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false
    func first() -> Bool { lock.lock(); defer { lock.unlock() }; if done { return false }; done = true; return true }
}

// MARK: - Player

@MainActor
@Observable
final class VoiceMemoPlayer: NSObject, AVAudioPlayerDelegate {
    private(set) var isPlaying = false
    @ObservationIgnored private var player: AVAudioPlayer?

    func toggle(_ data: Data) {
        if isPlaying { player?.stop(); isPlaying = false; return }
        #if os(iOS) || os(visionOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        player = try? AVAudioPlayer(data: data)
        player?.delegate = self
        isPlaying = player?.play() ?? false
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.isPlaying = false }
    }
}
