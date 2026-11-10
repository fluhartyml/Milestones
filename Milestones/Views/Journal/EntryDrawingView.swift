//
//  EntryDrawingView.swift
//  Milestones
//
//  REM: amber B-183.7 (locked 2026-11-09), his idea 2026-11-07: "Tapping one embeds the glyph in the journal entry so
//  you can type or draw near it with Apple Pencil." The glyphs (stickers) came in build 29; this is the drawing.
//  B-182.4: "handwriting and doodles anywhere on the page, writing sideways or around a drawing".
//  REM: PencilKit, checked in the SDKs on this Mac: PKCanvasView and PKToolPicker are in the iOS 27.1 and visionOS
//  27.0 SDKs; the macOS 27.0 SDK has PKDrawing but no PKCanvasView. So: draw on iPhone, iPad and Vision Pro; the Mac
//  shows the drawing (PKDrawing.image) but has no Draw button.
//  REM: Draw turns the entry card into a page you draw on and Done Drawing turns it back, so your finger still types and
//  scrolls the rest of the time. While drawing, a finger draws too (drawingPolicy .anyInput): iPhones other than the
//  ones that take a Pencil still get to draw, and Apple Pencil draws everywhere it's supported. Conservative choice; the
//  line names Apple Pencil, and nothing in it says a finger may not.
//  REM: the strokes are kept in points from the card's top left, so a drawing stays put beside its words; on a much
//  wider or narrower screen the words rewrap and the drawing doesn't (the same as stickers' fixed spots).
//

import SwiftUI
import PencilKit

/// The drawing layer on the entry card.
struct EntryDrawingLayer: View {
    @Bindable var entry: MilestoneEntry
    let isDrawing: Bool

    var body: some View {
        #if os(iOS) || os(visionOS)
        DrawingCanvas(data: $entry.drawing, isDrawing: isDrawing)
            .allowsHitTesting(isDrawing)
            .accessibilityLabel("Your drawing")
            .accessibilityHidden(entry.drawing == nil && !isDrawing)
        #else
        if let data = entry.drawing, let drawing = try? PKDrawing(data: data) {
            GeometryReader { geo in
                let image = drawing.image(from: CGRect(origin: .zero, size: geo.size), scale: 2)
                Image(nsImage: image)
                    .resizable()
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .allowsHitTesting(false)
            .accessibilityLabel("Your drawing")
        }
        #endif
    }
}

#if os(iOS) || os(visionOS)
/// A PencilKit canvas that keeps its drawing in `data`. Drawing only while `isDrawing`; otherwise it just shows it.
struct DrawingCanvas: UIViewRepresentable {
    @Binding var data: Data?
    let isDrawing: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.isScrollEnabled = false
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: 3)
        if let data, let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }
        context.coordinator.lastData = data
        canvas.delegate = context.coordinator
        context.coordinator.toolPicker.addObserver(canvas)
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        // Only when the stored drawing changed from outside (Clear Drawing), so a redraw never undoes a stroke.
        if data != context.coordinator.lastData {
            canvas.drawing = data.flatMap { try? PKDrawing(data: $0) } ?? PKDrawing()
            context.coordinator.lastData = data
        }
        canvas.isUserInteractionEnabled = isDrawing
        let picker = context.coordinator.toolPicker
        if isDrawing {
            picker.setVisible(true, forFirstResponder: canvas)
            if !canvas.isFirstResponder {
                DispatchQueue.main.async { canvas.becomeFirstResponder() }
            }
        } else if canvas.isFirstResponder || picker.isVisible {
            picker.setVisible(false, forFirstResponder: canvas)
            canvas.resignFirstResponder()
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingCanvas
        var lastData: Data?
        let toolPicker = PKToolPicker()

        init(_ parent: DrawingCanvas) { self.parent = parent }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let drawing = canvasView.drawing
            let saved: Data? = drawing.strokes.isEmpty ? nil : drawing.dataRepresentation()
            lastData = saved
            parent.data = saved
        }
    }
}
#endif

/// Draw / Done Drawing / Clear Drawing, under the entry card (iPhone, iPad, Vision Pro).
struct DrawingControls: View {
    @Bindable var entry: MilestoneEntry
    @Binding var isDrawing: Bool

    @State private var confirmingClear = false
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18

    var body: some View {
        #if os(iOS) || os(visionOS)
        HStack(spacing: 12) {
            Button {
                isDrawing.toggle()
            } label: {
                Label(isDrawing ? "Done Drawing" : "Draw", systemImage: isDrawing ? "checkmark" : "pencil.tip")
                    .font(.system(size: bodySize, weight: .semibold))
            }
            .accessibilityLabel(isDrawing ? "Done Drawing" : "Draw")
            .accessibilityHint(isDrawing ? "Puts the pen away." : "Draw or write on your entry with Apple Pencil or your finger.")
            .accessibilityIdentifier("entryDraw")

            if entry.drawing != nil {
                Button(role: .destructive) {
                    confirmingClear = true
                } label: {
                    Label("Clear Drawing", systemImage: "trash")
                        .font(.system(size: bodySize, weight: .semibold))
                }
                .accessibilityLabel("Clear Drawing")
                .accessibilityHint("Erases everything you drew on this entry.")
                .accessibilityIdentifier("entryClearDrawing")
            }
        }
        .buttonStyle(.bordered)
        .confirmationDialog("Erase your drawing?", isPresented: $confirmingClear, titleVisibility: .visible) {
            Button("Clear Drawing", role: .destructive) { entry.drawing = nil }
            Button("Keep It", role: .cancel) {}
        }
        #endif
    }
}
