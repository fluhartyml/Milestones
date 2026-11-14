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
//  gold-stamped year or name and the other closures (they show on a closed book, and the Duo's closed screen is the phone),
//  one-day-per-page and handwriting fonts, and the Extras (tabs, flags, pen loop, back pocket).
//  REM: B-182.2's last piece, his "code it" 2026-11-14: the teen diary's locking strap and key. The one place the diary
//  shows CLOSED is the journal lock screen (JournalLock.swift), so that is where the strap goes: with Locking Strap on,
//  the lock screen is your closed cover with the strap and brass clasp across it, and the key (biometric authorization,
//  his word 11-14) opens it. Off by default — it's one of the mix-and-match pieces.
//

import SwiftUI

enum DiaryKeys {
    static let cover = "diaryCover"
    static let binding = "diaryBinding"
    static let ribbon = "diaryRibbon"
    static let pages = "diaryPages"
    static let paper = "diaryPaper"
    static let strap = "diaryStrap"
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

// MARK: - Locking strap and clasp

/// The teen diary's strap: a leather band across the closed cover's front edge, held by a brass clasp with a keyhole.
struct DiaryStrap: View {
    var body: some View {
        Canvas { context, size in
            let h = size.height
            let band = CGRect(x: size.width * 0.45, y: 0, width: size.width * 0.55, height: h)
            context.fill(Path(band), with: .linearGradient(
                Gradient(colors: [Color(red: 0.42, green: 0.24, blue: 0.13), Color(red: 0.30, green: 0.16, blue: 0.08)]),
                startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: h)))
            var stitches = Path()
            for y in [h * 0.14, h * 0.86] {
                stitches.move(to: CGPoint(x: band.minX, y: y)); stitches.addLine(to: CGPoint(x: band.maxX, y: y))
            }
            context.stroke(stitches, with: .color(Color(red: 0.93, green: 0.84, blue: 0.66).opacity(0.8)),
                           style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
            // Brass clasp at the strap's end, with a keyhole.
            let claspW = min(size.width * 0.32, h * 1.5)
            let clasp = CGRect(x: band.minX - claspW * 0.55, y: -h * 0.12, width: claspW, height: h * 1.24)
            let brass = Gradient(colors: [Color(red: 0.95, green: 0.82, blue: 0.45), Color(red: 0.72, green: 0.55, blue: 0.20),
                                          Color(red: 0.55, green: 0.40, blue: 0.12)])
            context.fill(Path(roundedRect: clasp, cornerRadius: h * 0.22), with: .linearGradient(
                brass, startPoint: CGPoint(x: clasp.minX, y: clasp.minY), endPoint: CGPoint(x: clasp.maxX, y: clasp.maxY)))
            context.stroke(Path(roundedRect: clasp.insetBy(dx: 1.5, dy: 1.5), cornerRadius: h * 0.2),
                           with: .color(.black.opacity(0.25)), lineWidth: 1)
            let r = h * 0.15
            let c = CGPoint(x: clasp.midX, y: clasp.midY - r * 0.5)
            var hole = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            hole.move(to: CGPoint(x: c.x - r * 0.45, y: c.y))
            hole.addLine(to: CGPoint(x: c.x - r * 0.75, y: c.y + r * 2.6))
            hole.addLine(to: CGPoint(x: c.x + r * 0.75, y: c.y + r * 2.6))
            hole.addLine(to: CGPoint(x: c.x + r * 0.45, y: c.y))
            hole.closeSubpath()
            context.fill(hole, with: .color(Color(red: 0.12, green: 0.08, blue: 0.04)))
        }
        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 2)
        .accessibilityHidden(true)
    }
}

/// The diary shut: your cover, the spine edge, and (with Locking Strap on) the strap and clasp.
struct ClosedDiaryView: View {
    let cover: DiaryCover
    let binding: DiaryBinding
    let strap: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                DiaryCoverView(cover: cover)
                DiarySpineView(binding: binding, cover: cover).frame(width: max(10, geo.size.width * 0.07))
                if strap {
                    DiaryStrap()
                        .frame(width: geo.size.width * 0.55, height: max(14, geo.size.height * 0.11))
                        .position(x: geo.size.width * 0.725, y: geo.size.height * 0.5)
                }
            }
        }
        .aspectRatio(0.72, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
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
    @AppStorage(DiaryKeys.strap) private var strap = false
    @AppStorage(JournalLockKeys.on) private var lockOn = false

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
            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: $strap) { Text("Locking Strap").font(.system(size: bodySize)) }
                    .accessibilityLabel("Locking Strap")
                    .accessibilityIdentifier("diaryStrapToggle")
                Text(strap && !lockOn
                     ? "The strap shows on your closed diary when it's locked. Turn on Journal Lock above to lock it with Biometric Authorization."
                     : "The strap shows on your closed diary when it's locked; Biometric Authorization is the key.")
                    .font(.system(size: bodySize))
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Your diary closed (with the strap when it's on) beside a small open book with your picks.
    private var preview: some View {
        HStack(spacing: 12) {
            ClosedDiaryView(cover: cover, binding: binding, strap: strap)
                .frame(height: previewHeight)
                .accessibilityHidden(true)
            openPreview
        }
    }

    private var openPreview: some View {
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
        .accessibilityValue("\(cover.name) cover, \(binding.name) spine, \(paper.name) \(pages.name) pages\(strap ? ", locking strap" : "")")
    }
}
