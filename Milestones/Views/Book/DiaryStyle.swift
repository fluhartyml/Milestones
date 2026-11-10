//
//  DiaryStyle.swift
//  Milestones
//
//  REM: amber B-182.2 (locked 2026-11-09), his idea 2026-11-07: "on the iPhone Duo, Milestones should work like a real
//  diary. You personalize the cover ... or a mash-up where you mix and match pieces of each." Mix and match = each
//  piece is its own choice (cover, spine, ribbon, pages, paper), in Settings › Your Diary.
//  REM: B-182.3, his inspiration: "111 notebook and diary photos ... reference only, none of it copied." Built from the
//  pieces that line names that show on an OPEN book, all drawn in code (no artwork taken from anywhere):
//    Covers  — "black or colored marble (composition book), plain kraft card (pocket memo), leather or faux leather,
//              solid colors" → Black Marble, Blue Marble, Kraft Card, Leather, Red, Blue, Green, Purple.
//    Spine   — "taped cloth spine, spiral wire, stitched, a ribbon bookmark" → Cloth Tape, Spiral Wire, Stitched; Ribbon.
//    Pages   — "wide or college ruled, grid, dotted, blank ... aged and yellowed paper" → those five, White or Aged.
//  Not built (reported, not invented): floral/botanical and doodle/sticker-bomb covers (they need artwork), the
//  gold-stamped year or name and the closures (they show on a closed book, and the Duo's closed screen is the phone),
//  one-day-per-page and handwriting fonts, and the Extras (tabs, flags, pen loop, back pocket).
//

import SwiftUI

enum DiaryKeys {
    static let cover = "diaryCover"
    static let binding = "diaryBinding"
    static let ribbon = "diaryRibbon"
    static let pages = "diaryPages"
    static let paper = "diaryPaper"
}

enum DiaryCover: String, CaseIterable, Identifiable {
    case blackMarble, blueMarble, kraft, leather, red, blue, green, purple

    var id: String { rawValue }

    var name: String {
        switch self {
        case .blackMarble: "Black Marble"
        case .blueMarble: "Blue Marble"
        case .kraft: "Kraft Card"
        case .leather: "Leather"
        case .red: "Red"
        case .blue: "Blue"
        case .green: "Green"
        case .purple: "Purple"
        }
    }

    var base: Color {
        switch self {
        case .blackMarble: Color(red: 0.08, green: 0.08, blue: 0.09)
        case .blueMarble: Color(red: 0.10, green: 0.20, blue: 0.45)
        case .kraft: Color(red: 0.76, green: 0.62, blue: 0.43)
        case .leather: Color(red: 0.36, green: 0.21, blue: 0.12)
        case .red: Color(red: 0.62, green: 0.10, blue: 0.12)
        case .blue: Color(red: 0.12, green: 0.27, blue: 0.55)
        case .green: Color(red: 0.13, green: 0.40, blue: 0.24)
        case .purple: Color(red: 0.36, green: 0.18, blue: 0.48)
        }
    }

    /// The darker band a cloth tape spine shows.
    var tape: Color {
        switch self {
        case .blackMarble, .blueMarble: Color(red: 0.05, green: 0.05, blue: 0.06)
        case .kraft: Color(red: 0.20, green: 0.20, blue: 0.22)
        default: base.opacity(0.75)
        }
    }
}

enum DiaryBinding: String, CaseIterable, Identifiable {
    case clothTape, spiral, stitched
    var id: String { rawValue }
    var name: String {
        switch self {
        case .clothTape: "Cloth Tape"
        case .spiral: "Spiral Wire"
        case .stitched: "Stitched"
        }
    }
}

enum DiaryPages: String, CaseIterable, Identifiable {
    case blank, wideRuled, collegeRuled, grid, dotted
    var id: String { rawValue }
    var name: String {
        switch self {
        case .blank: "Blank"
        case .wideRuled: "Wide Ruled"
        case .collegeRuled: "College Ruled"
        case .grid: "Grid"
        case .dotted: "Dotted"
        }
    }
}

enum DiaryPaper: String, CaseIterable, Identifiable {
    case white, aged
    var id: String { rawValue }
    var name: String {
        switch self {
        case .white: "White"
        case .aged: "Aged"
        }
    }
    var color: Color {
        switch self {
        case .white: Color(red: 0.99, green: 0.99, blue: 0.98)
        case .aged: Color(red: 0.95, green: 0.90, blue: 0.77)
        }
    }
}

/// Repeatable "random" numbers, so a marble cover looks the same every time it's drawn.
private struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((state >> 33) % 1_000_000) / 1_000_000
    }
}

// MARK: - Cover

struct DiaryCoverView: View {
    let cover: DiaryCover

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .color(cover.base))
            var random = SeededRandom(seed: 1975)
            switch cover {
            case .blackMarble, .blueMarble:
                // Composition-book marble: many small pale flecks at every angle.
                let count = min(2400, max(60, Int(size.width * size.height / 260)))
                for _ in 0..<count {
                    let x = random.next() * size.width
                    let y = random.next() * size.height
                    let w = 3 + random.next() * 12
                    let h = 1.5 + random.next() * 5
                    let fleck = Path(ellipseIn: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
                        .applying(CGAffineTransform(rotationAngle: random.next() * .pi))
                        .applying(CGAffineTransform(translationX: x, y: y))
                    context.fill(fleck, with: .color(.white.opacity(0.35 + random.next() * 0.55)))
                }
            case .kraft:
                // Kraft card: fine dark fibers.
                let count = min(3000, max(60, Int(size.width * size.height / 120)))
                for _ in 0..<count {
                    let x = random.next() * size.width
                    let y = random.next() * size.height
                    let fiber = Path(CGRect(x: x, y: y, width: 1 + random.next() * 3, height: 1))
                    context.fill(fiber, with: .color(.black.opacity(0.08 + random.next() * 0.12)))
                }
            case .leather:
                // Leather: soft grain and a stitched edge.
                let count = min(3000, max(60, Int(size.width * size.height / 90)))
                for _ in 0..<count {
                    let x = random.next() * size.width
                    let y = random.next() * size.height
                    let d = 1 + random.next() * 2.5
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: d, height: d)),
                                 with: .color(.black.opacity(0.10 + random.next() * 0.12)))
                }
                context.stroke(Path(roundedRect: rect.insetBy(dx: 5, dy: 5), cornerRadius: 6),
                               with: .color(Color(red: 0.93, green: 0.84, blue: 0.66).opacity(0.7)),
                               style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            default:
                // Solid cloth: a light sheen from the top corner.
                context.fill(Path(rect), with: .linearGradient(
                    Gradient(colors: [.white.opacity(0.14), .clear, .black.opacity(0.18)]),
                    startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
            }
        }
    }
}

// MARK: - Paper

struct DiaryPaperView: View {
    let pages: DiaryPages
    let paper: DiaryPaper

    /// Line spacing grows with your text size, so ruled lines stay about one line of writing apart.
    @ScaledMetric(relativeTo: .body) private var wide: CGFloat = 34

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .color(paper.color))
            let rule = Color(red: 0.35, green: 0.55, blue: 0.85)
            switch pages {
            case .blank:
                break
            case .wideRuled, .collegeRuled:
                let step = pages == .wideRuled ? wide : wide * 0.78
                var lines = Path()
                var y = step * 2
                while y < size.height {
                    lines.move(to: CGPoint(x: 0, y: y))
                    lines.addLine(to: CGPoint(x: size.width, y: y))
                    y += step
                }
                context.stroke(lines, with: .color(rule.opacity(0.35)), lineWidth: 1)
                var margin = Path()
                margin.move(to: CGPoint(x: step * 1.4, y: 0))
                margin.addLine(to: CGPoint(x: step * 1.4, y: size.height))
                context.stroke(margin, with: .color(Color.red.opacity(0.35)), lineWidth: 1)
            case .grid:
                let step = wide * 0.66
                var lines = Path()
                var x: CGFloat = step
                while x < size.width {
                    lines.move(to: CGPoint(x: x, y: 0)); lines.addLine(to: CGPoint(x: x, y: size.height)); x += step
                }
                var y: CGFloat = step
                while y < size.height {
                    lines.move(to: CGPoint(x: 0, y: y)); lines.addLine(to: CGPoint(x: size.width, y: y)); y += step
                }
                context.stroke(lines, with: .color(rule.opacity(0.22)), lineWidth: 1)
            case .dotted:
                let step = wide * 0.66
                var dots = Path()
                var y: CGFloat = step
                while y < size.height {
                    var x: CGFloat = step
                    while x < size.width {
                        dots.addEllipse(in: CGRect(x: x - 1.2, y: y - 1.2, width: 2.4, height: 2.4))
                        x += step
                    }
                    y += step
                }
                context.fill(dots, with: .color(.gray.opacity(0.45)))
            }
            if paper == .aged {
                // Yellowed toward the edges, the way old paper goes.
                context.fill(Path(rect), with: .radialGradient(
                    Gradient(colors: [.clear, Color(red: 0.55, green: 0.38, blue: 0.15).opacity(0.22)]),
                    center: CGPoint(x: size.width / 2, y: size.height / 2),
                    startRadius: min(size.width, size.height) * 0.3,
                    endRadius: max(size.width, size.height) * 0.75))
            }
        }
    }
}

// MARK: - Spine

struct DiarySpineView: View {
    let binding: DiaryBinding
    let cover: DiaryCover

    var body: some View {
        Canvas { context, size in
            let mid = size.width / 2
            switch binding {
            case .clothTape:
                context.fill(Path(CGRect(x: size.width * 0.15, y: 0, width: size.width * 0.7, height: size.height)),
                             with: .color(cover.tape))
            case .stitched:
                context.fill(Path(CGRect(x: 0, y: 0, width: size.width, height: size.height)),
                             with: .color(Color(red: 0.97, green: 0.96, blue: 0.93)))
                var thread = Path()
                thread.move(to: CGPoint(x: mid, y: 0))
                thread.addLine(to: CGPoint(x: mid, y: size.height))
                context.stroke(thread, with: .color(Color(red: 0.45, green: 0.35, blue: 0.25)),
                               style: StrokeStyle(lineWidth: 2, dash: [10, 8]))
            case .spiral:
                var y: CGFloat = 10
                while y < size.height - 6 {
                    let ring = Path(roundedRect: CGRect(x: 2, y: y, width: size.width - 4, height: 6), cornerRadius: 3)
                    context.fill(ring, with: .linearGradient(
                        Gradient(colors: [Color(white: 0.55), Color(white: 0.92), Color(white: 0.5)]),
                        startPoint: CGPoint(x: 0, y: y), endPoint: CGPoint(x: 0, y: y + 6)))
                    y += 16
                }
            }
            // The fold's shadow, darkest at the spine.
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(colors: [.black.opacity(0.0), .black.opacity(0.35), .black.opacity(0.0)]),
                startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)))
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Ribbon bookmark

struct DiaryRibbon: View {
    var body: some View {
        Canvas { context, size in
            var ribbon = Path()
            ribbon.move(to: .zero)
            ribbon.addLine(to: CGPoint(x: size.width, y: 0))
            ribbon.addLine(to: CGPoint(x: size.width, y: size.height))
            ribbon.addLine(to: CGPoint(x: size.width / 2, y: size.height - size.width * 0.6))
            ribbon.addLine(to: CGPoint(x: 0, y: size.height))
            ribbon.closeSubpath()
            context.fill(ribbon, with: .linearGradient(
                Gradient(colors: [Color(red: 0.55, green: 0.05, blue: 0.10), Color(red: 0.80, green: 0.15, blue: 0.20),
                                  Color(red: 0.55, green: 0.05, blue: 0.10)]),
                startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)))
        }
        .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 1)
    }
}

// MARK: - Settings › Your Diary

/// REM: B-182.2 "You personalize the cover". Shown in Settings only on a device with a hinge (the Duo), since the book
/// only opens there; the preview shows your picks as you make them.
struct DiarySection: View {
    @AppStorage(DiaryKeys.cover) private var cover: DiaryCover = .blackMarble
    @AppStorage(DiaryKeys.binding) private var binding: DiaryBinding = .clothTape
    @AppStorage(DiaryKeys.ribbon) private var ribbon = true
    @AppStorage(DiaryKeys.pages) private var pages: DiaryPages = .wideRuled
    @AppStorage(DiaryKeys.paper) private var paper: DiaryPaper = .white

    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .headline) private var headingSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var previewHeight: CGFloat = 150

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text("Your Diary").font(.system(size: headingSize, weight: .semibold))
                } icon: {
                    Image(systemName: "book.closed.fill").foregroundStyle(.tint)
                }
                Text("Open your iPhone Duo like a book and your entry lies across two pages, with the hinge as the spine. Pick the cover, spine and pages it shows.")
                    .font(.system(size: bodySize))
                preview
            }
            .padding(.vertical, 6)

            Picker(selection: $cover) {
                ForEach(DiaryCover.allCases) { Text($0.name).tag($0) }
            } label: { Text("Cover").font(.system(size: bodySize)) }
                .accessibilityLabel("Cover")
            Picker(selection: $binding) {
                ForEach(DiaryBinding.allCases) { Text($0.name).tag($0) }
            } label: { Text("Spine").font(.system(size: bodySize)) }
                .accessibilityLabel("Spine")
            Toggle(isOn: $ribbon) { Text("Ribbon").font(.system(size: bodySize)) }
                .accessibilityLabel("Ribbon")
            Picker(selection: $pages) {
                ForEach(DiaryPages.allCases) { Text($0.name).tag($0) }
            } label: { Text("Pages").font(.system(size: bodySize)) }
                .accessibilityLabel("Pages")
            Picker(selection: $paper) {
                ForEach(DiaryPaper.allCases) { Text($0.name).tag($0) }
            } label: { Text("Paper").font(.system(size: bodySize)) }
                .accessibilityLabel("Paper")
        }
    }

    /// A small open book with your picks.
    private var preview: some View {
        HStack(spacing: 0) {
            DiaryPaperView(pages: pages, paper: paper)
            DiarySpineView(binding: binding, cover: cover).frame(width: 18)
            DiaryPaperView(pages: pages, paper: paper)
        }
        .padding(8)
        .background { DiaryCoverView(cover: cover) }
        .overlay(alignment: .top) {
            if ribbon {
                DiaryRibbon().frame(width: 9, height: previewHeight * 0.45).offset(x: 22, y: 8)
            }
        }
        .frame(height: previewHeight)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement()
        .accessibilityLabel("Diary preview")
        .accessibilityValue("\(cover.name) cover, \(binding.name) spine, \(paper.name) \(pages.name) pages")
    }
}
