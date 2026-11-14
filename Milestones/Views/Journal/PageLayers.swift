//
//  PageLayers.swift
//  Milestones
//
//  REM: his design 2026-11-14 10:0x, mapped in chat, then "yes always ready code it": "the user can choose a background
//  image of their choice for one page or all pages and its on the bottom most layer and the top most layer is apple
//  pencil only where it can write draw or scribble over any milimeyer or inch of the screen." — "iphone duo will have
//  apple [pencil] so does ipad mini" — "the ios device usually works that way and has palm rejection when using the
//  apple pencil if you are using your fingers to markdown maybe a button to tap first maybe at the center bottom of the
//  screen or apples human interface language".
//  Layers, bottom to top: (1) the page background picture — this page's, or else the all-pages one; (2) everything on
//  the page today; (3) the Pencil layer over the whole screen.
//  REM: Claude's calls: the Pencil layer is screen ink — it stays where you wrote it on the screen while the page
//  scrolls under it. Fingers never draw unless you tap the finger button (bottom center, above the senses bar, the way
//  Notes puts its tools at the bottom); tap it again to stop. Fingers that aren't drawing reach the page as always.
//  Undo takes back the last stroke. iPhone and iPad only (the Mac and Vision Pro have no Pencil); the background
//  picture works everywhere.
//

import PencilKit
import PhotosUI
import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Page background (bottom layer)

enum AllPagesBackground {
    static let versionKey = "diaryBackgroundVersion"

    static var url: URL? {
        try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("AllPagesBackground.jpg")
    }

    static func load() -> Data? { url.flatMap { try? Data(contentsOf: $0) } }

    static func save(_ data: Data?) {
        guard let url else { return }
        if let data { try? data.write(to: url, options: .atomic) } else { try? FileManager.default.removeItem(at: url) }
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: versionKey) + 1, forKey: versionKey)
    }
}

extension EnvironmentValues {
    /// This page's own background picture; nil falls back to the all-pages picture.
    @Entry var pageBackgroundData: Data? = nil
}

/// The bottom layer: this page's picture, or the all-pages one, filling the page. Nothing when neither is set.
struct PageBackgroundView: View {
    let pageData: Data?
    @AppStorage(AllPagesBackground.versionKey) private var version = 0
    @State private var image: Image?

    var body: some View {
        Group {
            if let image {
                image.resizable().scaledToFill()
            } else {
                Color.clear
            }
        }
        .clipped()
        .accessibilityHidden(true)
        .task(id: "\(pageData?.count ?? -1)-\(version)") {
            image = TapedPicture.image(from: pageData ?? AllPagesBackground.load())
        }
    }

    /// Whether any background picture applies to a page with this data.
    static func hasAny(_ pageData: Data?) -> Bool {
        pageData != nil || AllPagesBackground.url.map { FileManager.default.fileExists(atPath: $0.path) } == true
    }
}

/// Choose or remove the background, for this page or for all pages.
struct PageBackgroundControls: View {
    @Bindable var entry: MilestoneEntry
    @AppStorage(AllPagesBackground.versionKey) private var version = 0
    @State private var choosing = false
    @State private var forAll = false
    @State private var item: PhotosPickerItem?
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18

    var body: some View {
        Menu {
            Button { forAll = false; choosing = true } label: { Label("Picture for This Page", systemImage: "doc.richtext") }
            Button { forAll = true; choosing = true } label: { Label("Picture for All Pages", systemImage: "books.vertical") }
            if entry.pageBackground != nil {
                Button(role: .destructive) { entry.pageBackground = nil } label: {
                    Label("Remove This Page's Picture", systemImage: "trash")
                }
            }
            if version >= 0, PageBackgroundView.hasAny(nil) {
                Button(role: .destructive) { AllPagesBackground.save(nil) } label: {
                    Label("Remove All Pages' Picture", systemImage: "trash")
                }
            }
        } label: {
            Label("Page Background", systemImage: "photo.on.rectangle")
                .font(.system(size: bodySize, weight: .semibold))
        }
        .accessibilityHint("Puts a picture of your choice behind this page, or behind every page.")
        .accessibilityIdentifier("pageBackground")
        .photosPicker(isPresented: $choosing, selection: $item, matching: .images)
        .onChange(of: item) { _, picked in
            guard let picked else { return }
            Task {
                if let data = try? await picked.loadTransferable(type: Data.self), let (jpeg, _) = TapedPicture.prepare(data) {
                    if forAll { AllPagesBackground.save(jpeg) } else { entry.pageBackground = jpeg }
                }
                item = nil
            }
        }
    }
}

// MARK: - Pencil layer (top layer, iPhone and iPad)

#if os(iOS)
/// The finger button and Undo, bottom center.
struct PencilBar: View {
    @Binding var fingerDraws: Bool
    let canUndo: Bool
    let undo: () -> Void
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18

    var body: some View {
        HStack(spacing: 12) {
            Button { fingerDraws.toggle() } label: {
                Image(systemName: fingerDraws ? "hand.draw.fill" : "hand.draw")
                    .font(.system(size: bodySize + 2, weight: .semibold))
                    .frame(width: 48, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(fingerDraws ? .accentColor : .secondary)
            .accessibilityLabel(fingerDraws ? "Stop Drawing with Finger" : "Draw with Finger")
            .accessibilityHint("Apple Pencil always writes. This lets your finger draw too.")
            .accessibilityIdentifier("fingerDraw")
            if canUndo {
                Button(action: undo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: bodySize, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Undo Ink")
                .accessibilityHint("Takes back the last stroke you wrote over the page.")
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
    }
}

/// Shows the ink over the whole screen and takes strokes from Apple Pencil (and from a finger while the finger button
/// is on). Every other touch passes through to the page.
struct PencilLayer: UIViewRepresentable {
    @Binding var data: Data?
    let fingerDraws: Bool
    /// Bumped by Undo.
    let undoTick: Int

    func makeUIView(context: Context) -> PencilOverlayView {
        let view = PencilOverlayView()
        view.onChange = { data = $0 }
        view.load(data)
        return view
    }

    func updateUIView(_ view: PencilOverlayView, context: Context) {
        view.onChange = { data = $0 }
        view.fingerDraws = fingerDraws
        if view.lastUndoTick != undoTick {
            view.lastUndoTick = undoTick
            view.undo()
        }
    }

    static func dismantleUIView(_ view: PencilOverlayView, coordinator: ()) { view.uninstall() }
}

final class PencilOverlayView: UIView, UIGestureRecognizerDelegate {
    var onChange: ((Data?) -> Void)?
    var fingerDraws = false { didSet { recognizer.allowedTouchTypes = Self.types(fingerDraws) } }
    var lastUndoTick = 0

    private let canvas = PKCanvasView()
    private lazy var recognizer = StrokeRecognizer(target: self, action: #selector(stroke(_:)))
    private var strokes: [PKStroke] = []
    private var points: [PKStrokePoint] = []
    private var started = Date()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.isUserInteractionEnabled = false
        canvas.overrideUserInterfaceStyle = .light
        canvas.translatesAutoresizingMaskIntoConstraints = false
        addSubview(canvas)
        NSLayoutConstraint.activate([
            canvas.leadingAnchor.constraint(equalTo: leadingAnchor), canvas.trailingAnchor.constraint(equalTo: trailingAnchor),
            canvas.topAnchor.constraint(equalTo: topAnchor), canvas.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        recognizer.allowedTouchTypes = Self.types(false)
        recognizer.delegate = self
        recognizer.cancelsTouchesInView = true
        recognizer.delaysTouchesBegan = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    private static func types(_ finger: Bool) -> [NSNumber] {
        finger ? [UITouch.TouchType.pencil.rawValue as NSNumber, UITouch.TouchType.direct.rawValue as NSNumber]
               : [UITouch.TouchType.pencil.rawValue as NSNumber]
    }

    /// The ink never takes a touch itself; the stroke recognizer lives on the window.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        recognizer.view?.removeGestureRecognizer(recognizer)
        window?.addGestureRecognizer(recognizer)
    }

    func uninstall() { recognizer.view?.removeGestureRecognizer(recognizer) }

    func load(_ data: Data?) {
        strokes = data.flatMap { try? PKDrawing(data: $0) }?.strokes ?? []
        canvas.drawing = PKDrawing(strokes: strokes)
    }

    func undo() {
        guard !strokes.isEmpty else { return }
        strokes.removeLast()
        canvas.drawing = PKDrawing(strokes: strokes)
        save()
    }

    /// The page this layer belongs to: the nearest view controller's view. A sheet over it isn't inside it, so the
    /// Pencil writes in the sheet, not on the page behind.
    private var pageRoot: UIView? {
        var responder: UIResponder? = self
        while let r = responder {
            if let vc = r as? UIViewController { return vc.view }
            responder = r.next
        }
        return superview
    }

    func gestureRecognizer(_ g: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let root = pageRoot, let touched = touch.view else { return false }
        return touched.isDescendant(of: root) && bounds.contains(touch.location(in: self))
    }

    @objc private func stroke(_ g: StrokeRecognizer) {
        switch g.state {
        case .began:
            started = Date()
            points = []
            add(g.newTouches)
        case .changed:
            add(g.newTouches)
        case .ended:
            add(g.newTouches)
            if !points.isEmpty { strokes.append(makeStroke()) }
            points = []
            canvas.drawing = PKDrawing(strokes: strokes)
            save()
        default:
            points = []
            canvas.drawing = PKDrawing(strokes: strokes)
        }
    }

    private func add(_ touches: [UITouch]) {
        for t in touches {
            let pencil = t.type == .pencil
            let force = pencil && t.maximumPossibleForce > 0 ? t.force / t.maximumPossibleForce : 0.5
            let width = 1.5 + 4 * max(0.15, force)
            points.append(PKStrokePoint(location: t.location(in: self), timeOffset: t.timestamp,
                                        size: CGSize(width: width, height: width), opacity: 1, force: max(0.1, force * 2),
                                        azimuth: pencil ? t.azimuthAngle(in: self) : 0, altitude: pencil ? t.altitudeAngle : .pi / 2))
        }
        guard !points.isEmpty else { return }
        canvas.drawing = PKDrawing(strokes: strokes + [makeStroke()])
    }

    private func makeStroke() -> PKStroke {
        // Time offsets measured from the stroke's first point.
        let first = points.first?.timeOffset ?? 0
        let fixed = points.map { p in
            PKStrokePoint(location: p.location, timeOffset: max(0, p.timeOffset - first),
                          size: p.size, opacity: p.opacity, force: p.force, azimuth: p.azimuth, altitude: p.altitude)
        }
        return PKStroke(ink: PKInk(.pen, color: .black), path: PKStrokePath(controlPoints: fixed, creationDate: started))
    }

    private func save() {
        onChange?(strokes.isEmpty ? nil : PKDrawing(strokes: strokes).dataRepresentation())
    }

    // The stroke wins over the page's scrolling and taps once it starts.
    func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { false }
}

/// One finger or Pencil, from touch-down to lift-off. Hands its touches over as they arrive (coalesced, so fast
/// writing stays smooth).
final class StrokeRecognizer: UIGestureRecognizer {
    private(set) var newTouches: [UITouch] = []
    private var tracking: UITouch?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard tracking == nil, let t = touches.first else {
            for t in touches where t !== tracking { ignore(t, for: event) }
            return
        }
        tracking = t
        newTouches = event.coalescedTouches(for: t) ?? [t]
        state = .began
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let t = tracking, touches.contains(t) else { return }
        newTouches = event.coalescedTouches(for: t) ?? [t]
        state = .changed
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let t = tracking, touches.contains(t) else { return }
        newTouches = [t]
        state = .ended
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let t = tracking, touches.contains(t) else { return }
        newTouches = []
        state = .cancelled
    }

    override func reset() {
        tracking = nil
        newTouches = []
    }

    override func canBePrevented(by other: UIGestureRecognizer) -> Bool { false }
    override func canPrevent(_ other: UIGestureRecognizer) -> Bool { true }
}
#endif
