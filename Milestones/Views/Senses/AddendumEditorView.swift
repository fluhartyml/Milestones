//
//  AddendumEditorView.swift
//  Milestones
//
//  REM: amber B-183.2 (locked 2026-11-09): "each sense button adds an addendum (a sub-entry) to the current entry:
//  Sight → camera, take a picture · Hearing → audio recording · Touch → type something · Smell → picture + typing ·
//  Taste → picture + typing (you are probably photographing what you are eating)." B-183.7.1, his word: "use the
//  camera glyph to unify the glyph motife" — the tool tiles in a sense's sheet open this screen.
//  REM: B-183.2.1 "stamped at its top with the glyph of the sense button that made it"; B-183.2.2 "heading is the
//  title you write; its subheading is the sense". Tapping an addendum on the entry opens it here again to look, play,
//  change or remove it.
//  REM: the recording reuses VoiceMemoSection (amber B-031) — same Record / Stop / Play Memo / Remove and the same
//  on-device transcript, written into this addendum's words instead of the entry's.
//

import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

struct AddendumEditorView: View {
    let entry: MilestoneEntry
    /// The sense it belongs to (for an existing addendum, rebuilt from what the addendum kept).
    let sense: SenseButton
    /// The tool tile that opened it: the camera opens straight away, the keyboard puts you in the text.
    let startTool: SenseTool?
    let existing: Addendum?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var text = ""
    @State private var photo: Data?
    @State private var audio: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var cameraProblem: String?
    @State private var confirmingRemove = false
    @State private var loaded = false
    @FocusState private var typing: Bool

    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .headline) private var headingSize: CGFloat = 20
    @ScaledMetric(relativeTo: .title2) private var glyphSize: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var photoHeight: CGFloat = 220
    /// B-183.4: the picture gets the whole left page when the Duo is open.
    @ScaledMetric(relativeTo: .body) private var spreadPhotoHeight: CGFloat = 380

    init(entry: MilestoneEntry, sense: SenseButton, startTool: SenseTool?) {
        self.entry = entry
        self.sense = sense
        self.startTool = startTool
        self.existing = nil
    }

    init(entry: MilestoneEntry, addendum: Addendum) {
        self.entry = entry
        self.sense = SenseButton(id: addendum.sense, name: addendum.senseName, glyph: addendum.glyph)
        self.startTool = nil
        self.existing = addendum
    }

    private var tools: [SenseTool] { sense.tools }
    private var hasSomething: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || photo != nil || audio != nil
    }

    var body: some View {
        NavigationStack {
            // REM: B-183.4 (locked 2026-11-09): "iPhone Duo: a sub-entry spreads across the open book: the picture on
            // one page, and you type about it on the facing page. Ties to 182.1 (hinge = spine)." Open on the Duo: the
            // picture fills the left page; the title, recording and your words face it on the right. An addendum with no
            // picture (Hearing, Touch) puts its heading and recording on the left and your words on the right. Closed,
            // and on every other device, it is the one page it has always been.
            OpenBook {
                headerSection
                if showsPicture { pictureSection(height: photoHeight) }
                if showsRecording { VoiceMemoSection(memo: $audio, text: $text) }
                if showsWords { wordsSection }
                if existing != nil { removeSection }
            } left: {
                if showsPicture {
                    pictureSection(height: spreadPhotoHeight)
                } else {
                    headerSection
                    if showsRecording { VoiceMemoSection(memo: $audio, text: $text) }
                }
            } right: {
                if showsPicture {
                    headerSection
                    if showsRecording { VoiceMemoSection(memo: $audio, text: $text) }
                }
                if showsWords { wordsSection }
                if existing != nil { removeSection }
            }
            .font(.system(size: bodySize))
            .navigationTitle(existing == nil ? "New Addendum" : "Addendum")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(existing == nil ? "Cancel" : "Close") { dismiss() }
                        .accessibilityHint(existing == nil ? "Closes without adding." : "Closes without saving changes.")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existing == nil ? "Add" : "Save") { save() }
                        .disabled(!hasSomething)
                        .accessibilityHint(existing == nil ? "Adds this under your entry." : "Saves your changes.")
                        .accessibilityIdentifier("addendumSave")
                }
            }
            .confirmationDialog("Remove this addendum?", isPresented: $confirmingRemove, titleVisibility: .visible) {
                Button("Remove Addendum", role: .destructive) { remove() }
                Button("Keep It", role: .cancel) {}
            }
            .photosPicker(isPresented: $showingPhotoPicker, selection: $photoItem, matching: .images)
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) { photo = data }
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPicker { photo = $0 }
                    .ignoresSafeArea()
            }
            #endif
            .task {
                guard !loaded else { return }
                loaded = true
                if let existing {
                    title = existing.title
                    text = existing.text
                    photo = existing.photo
                    audio = existing.audio
                    return
                }
                // Let this screen finish opening before the camera or photo picker covers it.
                try? await Task.sleep(for: .milliseconds(450))
                switch startTool {
                case .camera: await takePicture()
                case .keyboard: typing = true
                default: break
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 520)
        #endif
    }

    // MARK: - Sections

    private var showsPicture: Bool { tools.contains(.camera) || photo != nil }
    private var showsRecording: Bool { tools.contains(.microphone) || audio != nil }
    private var showsWords: Bool { tools.contains(.keyboard) || tools.contains(.microphone) || !text.isEmpty }

    private var headerSection: some View {
        Section {
            // REM: B-183.2.1 — the sense's glyph stamped at the top.
            HStack(spacing: 12) {
                Image(systemName: sense.glyph.isEmpty ? "sparkles" : sense.glyph)
                    .font(.system(size: glyphSize))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                Text(sense.name)
                    .font(.system(size: headingSize, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
            }
            TextField(text: $title, prompt: Text("Addendum title")) { Text("Addendum title") }
                .labelsHidden()
                .font(.system(size: headingSize, weight: .semibold))
                .accessibilityLabel("Addendum title")
                .accessibilityIdentifier("addendumTitle")
        }
    }

    private var wordsSection: some View {
        Section {
            TextField(text: $text, prompt: Text(sense.prompt), axis: .vertical) { Text("Addendum text") }
                .labelsHidden()
                .lineLimit(3...12)
                .focused($typing)
                .accessibilityLabel("Addendum text")
                .accessibilityIdentifier("addendumText")
        }
    }

    private var removeSection: some View {
        Section {
            Button(role: .destructive) { confirmingRemove = true } label: {
                Label("Remove Addendum", systemImage: "trash")
                    .font(.system(size: bodySize, weight: .semibold))
            }
            .accessibilityHint("Removes this addendum from your entry.")
            .accessibilityIdentifier("addendumRemove")
        }
    }

    // MARK: - Picture

    private func pictureSection(height: CGFloat) -> some View {
        Section {
            if let photo {
                JournalPhoto(data: photo)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Your picture")
            }
            if let cameraProblem {
                Text(cameraProblem).foregroundStyle(.secondary)
            }
            #if os(iOS)
            if CameraAccess.isAvailable {
                Button { Task { await takePicture() } } label: {
                    Label(photo == nil ? "Take Picture" : "Retake Picture", systemImage: "camera.fill")
                        .font(.system(size: bodySize, weight: .semibold))
                }
                .accessibilityHint("Opens the camera.")
                .accessibilityIdentifier("addendumCamera")
            }
            #endif
            Button { showingPhotoPicker = true } label: {
                Label("Choose Photo", systemImage: "photo.on.rectangle")
                    .font(.system(size: bodySize, weight: .semibold))
            }
            .accessibilityHint("Picks a photo from your library.")
            .accessibilityIdentifier("addendumChoosePhoto")
            if photo != nil {
                Button(role: .destructive) { photo = nil; photoItem = nil } label: {
                    Label("Remove Picture", systemImage: "trash")
                        .font(.system(size: bodySize, weight: .semibold))
                }
                .accessibilityHint("Takes the picture off this addendum.")
            }
        } header: {
            Text("Picture").font(.system(size: bodySize))
        }
    }

    /// The camera on iPhone and iPad (asking first if Apple hasn't asked); the photo library everywhere else.
    private func takePicture() async {
        cameraProblem = nil
        #if os(iOS)
        if CameraAccess.isAvailable {
            if await CameraAccess.request() {
                showingCamera = true
            } else {
                cameraProblem = "The camera is off for Milestones. Turn it on with Access Camera in Settings, or choose a photo."
            }
            return
        }
        #endif
        showingPhotoPicker = true
    }

    // MARK: - Save / Remove

    private func save() {
        let addendum: Addendum
        if let existing {
            addendum = existing
        } else {
            addendum = Addendum(senseID: sense.id, senseName: sense.name, glyph: sense.glyph)
            modelContext.insert(addendum)
            addendum.entry = entry
        }
        addendum.title = title
        addendum.text = text
        addendum.photo = photo
        addendum.audio = audio
        addendum.audioSeconds = audio.flatMap { try? AVAudioPlayer(data: $0).duration } ?? 0
        dismiss()
    }

    private func remove() {
        if let existing { modelContext.delete(existing) }
        dismiss()
    }
}

/// A stored photo, on any of the app's platforms.
struct JournalPhoto: View {
    let data: Data

    var body: some View {
        #if os(macOS)
        if let image = NSImage(data: data) {
            Image(nsImage: image).resizable().scaledToFill()
        }
        #else
        if let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill()
        }
        #endif
    }
}
