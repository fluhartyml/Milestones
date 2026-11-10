//
//  SenseSheetView.swift
//  Milestones
//
//  REM: amber B-183.7 (locked 2026-11-09), his idea 2026-11-07: "tapping one of the five senses opens a sheet you
//  swipe between the five. Each page holds Daylio-style ready-made glyphs (activities), as many as fit, and you can
//  add your own (Sight: Movies or TV…). Tapping one embeds the glyph in the journal entry".
//  REM: B-183.7.1, his word 2026-11-09 19:3x: "use the camera glyph to unify the glyph motife." — the sense's tool
//  sits first on its page as a glyph tile with the same look as the others (camera on Sight, microphone on Hearing,
//  keyboard on Touch, camera + keyboard on Smell and Taste). B-183.7.2: "Touch stays as a container of glyphs. You
//  add your own (a furry sweater, your dog)." — every page has Add Glyph.
//  REM: swiping is never the only way (his rule): the sense buttons across the top jump to a page too.
//

import SwiftUI

struct SenseSheetView: View {
    let startSenseID: String
    /// A tool tile was tapped (the entry closes this sheet and opens the addendum).
    let onTool: (SenseButton, SenseTool) -> Void
    /// A glyph was tapped (the entry stamps it and closes this sheet).
    let onGlyph: (SenseButton, SenseGlyph) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var store = SenseBarStore.shared
    @State private var current: String?
    @State private var addingGlyphTo: SenseButton?
    @State private var editingSenses = false

    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .headline) private var headingSize: CGFloat = 20
    @ScaledMetric(relativeTo: .title2) private var glyphSize: CGFloat = 30
    @ScaledMetric(relativeTo: .body) private var tileWidth: CGFloat = 104

    init(startSenseID: String,
         onTool: @escaping (SenseButton, SenseTool) -> Void,
         onGlyph: @escaping (SenseButton, SenseGlyph) -> Void) {
        self.startSenseID = startSenseID
        self.onTool = onTool
        self.onGlyph = onGlyph
        // Set before the first layout, so the sheet opens on the sense you tapped.
        _current = State(initialValue: startSenseID)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                senseTabs
                Divider()
                pages
            }
            .navigationTitle(store.button(current ?? startSenseID)?.name ?? "Senses")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Edit Senses") { editingSenses = true }
                        .accessibilityHint("Move, add, rename or remove your sense buttons.")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityHint("Closes the senses.")
                }
            }
            .sheet(item: $addingGlyphTo) { sense in
                GlyphMakerView(title: "New Glyph", addLabel: "Add Glyph") { name, symbol in
                    store.addGlyph(to: sense.id, name: name, symbol: symbol)
                }
            }
            .sheet(isPresented: $editingSenses) {
                SenseEditorView()
            }
            .onChange(of: store.buttons) { _, buttons in
                if let current, !buttons.contains(where: { $0.id == current }) { self.current = buttons.first?.id }
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 560)
        #endif
    }

    // MARK: - Sense buttons across the top

    private var senseTabs: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(store.buttons) { sense in
                    let isOn = sense.id == current
                    Button {
                        withAnimation { current = sense.id }
                    } label: {
                        Label(sense.name, systemImage: sense.glyph)
                            .font(.system(size: bodySize, weight: isOn ? .semibold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(isOn ? Color.white : Color.primary)
                            .background(Capsule().fill(isOn ? Color.accentColor : Color.secondary.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(sense.name)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                    .accessibilityHint("Shows the \(sense.name) page.")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Pages, swiped sideways

    private var pages: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(store.buttons) { sense in
                    page(sense)
                        .containerRelativeFrame(.horizontal)
                        .id(sense.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $current)
        .scrollIndicators(.hidden)
    }

    private func page(_ sense: SenseButton) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(sense.prompt)
                    .font(.system(size: headingSize, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: tileWidth), spacing: 12)], spacing: 12) {
                    ForEach(sense.tools) { tool in
                        Button { onTool(sense, tool) } label: { tile(tool.name, symbol: tool.glyph) }
                            .buttonStyle(.plain)
                            .accessibilityLabel(tool.name)
                            .accessibilityHint(toolHint(tool))
                            .accessibilityIdentifier("tool-\(sense.id)-\(tool.rawValue)")
                    }
                    ForEach(store.glyphs(for: sense)) { glyph in
                        Button { onGlyph(sense, glyph) } label: { tile(glyph.name, symbol: glyph.symbol) }
                            .buttonStyle(.plain)
                            .accessibilityLabel(glyph.name)
                            .accessibilityHint("Stamps \(glyph.name) on your entry.")
                    }
                    Button { addingGlyphTo = sense } label: { tile("Add Glyph", symbol: "plus") }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add Glyph")
                        .accessibilityHint("Makes your own \(sense.name) glyph.")
                        .accessibilityIdentifier("addGlyph-\(sense.id)")
                }
            }
            .padding()
        }
    }

    private func toolHint(_ tool: SenseTool) -> String {
        switch tool {
        case .camera: "Adds a picture under your entry."
        case .microphone: "Adds a recording under your entry."
        case .keyboard: "Adds something you type under your entry."
        }
    }

    /// One tile — tools and glyphs share this look (B-183.7.1, "unify the glyph motife").
    private func tile(_ name: String, symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: glyphSize))
                .foregroundStyle(Color.accentColor)
                .frame(height: glyphSize * 1.3)
            Text(name)
                .font(.system(size: bodySize))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: tileWidth)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.secondary.opacity(0.12)))
        .contentShape(RoundedRectangle(cornerRadius: 14))
    }
}
