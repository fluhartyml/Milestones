//
//  TapedIn.swift
//  Milestones
//
//  REM: amber B-182.4, his design 2026-11-14 (mapped in chat, then "code it"): scan a ticket (movie, game, a used
//  airline ticket) with the camera, paste it "at any angle 180 or any angular degree", "place it with washi tape like
//  embellishments", and "pinch zoom / resize it too". Photos work the same way; washi tape can also go on alone.
//  REM: Claude's calls: the scan uses Apple's document scanner (it finds the ticket's edges and crops it) on iPhone and
//  iPad; the Mac and Vision Pro pick a picture instead. A new ticket or photo lands with washi strips on two corners
//  and a small tilt, like a hand taped it; tape can be changed or taken off. Drag moves, two fingers twist and pinch,
//  and buttons do all of it too (his rule: a gesture is never the only way). Pictures are shrunk to 1600 px on the long
//  side before saving, so a page full of tickets stays light in iCloud.
//

import PhotosUI
import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if os(iOS)
import VisionKit
#endif
#if os(macOS)
import AppKit
#endif

// MARK: - Washi tape

enum WashiPattern: String, CaseIterable, Identifiable {
    case pinkStripes, mintDots, blueGingham, yellowStars, redHearts, plainKraft
    var id: String { rawValue }
    var name: String {
        switch self {
        case .pinkStripes: "Pink Stripes"
        case .mintDots: "Mint Dots"
        case .blueGingham: "Blue Gingham"
        case .yellowStars: "Yellow Stars"
        case .redHearts: "Red Hearts"
        case .plainKraft: "Plain Kraft"
        }
    }
    var base: Color {
        switch self {
        case .pinkStripes: Color(red: 1.0, green: 0.80, blue: 0.86)
        case .mintDots: Color(red: 0.72, green: 0.93, blue: 0.84)
        case .blueGingham: Color(red: 0.85, green: 0.91, blue: 1.0)
        case .yellowStars: Color(red: 1.0, green: 0.92, blue: 0.55)
        case .redHearts: Color(red: 1.0, green: 0.95, blue: 0.93)
        case .plainKraft: Color(red: 0.84, green: 0.72, blue: 0.53)
        }
    }
    var ink: Color {
        switch self {
        case .pinkStripes: Color(red: 0.92, green: 0.45, blue: 0.60)
        case .mintDots: Color(red: 0.20, green: 0.60, blue: 0.45)
        case .blueGingham: Color(red: 0.35, green: 0.55, blue: 0.90)
        case .yellowStars: Color(red: 0.90, green: 0.55, blue: 0.10)
        case .redHearts: Color(red: 0.85, green: 0.15, blue: 0.25)
        case .plainKraft: Color(red: 0.60, green: 0.45, blue: 0.28)
        }
    }
}

/// A strip of washi tape: see-through paper with a pattern and torn ends.
struct WashiStrip: View {
    let pattern: WashiPattern

    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            // Torn ends: a zigzag on the left and right.
            var strip = Path()
            let teeth = max(3, Int(h / 4))
            strip.move(to: CGPoint(x: 3, y: 0))
            strip.addLine(to: CGPoint(x: w - 3, y: 0))
            for k in 0...teeth {
                let y = h * CGFloat(k) / CGFloat(teeth)
                strip.addLine(to: CGPoint(x: k.isMultiple(of: 2) ? w : w - 4, y: y))
            }
            strip.addLine(to: CGPoint(x: 3, y: h))
            for k in stride(from: teeth, through: 0, by: -1) {
                let y = h * CGFloat(k) / CGFloat(teeth)
                strip.addLine(to: CGPoint(x: k.isMultiple(of: 2) ? 0 : 4, y: y))
            }
            strip.closeSubpath()
            context.clip(to: strip)
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(pattern.base.opacity(0.82)))
            let ink = pattern.ink.opacity(0.75)
            switch pattern {
            case .pinkStripes:
                var x: CGFloat = -h
                while x < w {
                    var band = Path()
                    band.move(to: CGPoint(x: x, y: h)); band.addLine(to: CGPoint(x: x + h, y: 0))
                    context.stroke(band, with: .color(ink), lineWidth: h * 0.16)
                    x += h * 0.45
                }
            case .mintDots:
                let step = h * 0.4
                var y = step / 2, row = 0
                while y < h {
                    var x = row.isMultiple(of: 2) ? step / 2 : step
                    while x < w {
                        context.fill(Path(ellipseIn: CGRect(x: x - h * 0.08, y: y - h * 0.08, width: h * 0.16, height: h * 0.16)),
                                     with: .color(ink))
                        x += step
                    }
                    y += step / 1.4; row += 1
                }
            case .blueGingham:
                let step = h * 0.33
                var x: CGFloat = 0
                while x < w { context.fill(Path(CGRect(x: x, y: 0, width: step / 2, height: h)), with: .color(ink.opacity(0.4))); x += step }
                var y: CGFloat = 0
                while y < h { context.fill(Path(CGRect(x: 0, y: y, width: w, height: step / 2)), with: .color(ink.opacity(0.4))); y += step }
            case .yellowStars:
                var x = h * 0.5
                while x < w {
                    context.fill(DiaryShapes.star(center: CGPoint(x: x, y: h / 2), radius: h * 0.28), with: .color(ink))
                    x += h * 0.9
                }
            case .redHearts:
                var x = h * 0.3
                while x < w {
                    context.fill(DiaryShapes.heart(in: CGRect(x: x, y: h * 0.25, width: h * 0.5, height: h * 0.5)), with: .color(ink))
                    x += h * 0.9
                }
            case .plainKraft:
                break
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - The layer on the entry card

struct TapedInLayer: View {
    let entry: MilestoneEntry
    @Binding var selectedID: PersistentIdentifier?

    var body: some View {
        GeometryReader { geo in
            ForEach(entry.sortedTapedItems) { item in
                TapedItemView(item: item, area: geo.size, isSelected: item.persistentModelID == selectedID) {
                    selectedID = selectedID == item.persistentModelID ? nil : item.persistentModelID
                }
            }
        }
    }
}

struct TapedItemView: View {
    @Bindable var item: TapedItem
    let area: CGSize
    let isSelected: Bool
    let onTap: () -> Void

    @State private var drag: CGSize = .zero
    @State private var turn: Angle = .zero
    @State private var pinch: CGFloat = 1
    @State private var picture: Image?
    @ScaledMetric(relativeTo: .body) private var baseWidth: CGFloat = 150
    @ScaledMetric(relativeTo: .body) private var tapeHeight: CGFloat = 22

    private var scale: CGFloat { CGFloat(item.scale) * pinch }

    var body: some View {
        content
            .overlay {
                if isSelected {
                    Rectangle().strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .padding(-4)
                }
            }
            .contentShape(Rectangle())
            .rotationEffect(.degrees(item.rotation) + turn)
            // Gestures sit before .position so only the item itself takes the touch, not the whole card.
            .gesture(
                DragGesture(minimumDistance: 6)
                    .onChanged { drag = $0.translation }
                    .onEnded { value in
                        guard area.width > 0, area.height > 0 else { drag = .zero; return }
                        item.x = min(max(item.x + value.translation.width / area.width, 0.02), 0.98)
                        item.y = min(max(item.y + value.translation.height / area.height, 0.02), 0.98)
                        drag = .zero
                    }
            )
            .simultaneousGesture(
                RotateGesture()
                    .onChanged { turn = $0.rotation }
                    .onEnded { value in
                        item.rotation = TapedItemView.normalized(item.rotation + value.rotation.degrees)
                        turn = .zero
                    }
            )
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { pinch = $0.magnification }
                    .onEnded { value in
                        item.scale = TapedItemView.clampedScale(item.scale * value.magnification)
                        pinch = 1
                    }
            )
            .onTapGesture(perform: onTap)
            .accessibilityElement()
            .accessibilityLabel(item.name)
            .accessibilityValue("Turned \(Int(item.rotation)) degrees, \(Int(item.scale * 100)) percent size")
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint("Shows buttons to move, turn, resize, tape or remove it.")
            .offset(drag)
            .position(x: item.x * area.width, y: item.y * area.height)
            .task(id: item.imageData?.count) { picture = TapedPicture.image(from: item.imageData) }
    }

    @ViewBuilder
    private var content: some View {
        if item.kind == "tape" {
            WashiStrip(pattern: WashiPattern(rawValue: item.tape) ?? .pinkStripes)
                .frame(width: baseWidth * 0.8 * scale, height: tapeHeight * scale)
                .shadow(color: .black.opacity(0.15), radius: 1, y: 0.5)
        } else {
            let w = baseWidth * scale
            let h = w / max(0.2, CGFloat(item.aspect))
            Group {
                if let picture {
                    picture.resizable().scaledToFill()
                } else {
                    Rectangle().fill(Color.secondary.opacity(0.2))
                }
            }
            .frame(width: w, height: h)
            .clipped()
            // A photo gets a white print border; a ticket keeps its own edges.
            .padding(item.kind == "photo" ? 5 * scale : 0)
            .background(item.kind == "photo" ? Color.white : Color.clear)
            .shadow(color: .black.opacity(0.3), radius: 3, x: 1, y: 2)
            .overlay(alignment: .topLeading) { cornerTape(w: w, flip: false) }
            .overlay(alignment: .bottomTrailing) { cornerTape(w: w, flip: true) }
        }
    }

    @ViewBuilder
    private func cornerTape(w: CGFloat, flip: Bool) -> some View {
        if let pattern = WashiPattern(rawValue: item.tape) {
            WashiStrip(pattern: pattern)
                .frame(width: min(w * 0.45, baseWidth * 0.5 * scale), height: tapeHeight * scale)
                .rotationEffect(.degrees(-38))
                .offset(x: flip ? tapeHeight * scale * 0.6 : -tapeHeight * scale * 0.6,
                        y: flip ? tapeHeight * scale * 0.2 : -tapeHeight * scale * 0.2)
                .allowsHitTesting(false)
        }
    }

    static func normalized(_ degrees: Double) -> Double {
        var d = degrees.truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d <= -180 { d += 360 }
        return d
    }

    static func clampedScale(_ s: Double) -> Double { min(max(s, 0.3), 4) }
}

// MARK: - Pictures

enum TapedPicture {
    /// Shrinks to 1600 px on the long side and saves as JPEG. Returns the data and width ÷ height.
    static func prepare(_ data: Data) -> (Data, Double)? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        return prepare(image)
        #elseif os(macOS)
        guard let image = NSImage(data: data), let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let size = CGSize(width: cg.width, height: cg.height)
        let fit = min(1, 1600 / max(size.width, size.height))
        let target = CGSize(width: (size.width * fit).rounded(), height: (size.height * fit).rounded())
        guard let ctx = CGContext(data: nil, width: Int(target.width), height: Int(target.height), bitsPerComponent: 8,
                                  bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.interpolationQuality = .high
        ctx.draw(cg, in: CGRect(origin: .zero, size: target))
        guard let small = ctx.makeImage(),
              let jpeg = NSBitmapImageRep(cgImage: small).representation(using: .jpeg, properties: [.compressionFactor: 0.8])
        else { return nil }
        return (jpeg, Double(target.width / max(1, target.height)))
        #else
        return nil
        #endif
    }

    #if canImport(UIKit)
    static func prepare(_ image: UIImage) -> (Data, Double)? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let fit = min(1, 1600 / max(size.width, size.height))
        let target = CGSize(width: (size.width * fit).rounded(), height: (size.height * fit).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let small = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        guard let jpeg = small.jpegData(compressionQuality: 0.8) else { return nil }
        return (jpeg, Double(target.width / target.height))
    }
    #endif

    static func image(from data: Data?) -> Image? {
        guard let data else { return nil }
        #if canImport(UIKit)
        return UIImage(data: data).map { Image(uiImage: $0) }
        #elseif os(macOS)
        return NSImage(data: data).map { Image(nsImage: $0) }
        #else
        return nil
        #endif
    }
}

// MARK: - Ticket scanner (iPhone and iPad)

#if os(iOS)
/// Apple's document scanner: finds the ticket's edges in the camera and crops it flat.
struct TicketScanner: UIViewControllerRepresentable {
    let onFinish: (UIImage?) -> Void

    static var isAvailable: Bool { VNDocumentCameraViewController.isSupported }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onFinish: (UIImage?) -> Void
        init(onFinish: @escaping (UIImage?) -> Void) { self.onFinish = onFinish }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            onFinish(scan.pageCount > 0 ? scan.imageOfPage(at: 0) : nil)
        }
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) { onFinish(nil) }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onFinish(nil)
        }
    }
}
#endif

// MARK: - Tape In (the buttons under the entry)

struct TapeInControls: View {
    @Bindable var entry: MilestoneEntry
    @Binding var selectedID: PersistentIdentifier?
    @Environment(\.modelContext) private var modelContext

    @State private var scanning = false
    @State private var photoItem: PhotosPickerItem?
    @State private var photoKind = "photo"
    @State private var choosingPhoto = false
    @State private var problem: String?
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18

    private var selected: TapedItem? {
        guard let selectedID else { return nil }
        return entry.sortedTapedItems.first { $0.persistentModelID == selectedID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Menu {
                #if os(iOS)
                if TicketScanner.isAvailable {
                    Button { scanning = true } label: { Label("Scan a Ticket", systemImage: "ticket") }
                }
                #endif
                Button { photoKind = "ticket"; choosingPhoto = true } label: {
                    Label("Ticket from Photos", systemImage: "ticket.fill")
                }
                Button { photoKind = "photo"; choosingPhoto = true } label: {
                    Label("Photo", systemImage: "photo")
                }
                Menu {
                    ForEach(WashiPattern.allCases) { pattern in
                        Button(pattern.name) { addTape(pattern) }
                    }
                } label: { Label("Washi Tape", systemImage: "bandage") }
            } label: {
                Label("Tape In", systemImage: "paperclip")
                    .font(.system(size: bodySize, weight: .semibold))
            }
            .accessibilityHint("Scan a ticket, add a photo, or lay a strip of washi tape on your entry.")
            .accessibilityIdentifier("tapeIn")

            if let problem {
                Text(problem).font(.system(size: bodySize)).foregroundStyle(.secondary)
            }
            if let item = selected {
                itemControls(item)
            }
        }
        .padding(.vertical, 4)
        .photosPicker(isPresented: $choosingPhoto, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let (jpeg, aspect) = TapedPicture.prepare(data) {
                    add(kind: photoKind, data: jpeg, aspect: aspect)
                } else {
                    problem = "That picture couldn't be opened. Try another one."
                }
                photoItem = nil
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $scanning) {
            TicketScanner { image in
                scanning = false
                if let image, let (jpeg, aspect) = TapedPicture.prepare(image) {
                    add(kind: "ticket", data: jpeg, aspect: aspect)
                }
            }
            .ignoresSafeArea()
        }
        #endif
    }

    private func add(kind: String, data: Data, aspect: Double) {
        problem = nil
        let count = entry.sortedTapedItems.count
        let tilt = [-6.0, 4.0, -3.0, 7.0, -8.0][count % 5]
        let item = TapedItem(kind: kind, imageData: data, aspect: aspect, tape: WashiPattern.allCases[count % WashiPattern.allCases.count].rawValue,
                             x: 0.5, y: 0.35 + Double(count % 3) * 0.12, rotation: tilt)
        modelContext.insert(item)
        item.entry = entry
        selectedID = item.persistentModelID
    }

    private func addTape(_ pattern: WashiPattern) {
        let count = entry.sortedTapedItems.count
        let item = TapedItem(kind: "tape", imageData: nil, aspect: 1, tape: pattern.rawValue,
                             x: 0.3 + Double(count % 3) * 0.2, y: 0.2, rotation: [-12.0, 8.0, -4.0][count % 3])
        modelContext.insert(item)
        item.entry = entry
        selectedID = item.persistentModelID
    }

    /// Buttons for everything the fingers do: move, turn, resize, tape, remove.
    private func itemControls(_ item: TapedItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(item.name, systemImage: item.kind == "tape" ? "bandage" : (item.kind == "ticket" ? "ticket" : "photo"))
                .font(.system(size: bodySize, weight: .semibold))
            Text("Drag to move. Twist with two fingers to turn it, pinch to resize it.")
                .font(.system(size: bodySize)).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                small("Move Left", "arrow.left") { item.x = max(0.02, item.x - 0.05) }
                small("Move Up", "arrow.up") { item.y = max(0.02, item.y - 0.05) }
                small("Move Down", "arrow.down") { item.y = min(0.98, item.y + 0.05) }
                small("Move Right", "arrow.right") { item.x = min(0.98, item.x + 0.05) }
            }
            HStack(spacing: 8) {
                small("Turn Left", "rotate.left") { item.rotation = TapedItemView.normalized(item.rotation - 15) }
                small("Turn Right", "rotate.right") { item.rotation = TapedItemView.normalized(item.rotation + 15) }
                small("Smaller", "minus.magnifyingglass") { item.scale = TapedItemView.clampedScale(item.scale / 1.15) }
                small("Bigger", "plus.magnifyingglass") { item.scale = TapedItemView.clampedScale(item.scale * 1.15) }
            }
            Picker(selection: Binding(get: { item.tape }, set: { item.tape = $0 })) {
                if item.kind != "tape" { Text("No Tape").tag("") }
                ForEach(WashiPattern.allCases) { Text($0.name).tag($0.rawValue) }
            } label: { Text(item.kind == "tape" ? "Pattern" : "Washi Tape").font(.system(size: bodySize)) }
            HStack(spacing: 12) {
                Button(role: .destructive) {
                    selectedID = nil
                    modelContext.delete(item)
                } label: {
                    Label("Remove", systemImage: "trash").font(.system(size: bodySize, weight: .semibold))
                }
                .accessibilityHint("Peels it off your entry.")
                Button { selectedID = nil } label: {
                    Text("Done").font(.system(size: bodySize, weight: .semibold))
                }
                .accessibilityHint("Leaves it where it is.")
            }
            .buttonStyle(.bordered)
        }
    }

    private func small(_ name: String, _ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: bodySize, weight: .semibold)).frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(name)
    }
}
