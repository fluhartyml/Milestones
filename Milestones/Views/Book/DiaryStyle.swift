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
//  REM: B-182.3's rest, his "code it" 2026-11-14 — every piece the line names, all drawn in code, nothing copied:
//    Covers   — Floral (drawn flowers and leaves) and Doodle (stars, hearts, spirals, smiles), plus a Gold Stamp: a year
//               or name you type, stamped in gold on the closed cover.
//    Closures — one picker: None, Brass Clasp (the strap above), Elastic Band, Snap Strap, Heart Lock, Cord and Button.
//               Any closure turns the lock screen into your closed diary; the key is always biometric authorization.
//    Pages    — One Day per Page: the entry's date printed at the top of each page, the way a dated diary is.
//               Handwriting: Apple's built-in hands (Marker Felt, Noteworthy, Chalkboard, Bradley Hand) for the words
//               on the pages; Print is today's type.
//    Extras   — Month Tabs (the entry's month stands out), Sticky Flags, Pen Loop and Back Pocket, drawn on the open
//               book's edges. They are looks only; nothing on them takes a touch.
//

import SwiftUI

enum DiaryKeys {
    static let cover = "diaryCover"
    static let binding = "diaryBinding"
    static let ribbon = "diaryRibbon"
    static let pages = "diaryPages"
    static let paper = "diaryPaper"
    /// The first strap switch (Milestones 35). Read once and moved into `closure` as Brass Clasp.
    static let strap = "diaryStrap"
    static let closure = "diaryClosure"
    static let stamp = "diaryStamp"
    static let hand = "diaryHand"
    static let tabs = "diaryMonthTabs"
    static let flags = "diaryFlags"
    static let penLoop = "diaryPenLoop"
    static let pocket = "diaryPocket"
}

/// What holds the diary shut.
enum DiaryClosure: String, CaseIterable, Identifiable {
    case none, brassClasp, elastic, snapStrap, heartLock, cord
    var id: String { rawValue }
    var name: String {
        switch self {
        case .none: "None"
        case .brassClasp: "Brass Clasp Strap"
        case .elastic: "Elastic Band"
        case .snapStrap: "Snap Strap"
        case .heartLock: "Heart Lock and Key"
        case .cord: "Cord and Button"
        }
    }

    /// The closure in effect, counting the first strap switch from Milestones 35.
    static func current(_ stored: DiaryClosure, legacyStrap: Bool) -> DiaryClosure {
        stored == .none && legacyStrap ? .brassClasp : stored
    }
}

/// The hand the words on the pages are written in.
enum DiaryHand: String, CaseIterable, Identifiable {
    case print, marker, noteworthy, chalkboard, bradley
    var id: String { rawValue }
    var name: String {
        switch self {
        case .print: "Print"
        case .marker: "Marker Felt"
        case .noteworthy: "Noteworthy"
        case .chalkboard: "Chalkboard"
        case .bradley: "Bradley Hand"
        }
    }
    /// The font's name on iPhone and Mac; nil for Print (the app's own type).
    var fontName: String? {
        switch self {
        case .print: nil
        case .marker: "MarkerFelt-Thin"
        case .noteworthy: "Noteworthy-Light"
        case .chalkboard: "ChalkboardSE-Regular"
        case .bradley: "BradleyHandITCTT-Bold"
        }
    }
    func font(size: CGFloat) -> Font? {
        fontName.map { Font.custom($0, size: size, relativeTo: .body) }
    }
}

enum DiaryCover: String, CaseIterable, Identifiable {
    case blackMarble, blueMarble, kraft, leather, red, blue, green, purple, floral, doodle

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
        case .floral: "Floral"
        case .doodle: "Doodle"
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
        case .floral: Color(red: 0.93, green: 0.90, blue: 0.82)
        case .doodle: Color(red: 0.97, green: 0.96, blue: 0.92)
        }
    }

    /// The darker band a cloth tape spine shows.
    var tape: Color {
        switch self {
        case .blackMarble, .blueMarble: Color(red: 0.05, green: 0.05, blue: 0.06)
        case .kraft, .doodle: Color(red: 0.20, green: 0.20, blue: 0.22)
        case .floral: Color(red: 0.25, green: 0.38, blue: 0.27)
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
    case blank, wideRuled, collegeRuled, grid, dotted, dayPerPage
    var id: String { rawValue }
    var name: String {
        switch self {
        case .blank: "Blank"
        case .wideRuled: "Wide Ruled"
        case .collegeRuled: "College Ruled"
        case .grid: "Grid"
        case .dotted: "Dotted"
        case .dayPerPage: "One Day per Page"
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
            case .floral:
                // Floral: five-petal flowers and leaves scattered over a cream ground.
                let petals: [Color] = [Color(red: 0.88, green: 0.45, blue: 0.55), Color(red: 0.95, green: 0.70, blue: 0.30),
                                       Color(red: 0.60, green: 0.45, blue: 0.80), Color(red: 0.92, green: 0.55, blue: 0.40)]
                let leaf = Color(red: 0.35, green: 0.55, blue: 0.35)
                let count = min(140, max(6, Int(size.width * size.height / 2200)))
                for _ in 0..<count {
                    let c = CGPoint(x: random.next() * size.width, y: random.next() * size.height)
                    let r = 6 + random.next() * 10
                    let turn = random.next() * .pi
                    for side in [-1.0, 1.0] {
                        let l = Path(ellipseIn: CGRect(x: r * 0.6, y: -r * 0.25, width: r * 1.4, height: r * 0.5))
                            .applying(CGAffineTransform(rotationAngle: turn + side * 0.9 + .pi / 2))
                            .applying(CGAffineTransform(translationX: c.x, y: c.y))
                        context.fill(l, with: .color(leaf.opacity(0.8)))
                    }
                    let color = petals[Int(random.next() * CGFloat(petals.count)) % petals.count]
                    for k in 0..<5 {
                        let petal = Path(ellipseIn: CGRect(x: 0, y: -r * 0.32, width: r, height: r * 0.64))
                            .applying(CGAffineTransform(rotationAngle: turn + CGFloat(k) * .pi * 2 / 5))
                            .applying(CGAffineTransform(translationX: c.x, y: c.y))
                        context.fill(petal, with: .color(color))
                    }
                    context.fill(Path(ellipseIn: CGRect(x: c.x - r * 0.22, y: c.y - r * 0.22, width: r * 0.44, height: r * 0.44)),
                                 with: .color(Color(red: 0.98, green: 0.85, blue: 0.35)))
                }
            case .doodle:
                // Doodle: pen stars, hearts, spirals and smiles, the way a cover fills up in class.
                let inks: [Color] = [Color(red: 0.15, green: 0.30, blue: 0.75), Color(red: 0.85, green: 0.20, blue: 0.35),
                                     Color(red: 0.10, green: 0.55, blue: 0.35), Color(red: 0.55, green: 0.25, blue: 0.70),
                                     Color(red: 0.10, green: 0.10, blue: 0.12)]
                let count = min(120, max(6, Int(size.width * size.height / 1800)))
                for _ in 0..<count {
                    let c = CGPoint(x: random.next() * size.width, y: random.next() * size.height)
                    let r = 5 + random.next() * 9
                    let ink = inks[Int(random.next() * CGFloat(inks.count)) % inks.count]
                    let kind = Int(random.next() * 4) % 4
                    var shape = Path()
                    switch kind {
                    case 0: shape = DiaryShapes.star(center: c, radius: r)
                    case 1: shape = DiaryShapes.heart(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                    case 2:
                        shape.move(to: c)
                        for step in 1...24 {
                            let a = CGFloat(step) * 0.55
                            let d = r * CGFloat(step) / 24
                            shape.addLine(to: CGPoint(x: c.x + cos(a) * d, y: c.y + sin(a) * d))
                        }
                    default:
                        shape.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                        shape.addEllipse(in: CGRect(x: c.x - r * 0.4, y: c.y - r * 0.4, width: r * 0.2, height: r * 0.2))
                        shape.addEllipse(in: CGRect(x: c.x + r * 0.2, y: c.y - r * 0.4, width: r * 0.2, height: r * 0.2))
                        shape.addArc(center: c, radius: r * 0.55, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
                    }
                    context.stroke(shape, with: .color(ink.opacity(0.85)), lineWidth: 1.4)
                }
            default:
                // Solid cloth: a light sheen from the top corner.
                context.fill(Path(rect), with: .linearGradient(
                    Gradient(colors: [.white.opacity(0.14), .clear, .black.opacity(0.18)]),
                    startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
            }
        }
    }
}

/// Shapes the covers and closures share.
enum DiaryShapes {
    static func star(center c: CGPoint, radius r: CGFloat) -> Path {
        var p = Path()
        for k in 0..<10 {
            let a = CGFloat(k) * .pi / 5 - .pi / 2
            let d = k.isMultiple(of: 2) ? r : r * 0.45
            let pt = CGPoint(x: c.x + cos(a) * d, y: c.y + sin(a) * d)
            if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }

    static func heart(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.3),
                   control1: CGPoint(x: rect.midX - w * 0.1, y: rect.maxY - h * 0.15),
                   control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.6))
        p.addArc(center: CGPoint(x: rect.minX + w * 0.25, y: rect.minY + h * 0.3), radius: w * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addArc(center: CGPoint(x: rect.minX + w * 0.75, y: rect.minY + h * 0.3), radius: w * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                   control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.6),
                   control2: CGPoint(x: rect.midX + w * 0.1, y: rect.maxY - h * 0.15))
        p.closeSubpath()
        return p
    }
}

// MARK: - Paper

struct DiaryPaperView: View {
    let pages: DiaryPages
    let paper: DiaryPaper
    /// One Day per Page prints this date at the top of the page.
    var date: Date? = nil

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
            case .dayPerPage:
                // A dated diary page: the date at the top over a double rule, wide-ruled lines below.
                let step = wide
                let head = step * 2.2
                if let date {
                    context.draw(Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                                    .font(.system(size: step * 0.5, weight: .semibold, design: .serif))
                                    .foregroundStyle(Color(red: 0.55, green: 0.15, blue: 0.15)),
                                 at: CGPoint(x: size.width / 2, y: head * 0.5))
                }
                var lines = Path()
                for y in [head, head + 3] {
                    lines.move(to: CGPoint(x: 8, y: y)); lines.addLine(to: CGPoint(x: size.width - 8, y: y))
                }
                context.stroke(lines, with: .color(Color.red.opacity(0.45)), lineWidth: 1)
                var rules = Path()
                var y = head + step
                while y < size.height {
                    rules.move(to: CGPoint(x: 0, y: y)); rules.addLine(to: CGPoint(x: size.width, y: y)); y += step
                }
                context.stroke(rules, with: .color(rule.opacity(0.35)), lineWidth: 1)
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

/// The diary shut: your cover, the spine edge, the gold stamp, and the closure.
struct ClosedDiaryView: View {
    let cover: DiaryCover
    let binding: DiaryBinding
    let closure: DiaryClosure
    var stamp: String = ""

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack(alignment: .leading) {
                DiaryCoverView(cover: cover)
                DiarySpineView(binding: binding, cover: cover).frame(width: max(10, w * 0.07))
                if !stamp.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(stamp.trimmingCharacters(in: .whitespaces))
                        .font(.system(size: max(10, w * 0.11), weight: .bold, design: .serif))
                        .foregroundStyle(LinearGradient(colors: [Color(red: 0.98, green: 0.86, blue: 0.48),
                                                                 Color(red: 0.75, green: 0.57, blue: 0.20),
                                                                 Color(red: 0.95, green: 0.80, blue: 0.40)],
                                                        startPoint: .top, endPoint: .bottom))
                        .shadow(color: .black.opacity(0.45), radius: 0.5, x: 0.5, y: 0.8)
                        .lineLimit(1).minimumScaleFactor(0.4)
                        .frame(width: w * 0.8)
                        .position(x: w * 0.54, y: h * 0.24)
                }
                closureView(w: w, h: h)
            }
        }
        .aspectRatio(0.72, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func closureView(w: CGFloat, h: CGFloat) -> some View {
        let band = max(14, h * 0.11)
        switch closure {
        case .none:
            EmptyView()
        case .brassClasp:
            DiaryStrap().frame(width: w * 0.55, height: band).position(x: w * 0.725, y: h * 0.5)
        case .elastic:
            LinearGradient(colors: [Color(white: 0.05), Color(white: 0.28), Color(white: 0.05)],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: max(6, w * 0.045), height: h)
                .position(x: w * 0.86, y: h / 2)
                .shadow(color: .black.opacity(0.4), radius: 1.5, x: -1)
        case .snapStrap:
            ZStack(alignment: .leading) {
                Rectangle().fill(Color(red: 0.36, green: 0.21, blue: 0.12))
                Circle()
                    .fill(RadialGradient(colors: [Color(white: 0.95), Color(white: 0.55)], center: .topLeading,
                                         startRadius: 1, endRadius: band))
                    .frame(width: band * 0.7, height: band * 0.7)
                    .padding(.leading, band * 0.2)
            }
            .frame(width: w * 0.4, height: band)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: band / 2, bottomLeadingRadius: band / 2))
            .shadow(color: .black.opacity(0.35), radius: 2, y: 2)
            .position(x: w * 0.8, y: h * 0.5)
        case .heartLock:
            ZStack {
                Rectangle().fill(Color(red: 0.55, green: 0.12, blue: 0.25))
                    .frame(width: w * 0.42, height: band * 0.6)
                    .position(x: w * 0.79, y: h * 0.5)
                Canvas { context, size in
                    let rect = CGRect(origin: .zero, size: size)
                    let heart = DiaryShapes.heart(in: rect.insetBy(dx: 1, dy: 1))
                    context.fill(heart, with: .linearGradient(
                        Gradient(colors: [Color(red: 0.98, green: 0.86, blue: 0.48), Color(red: 0.70, green: 0.52, blue: 0.18)]),
                        startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
                    let r = size.width * 0.09
                    let c = CGPoint(x: size.width / 2, y: size.height * 0.42)
                    var hole = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                    hole.addRect(CGRect(x: c.x - r * 0.45, y: c.y, width: r * 0.9, height: r * 2.4))
                    context.fill(hole, with: .color(Color(red: 0.15, green: 0.08, blue: 0.04)))
                }
                .frame(width: band * 1.9, height: band * 1.9)
                .position(x: w * 0.58, y: h * 0.5)
                .shadow(color: .black.opacity(0.35), radius: 2, y: 2)
            }
        case .cord:
            Canvas { context, size in
                let button = CGPoint(x: size.width * 0.78, y: size.height * 0.5)
                let br = max(6, size.width * 0.06)
                var cord = Path()
                cord.move(to: CGPoint(x: size.width, y: size.height * 0.44))
                cord.addCurve(to: CGPoint(x: button.x - br * 0.4, y: button.y - br * 1.1),
                              control1: CGPoint(x: size.width * 0.9, y: size.height * 0.4),
                              control2: CGPoint(x: button.x + br, y: button.y - br * 1.6))
                cord.addCurve(to: CGPoint(x: button.x + br * 0.2, y: button.y + br * 1.2),
                              control1: CGPoint(x: button.x - br * 2.2, y: button.y - br * 0.4),
                              control2: CGPoint(x: button.x - br * 1.6, y: button.y + br * 1.8))
                cord.addCurve(to: CGPoint(x: size.width, y: size.height * 0.56),
                              control1: CGPoint(x: button.x + br * 1.6, y: button.y + br),
                              control2: CGPoint(x: size.width * 0.92, y: size.height * 0.6))
                context.stroke(cord, with: .color(Color(red: 0.55, green: 0.12, blue: 0.10)),
                               style: StrokeStyle(lineWidth: max(2, br * 0.35), lineCap: .round))
                context.fill(Path(ellipseIn: CGRect(x: button.x - br, y: button.y - br, width: br * 2, height: br * 2)),
                             with: .color(Color(red: 0.45, green: 0.30, blue: 0.18)))
                for dx in [-0.3, 0.3] { for dy in [-0.3, 0.3] {
                    context.fill(Path(ellipseIn: CGRect(x: button.x + br * dx - 1.2, y: button.y + br * dy - 1.2, width: 2.4, height: 2.4)),
                                 with: .color(.black.opacity(0.6)))
                } }
            }
            .shadow(color: .black.opacity(0.3), radius: 1.5, y: 1)
        }
    }
}

// MARK: - Extras on the open book

/// Month Tabs, Sticky Flags, Pen Loop and Back Pocket, drawn around the open book's edges. Looks only — no touches.
struct DiaryExtras: View {
    let spine: CGFloat
    let edge: CGFloat
    let gutter: CGFloat
    let month: Int
    let tabs: Bool
    let flags: Bool
    let penLoop: Bool
    let pocket: Bool

    var body: some View {
        Canvas { context, size in
            let rightPageX = spine + gutter / 2
            if tabs {
                // Twelve month tabs down the right edge; the entry's month sticks out further.
                let colors: [Color] = [.red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown]
                let top = edge + 6, slot = (size.height - top * 2) / 12
                for m in 0..<12 {
                    let here = m + 1 == month
                    let rect = CGRect(x: size.width - edge - 2 - (here ? 4 : 0), y: top + CGFloat(m) * slot + 1,
                                      width: edge + (here ? 4 : 0), height: slot - 2)
                    context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(colors[m].opacity(here ? 1 : 0.55)))
                }
            }
            if flags {
                let colors = [Color(red: 1.0, green: 0.88, blue: 0.30), Color(red: 1.0, green: 0.55, blue: 0.70),
                              Color(red: 0.55, green: 0.90, blue: 0.55)]
                let pageWidth = size.width - rightPageX - edge
                for (k, color) in colors.enumerated() {
                    let x = rightPageX + pageWidth * (0.45 + CGFloat(k) * 0.14)
                    context.fill(Path(CGRect(x: x, y: 1, width: 14, height: edge + 8)), with: .color(color.opacity(0.9)))
                }
            }
            if penLoop {
                // An elastic loop on the left edge with a pen through it.
                let loop = CGRect(x: 0, y: size.height * 0.42, width: edge, height: size.height * 0.16)
                context.fill(Path(loop), with: .color(Color(white: 0.1)))
                let pen = CGRect(x: 1.5, y: size.height * 0.25, width: edge - 3, height: size.height * 0.5)
                context.fill(Path(roundedRect: pen, cornerRadius: (edge - 3) / 2), with: .linearGradient(
                    Gradient(colors: [Color(red: 0.10, green: 0.20, blue: 0.55), Color(red: 0.25, green: 0.40, blue: 0.80),
                                      Color(red: 0.10, green: 0.20, blue: 0.55)]),
                    startPoint: CGPoint(x: pen.minX, y: 0), endPoint: CGPoint(x: pen.maxX, y: 0)))
                context.fill(Path(loop.insetBy(dx: 0, dy: loop.height * 0.2)), with: .color(Color(white: 0.1).opacity(0.9)))
            }
            if pocket {
                // The back pocket's kraft lip along the bottom of the right side.
                let rect = CGRect(x: rightPageX + 8, y: size.height - edge - 8, width: size.width - rightPageX - edge * 2 - 8,
                                  height: edge + 8)
                context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(Color(red: 0.76, green: 0.62, blue: 0.43)))
                var stitch = Path()
                stitch.move(to: CGPoint(x: rect.minX + 4, y: rect.minY + 3)); stitch.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.minY + 3))
                context.stroke(stitch, with: .color(.white.opacity(0.7)), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
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
    @AppStorage(DiaryKeys.closure) private var closure: DiaryClosure = .none
    @AppStorage(DiaryKeys.stamp) private var stamp = ""
    @AppStorage(DiaryKeys.hand) private var hand: DiaryHand = .print
    @AppStorage(DiaryKeys.tabs) private var tabs = false
    @AppStorage(DiaryKeys.flags) private var flags = false
    @AppStorage(DiaryKeys.penLoop) private var penLoop = false
    @AppStorage(DiaryKeys.pocket) private var pocket = false
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
            Picker(selection: $hand) {
                ForEach(DiaryHand.allCases) { Text($0.name).font($0.font(size: bodySize) ?? .system(size: bodySize)).tag($0) }
            } label: { Text("Handwriting").font(.system(size: bodySize)) }
                .accessibilityLabel("Handwriting")
            HStack {
                Text("Gold Stamp").font(.system(size: bodySize))
                TextField("Year or name", text: $stamp)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: bodySize))
                    .accessibilityLabel("Gold Stamp")
                    .accessibilityHint("A year or name stamped in gold on the closed cover.")
                    .onChange(of: stamp) { _, new in if new.count > 24 { stamp = String(new.prefix(24)) } }
            }
            VStack(alignment: .leading, spacing: 6) {
                Picker(selection: $closure) {
                    ForEach(DiaryClosure.allCases) { Text($0.name).tag($0) }
                } label: { Text("Closure").font(.system(size: bodySize)) }
                    .accessibilityLabel("Closure")
                    .accessibilityIdentifier("diaryClosurePicker")
                if closure != .none {
                    Text(lockOn
                         ? "Your closed diary shows on the lock screen; Biometric Authorization is the key."
                         : "Your closed diary shows when it's locked. Turn on Journal Lock above to lock it with Biometric Authorization.")
                        .font(.system(size: bodySize))
                        .foregroundStyle(.secondary)
                }
            }
            Toggle(isOn: $tabs) { Text("Month Tabs").font(.system(size: bodySize)) }.accessibilityLabel("Month Tabs")
            Toggle(isOn: $flags) { Text("Sticky Flags").font(.system(size: bodySize)) }.accessibilityLabel("Sticky Flags")
            Toggle(isOn: $penLoop) { Text("Pen Loop").font(.system(size: bodySize)) }.accessibilityLabel("Pen Loop")
            Toggle(isOn: $pocket) { Text("Back Pocket").font(.system(size: bodySize)) }.accessibilityLabel("Back Pocket")
        }
        .onAppear {
            // The first strap switch (Milestones 35) becomes the Brass Clasp closure.
            if strap { if closure == .none { closure = .brassClasp }; strap = false }
        }
    }

    /// Your diary closed (with the strap when it's on) beside a small open book with your picks.
    private var preview: some View {
        HStack(spacing: 12) {
            ClosedDiaryView(cover: cover, binding: binding, closure: DiaryClosure.current(closure, legacyStrap: strap),
                            stamp: stamp)
                .frame(height: previewHeight)
                .accessibilityHidden(true)
            openPreview
        }
    }

    private var openPreview: some View {
        HStack(spacing: 0) {
            DiaryPaperView(pages: pages, paper: paper, date: .now)
            DiarySpineView(binding: binding, cover: cover).frame(width: 18)
            DiaryPaperView(pages: pages, paper: paper, date: .now)
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
        .accessibilityValue("\(cover.name) cover, \(binding.name) spine, \(paper.name) \(pages.name) pages, closure \(DiaryClosure.current(closure, legacyStrap: strap).name)\(stamp.isEmpty ? "" : ", gold stamp \(stamp)")")
    }
}
