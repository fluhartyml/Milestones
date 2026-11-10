//
//  SenseEditorView.swift
//  Milestones
//
//  REM: amber B-183.5 / F-183.5 (locked 2026-11-09), his word 2026-11-07 (like Daylio): "you can move, add, rename or
//  remove the sense buttons. A new one gets a glyph you choose and a title you write." The model: "drag a sense to
//  move it, tap its name to rename it, tap its glyph to change it, use ✕ to remove it, and use ＋ Add to make your own."
//  REM: dragging is never the only way (his rule): each sense's page also has Move Left / Move Right and Remove Sense.
//  REM: B-183.7.2 — the glyphs you added to a sense are listed on its page, each with a Remove button.
//

import SwiftUI

/// The list of sense buttons: tap one to change it, drag to reorder, Add Sense to make your own.
struct SenseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = SenseBarStore.shared
    @State private var addingSense = false
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.buttons) { sense in
                        NavigationLink {
                            SenseDetailEditor(senseID: sense.id)
                        } label: {
                            Label(sense.name, systemImage: sense.glyph)
                                .font(.system(size: bodySize))
                        }
                        .accessibilityLabel(sense.name)
                        .accessibilityHint("Rename, move or remove \(sense.name), or change its glyph.")
                    }
                    .onMove { store.move(fromOffsets: $0, toOffset: $1) }
                } header: {
                    Text("Your Sense Buttons").font(.system(size: bodySize))
                } footer: {
                    Text("They show in this order at the bottom of every entry.").font(.system(size: bodySize))
                }

                Section {
                    Button { addingSense = true } label: {
                        Label("Add Sense", systemImage: "plus")
                            .font(.system(size: bodySize, weight: .semibold))
                    }
                    .accessibilityHint("Makes a new sense button with a glyph you choose and a name you write.")
                    .accessibilityIdentifier("addSense")
                    if store.isMissingAFiveSense {
                        Button { store.restoreFiveSenses() } label: {
                            Label("Restore Five Senses", systemImage: "arrow.uturn.backward")
                                .font(.system(size: bodySize, weight: .semibold))
                        }
                        .accessibilityHint("Puts back Sight, Hearing, Touch, Smell or Taste if you removed them.")
                    }
                }
            }
            .navigationTitle("Edit Senses")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    EditButton()
                        .accessibilityHint("Lets you drag sense buttons into a new order.")
                }
                #endif
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $addingSense) {
                GlyphMakerView(title: "New Sense", addLabel: "Add Sense") { name, symbol in
                    store.addSense(name: name, glyph: symbol)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 520)
        #endif
    }
}

/// One sense button: its name, its glyph, its place in the bar, the glyphs you added to it.
struct SenseDetailEditor: View {
    let senseID: String
    @Environment(\.dismiss) private var dismiss
    @State private var store = SenseBarStore.shared
    @State private var name = ""
    @State private var addingGlyph = false
    @State private var confirmingRemove = false
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18

    private var sense: SenseButton? { store.button(senseID) }
    private var index: Int? { store.buttons.firstIndex { $0.id == senseID } }

    var body: some View {
        Form {
            if let sense {
                Section {
                    TextField(text: $name, prompt: Text("Sense name")) { Text("Sense name") }
                        .labelsHidden()
                        .font(.system(size: bodySize))
                        .accessibilityLabel("Sense name")
                        .onChange(of: name) { _, typed in
                            let trimmed = typed.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty { store.rename(senseID, to: trimmed) }
                        }
                } header: {
                    Text("Name").font(.system(size: bodySize))
                }

                Section {
                    GlyphChooser(selected: Binding(get: { sense.glyph }, set: { store.setGlyph(senseID, to: $0) }))
                } header: {
                    Text("Glyph").font(.system(size: bodySize))
                }

                Section {
                    HStack(spacing: 12) {
                        Button { store.move(senseID, by: -1) } label: {
                            Label("Move Left", systemImage: "arrow.left").font(.system(size: bodySize))
                        }
                        .disabled(index == 0)
                        Button { store.move(senseID, by: 1) } label: {
                            Label("Move Right", systemImage: "arrow.right").font(.system(size: bodySize))
                        }
                        .disabled(index == store.buttons.count - 1)
                    }
                    .buttonStyle(.bordered)
                } header: {
                    Text("Place in the Bar").font(.system(size: bodySize))
                }

                Section {
                    let own = store.ownGlyphs[senseID] ?? []
                    ForEach(own) { glyph in
                        HStack {
                            Label(glyph.name, systemImage: glyph.symbol).font(.system(size: bodySize))
                            Spacer()
                            Button(role: .destructive) { store.removeGlyph(glyph.id, from: senseID) } label: {
                                Text("Remove").font(.system(size: bodySize))
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Remove \(glyph.name)")
                        }
                    }
                    Button { addingGlyph = true } label: {
                        Label("Add Glyph", systemImage: "plus").font(.system(size: bodySize, weight: .semibold))
                    }
                    .accessibilityHint("Makes your own \(sense.name) glyph.")
                } header: {
                    Text("Your Glyphs").font(.system(size: bodySize))
                } footer: {
                    Text("Glyphs already stamped on your entries stay there.").font(.system(size: bodySize))
                }

                Section {
                    Button(role: .destructive) { confirmingRemove = true } label: {
                        Label("Remove Sense", systemImage: "trash").font(.system(size: bodySize, weight: .semibold))
                    }
                    .accessibilityHint("Takes \(sense.name) off the bar. Your entries keep what you added with it.")
                }
            }
        }
        .navigationTitle(sense?.name ?? "Sense")
        .onAppear { name = sense?.name ?? "" }
        .confirmationDialog("Remove this sense button?", isPresented: $confirmingRemove, titleVisibility: .visible) {
            Button("Remove Sense", role: .destructive) {
                store.remove(senseID)
                dismiss()
            }
            Button("Keep It", role: .cancel) {}
        } message: {
            Text("Your entries keep everything you added with it.")
        }
        .sheet(isPresented: $addingGlyph) {
            GlyphMakerView(title: "New Glyph", addLabel: "Add Glyph") { name, symbol in
                store.addGlyph(to: senseID, name: name, symbol: symbol)
            }
        }
    }
}

/// Make a glyph or a sense: write a name, choose a glyph.
struct GlyphMakerView: View {
    let title: String
    let addLabel: String
    let onMake: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var symbol = ""
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(text: $name, prompt: Text("Name, like Sweater")) { Text("Name") }
                        .labelsHidden()
                        .font(.system(size: bodySize))
                        .accessibilityLabel("Name")
                        .accessibilityIdentifier("glyphMakerName")
                } header: {
                    Text("Name").font(.system(size: bodySize))
                }
                Section {
                    GlyphChooser(selected: Binding(get: { symbol }, set: { picked in
                        symbol = picked
                        // Fill in the glyph's name when you haven't written one.
                        if trimmed.isEmpty, let glyph = SenseBarStore.choosable.first(where: { $0.symbol == picked }) {
                            name = glyph.name
                        }
                    }))
                } header: {
                    Text("Glyph").font(.system(size: bodySize))
                }
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(addLabel) {
                        onMake(trimmed, symbol)
                        dismiss()
                    }
                    .disabled(trimmed.isEmpty || symbol.isEmpty)
                    .accessibilityIdentifier("glyphMakerAdd")
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 520)
        #endif
    }
}

/// A grid of glyphs to choose from; the chosen one is filled in.
struct GlyphChooser: View {
    @Binding var selected: String
    @ScaledMetric(relativeTo: .title2) private var glyphSize: CGFloat = 26
    @ScaledMetric(relativeTo: .body) private var cell: CGFloat = 56

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: cell), spacing: 8)], spacing: 8) {
            ForEach(SenseBarStore.choosable) { glyph in
                let isOn = glyph.symbol == selected
                Button { selected = glyph.symbol } label: {
                    Image(systemName: glyph.symbol)
                        .font(.system(size: glyphSize))
                        .frame(width: cell, height: cell)
                        .foregroundStyle(isOn ? Color.white : Color.accentColor)
                        .background(RoundedRectangle(cornerRadius: 10)
                            .fill(isOn ? Color.accentColor : Color.secondary.opacity(0.12)))
                        .contentShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(glyph.name)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}
