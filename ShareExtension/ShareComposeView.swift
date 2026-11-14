//
//  ShareComposeView.swift
//  MilestonesShare (Share extension)
//
//  REM: amber B-031.3 — shared text "opens it as a new entry for the person to edit and save". His words 2026-11-06:
//  "at a minimum they can share the transcriptions or summaries from the Siri app so a share to our app is important
//  linchpin." The text you shared fills the box, ready to change before you save.
//  REM: amber B-031.5 — "you can also share photos to milestones where it should receive them, and if a group of
//  photos, even if just one photo, you get to add an entry or description of the photo stack." One photo or many,
//  they sit as one stack above the same box; what you write is the entry, or your description of the stack.
//  Save puts it in the inbox (Shared/ShareInbox.swift); Milestones makes the entry and opens it the next time it
//  comes to the front.
//

import SwiftUI

struct ShareComposeView: View {
    let items: [NSExtensionItem]
    let finish: (_ saved: Bool) -> Void

    @State private var text = ""
    @State private var photos: [Data] = []
    @State private var previews: [CGImage] = []
    @State private var loading = true
    @State private var saving = false
    @State private var problem: String?

    // REM: 18 pt minimum at the default size, scaled with Dynamic Type — the app's own sizes (EntryDetailView).
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .headline) private var headingSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var stackSize: CGFloat = 150
    @ScaledMetric(relativeTo: .body) private var boxHeight: CGFloat = 180

    private var canSave: Bool {
        !loading && !saving && (!photos.isEmpty || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if loading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .accessibilityLabel("Loading")
                    } else {
                        if !photos.isEmpty { photoStack }
                        entryBox
                        Text("Milestones opens this as a new entry, ready for you to edit.")
                            .font(.system(size: bodySize))
                            .foregroundStyle(.secondary)
                        if let problem {
                            Text(problem)
                                .font(.system(size: bodySize, weight: .semibold))
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding()
            }
        }
        .font(.system(size: bodySize))
        .task { await load() }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack {
            Button("Cancel") { finish(false) }
                .font(.system(size: bodySize))
                .accessibilityLabel("Cancel")
            Spacer()
            Text("New Entry")
                .font(.system(size: headingSize, weight: .semibold))
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button("Save") { save() }
                .font(.system(size: bodySize, weight: .semibold))
                .disabled(!canSave)
                .accessibilityLabel("Save")
        }
        .padding()
    }

    /// The photos as one stack: the first on top, up to two more fanned out beneath it.
    private var photoStack: some View {
        VStack(spacing: 8) {
            ZStack {
                ForEach(Array(previews.prefix(3).enumerated().reversed()), id: \.offset) { index, image in
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .scaledToFill()
                        .frame(width: stackSize, height: stackSize)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.background, lineWidth: 3))
                        .shadow(radius: 2)
                        .rotationEffect(.degrees(Double(index) * 5))
                        .offset(x: CGFloat(index) * 8, y: CGFloat(index) * -4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            Text(photos.count == 1 ? "1 photo" : "\(photos.count) photos")
                .font(.system(size: bodySize))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Photo stack")
        .accessibilityValue(photos.count == 1 ? "1 photo" : "\(photos.count) photos")
    }

    private var entryBox: some View {
        TextEditor(text: $text)
            .font(.system(size: bodySize))
            .frame(minHeight: boxHeight)
            .scrollContentBackground(.hidden)
            .padding(8)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(photos.isEmpty ? "Write your entry." : "Write your entry or describe these photos.")
                        .font(.system(size: bodySize))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel("Entry text")
    }

    // MARK: - Work

    /// Reads what was shared: every text joined into the box, every photo into the stack.
    private func load() async {
        var texts: [String] = []
        var loaded: [Data] = []
        for item in items {
            var itemText: [String] = []
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier("public.image") {
                    if let photo = await ShareInbox.loadPhoto(from: provider) { loaded.append(photo) }
                } else if let words = await ShareInbox.loadText(from: provider) {
                    itemText.append(words)
                }
            }
            // Some apps put the text on the share itself rather than in an attachment.
            if itemText.isEmpty, let words = item.attributedContentText?.string { itemText.append(words) }
            texts += itemText
        }
        text = texts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        photos = loaded
        previews = loaded.prefix(3).compactMap { ShareInbox.preview(of: $0, maxPixels: 400) }
        if loaded.isEmpty && text.isEmpty && items.contains(where: { !($0.attachments ?? []).isEmpty }) {
            problem = "Milestones couldn't read what you shared. Write your entry here, or try sharing again."
        }
        loading = false
    }

    private func save() {
        saving = true
        problem = nil
        let words = text
        let stack = photos
        Task {
            do {
                try await Task.detached { try ShareInbox.save(text: words, photos: stack) }.value
                finish(true)
            } catch {
                problem = "Milestones couldn't save this. Try again."
                saving = false
            }
        }
    }
}
