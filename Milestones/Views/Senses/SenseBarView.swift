//
//  SenseBarView.swift
//  Milestones
//
//  REM: F-M1, his word 2026-11-09 20:2x: "i guess it looks okay as presented" — "senses pinned at the bottom"
//  (.safeAreaInset(edge: .bottom) › HStack in the mockup), so they stay put while you scroll.
//  REM: B-183.3.1: "the defaults are the five senses". B-183.5: you move, add, rename or remove them — the Edit
//  Senses tile at the end of the bar (and in each sense's sheet) opens SenseEditorView.
//

import SwiftUI

/// The senses bar at the bottom of an entry.
struct SenseBarView: View {
    let onSense: (SenseButton) -> Void
    let onEdit: () -> Void

    @State private var store = SenseBarStore.shared
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .title2) private var glyphSize: CGFloat = 24

    var body: some View {
        // Fits on one line when it can; scrolls sideways when your senses (or a bigger text size) don't fit.
        ViewThatFits(in: .horizontal) {
            row.padding(.horizontal, 8).frame(maxWidth: .infinity)
            ScrollView(.horizontal) { row.padding(.horizontal, 8) }
                .scrollIndicators(.hidden)
        }
        .padding(.vertical, 6)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private var row: some View {
        HStack(spacing: 4) {
            ForEach(store.buttons) { sense in
                Button { onSense(sense) } label: {
                    item(sense.name, glyph: sense.glyph)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(sense.name)
                .accessibilityHint("Opens the \(sense.name) glyphs and tools.")
                .accessibilityIdentifier("senseBar-\(sense.id)")
            }
            Button(action: onEdit) {
                item("Edit", glyph: "slider.horizontal.3")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit Senses")
            .accessibilityHint("Move, add, rename or remove your sense buttons.")
            .accessibilityIdentifier("senseBarEdit")
        }
    }

    private func item(_ name: String, glyph: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: glyph.isEmpty ? "sparkles" : glyph)
                .font(.system(size: glyphSize))
                .foregroundStyle(Color.accentColor)
            Text(name)
                .font(.system(size: bodySize))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
    }
}
