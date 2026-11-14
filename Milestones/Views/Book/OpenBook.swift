//
//  OpenBook.swift
//  Milestones
//
//  REM: amber B-182 (locked 2026-11-09), his idea 2026-11-07: "opened or in stand mode, Milestones still lays out as
//  if the Duo were closed ... A simpler step could come first: two frames side by side when it is open or in stand
//  mode." B-182.1, his revise: "panes could also be pages" — "The book's spine is the Duo's hinge: one page on each
//  side of the fold, the way an open journal lies."
//  REM: what the iOS 27.1 SDK on this Mac offers for the hinge (read from the headers, 2026-11-09):
//    UIKit  — UIHinge (status: unknown / closed / partiallyOpen / fullyOpen, angle in radians) and UIHingeInteraction,
//             "invoked with the initial hinge state, and again whenever there is an update"; update.hinge is nil where
//             the hierarchy gives no hinge updates (every device without a hinge). iOS / visionOS 27.1.
//    SwiftUI — DeviceHinge, DeviceHingeContext, View.onHingeChange(isEnabled:_:) (anyAppleOS 27.1).
//    Neither says WHERE the hinge is on the screen. The UIKit one is used because its first call is documented.
//  REM: the spine's place is NOT in the SDK. Conservative choice: the Duo's fold runs down the middle of the inner
//  screen, so the spine sits at the screen's center, and the book opens only when (1) the hinge is partly or fully
//  open ("opened or in stand mode"), (2) the screen is wider than tall (the fold runs top to bottom, like a book), and
//  (3) the screen's center falls inside this view with room for a page on each side. Held with the fold running side
//  to side, or with Milestones in a narrow window that doesn't cross the fold, you get the one-page layout. The Mac and
//  Vision Pro have no hinge (and their SDKs here, 27.0, have no hinge API), so they always get one page.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

/// What the hinge probe reports.
struct HingeState: Equatable {
    /// This device has a hinge (an iPhone Duo).
    var hasHinge = false
    /// Where the spine falls in this view, from its leading edge, when the book is open; nil for one page.
    var spineX: CGFloat?
}

/// Two pages with the spine on the Duo's hinge when it's open or standing; one page (today's layout) otherwise.
struct OpenBook<Single: View, Left: View, Right: View>: View {
    private let single: Single
    private let left: Left
    private let right: Right

    @State private var hinge = HingeState()
    @AppStorage(DiaryKeys.cover) private var cover: DiaryCover = .blackMarble
    @AppStorage(DiaryKeys.binding) private var binding: DiaryBinding = .clothTape
    @AppStorage(DiaryKeys.ribbon) private var ribbon = true
    @AppStorage(DiaryKeys.pages) private var pages: DiaryPages = .wideRuled
    @AppStorage(DiaryKeys.paper) private var paper: DiaryPaper = .white
    // REM: B-182.3, his "code it" 2026-11-14 — handwriting, date per page and the extras (DiaryStyle.swift).
    @AppStorage(DiaryKeys.hand) private var hand: DiaryHand = .print
    @AppStorage(DiaryKeys.tabs) private var tabs = false
    @AppStorage(DiaryKeys.flags) private var flags = false
    @AppStorage(DiaryKeys.penLoop) private var penLoop = false
    @AppStorage(DiaryKeys.pocket) private var pocket = false
    @Environment(\.diaryPageDate) private var pageDate
    // REM: his design 2026-11-14 — the page background picture is the bottom layer (PageLayers.swift).
    @Environment(\.pageBackgroundData) private var backgroundData
    @AppStorage(AllPagesBackground.versionKey) private var backgroundVersion = 0
    private var hasBackground: Bool { backgroundVersion >= 0 && PageBackgroundView.hasAny(backgroundData) }
    @ScaledMetric(relativeTo: .body) private var handSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var dateHead: CGFloat = 34

    /// - Parameters:
    ///   - single: the closed (one-page) layout's rows, in today's order.
    ///   - left: the left page's rows when the book is open.
    ///   - right: the right page's rows.
    init(@ViewBuilder single: () -> Single, @ViewBuilder left: () -> Left, @ViewBuilder right: () -> Right) {
        self.single = single()
        self.left = left()
        self.right = right()
    }

    /// Cover showing around the pages, and the gutter the spine sits in.
    private let coverEdge: CGFloat = 12
    private let gutter: CGFloat = 32

    var body: some View {
        Group {
            if let spine = hinge.spineX {
                spread(spine: spine)
            } else {
                Form { single }
                    .scrollContentBackground(hasBackground ? .hidden : .automatic)
                    .background { if hasBackground { PageBackgroundView(pageData: backgroundData).ignoresSafeArea() } }
            }
        }
        #if os(iOS)
        .background(HingeReader(minimumPage: 280) { hinge = $0 })
        #endif
    }

    private func spread(spine: CGFloat) -> some View {
        GeometryReader { geo in
            let leftWidth = max(0, spine - coverEdge - gutter / 2)
            HStack(spacing: 0) {
                page { left }
                    .frame(width: leftWidth)
                DiarySpineView(binding: binding, cover: cover)
                    .frame(width: gutter)
                page { right }
                    .frame(maxWidth: .infinity)
            }
            .padding(coverEdge)
            .frame(width: geo.size.width, height: geo.size.height)
            .background { DiaryCoverView(cover: cover).accessibilityHidden(true) }
            .overlay(alignment: .topLeading) {
                // B-182.3 "a ribbon bookmark" — lies on the right page beside the spine; it never takes a touch.
                if ribbon {
                    DiaryRibbon()
                        .frame(width: 14, height: geo.size.height * 0.4)
                        .offset(x: spine + gutter / 2 + 18, y: coverEdge)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .overlay {
                DiaryExtras(spine: spine, edge: coverEdge, gutter: gutter,
                            month: Calendar.current.component(.month, from: pageDate ?? .now),
                            tabs: tabs, flags: flags, penLoop: penLoop, pocket: pocket)
            }
        }
    }

    /// One page: the rows on paper. Paper is light in dark mode too, as a real page is, so the page's text stays dark.
    private func page<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        Form {
            Group { content() }
                .listRowBackground(Color.clear)
        }
        .font(hand.font(size: handSize))
        .contentMargins(.top, pages == .dayPerPage ? dateHead * 2.2 : 0, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background {
            if hasBackground {
                PageBackgroundView(pageData: backgroundData)
            } else {
                DiaryPaperView(pages: pages, paper: paper, date: pageDate ?? .now).accessibilityHidden(true)
            }
        }
        .environment(\.colorScheme, .light)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
    }
}

extension OpenBook where Single == TupleView<(Left, Right)> {
    /// The one-page layout is the left page's rows followed by the right page's.
    init(@ViewBuilder left: () -> Left, @ViewBuilder right: () -> Right) {
        let l = left()
        let r = right()
        self.init(single: { l; r }, left: { l }, right: { r })
    }
}

extension EnvironmentValues {
    /// The day an open diary page belongs to; One Day per Page prints it at the top.
    @Entry var diaryPageDate: Date? = nil
}

// MARK: - Hinge probe (iPhone Duo)

#if os(iOS)
/// Reports whether the device has a hinge and, when the book is open, where the spine falls in the view it backs.
struct HingeReader: UIViewRepresentable {
    /// The narrowest a page may be; below it the book stays closed (one page).
    let minimumPage: CGFloat
    let onChange: (HingeState) -> Void

    func makeUIView(context: Context) -> HingeProbeView {
        let view = HingeProbeView()
        view.minimumPage = minimumPage
        view.onChange = onChange
        return view
    }

    func updateUIView(_ view: HingeProbeView, context: Context) {
        view.minimumPage = minimumPage
        view.onChange = onChange
    }
}

final class HingeProbeView: UIView {
    var minimumPage: CGFloat = 280
    var onChange: ((HingeState) -> Void)?

    private var hasHinge = false
    private var isOpen = false
    private var last: HingeState?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        if #available(iOS 27.1, *) {
            let interaction = UIHingeInteraction { [weak self] _, update in
                guard let self else { return }
                if let hinge = update.hinge {
                    self.hasHinge = true
                    self.isOpen = hinge.status == .partiallyOpen || hinge.status == .fullyOpen
                } else {
                    self.hasHinge = false
                    self.isOpen = false
                }
                self.report()
            }
            addInteraction(interaction)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        report()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        report()
    }

    private func report() {
        var state = HingeState(hasHinge: hasHinge, spineX: nil)
        if isOpen, let screen = window?.windowScene?.screen {
            let screenBounds = screen.bounds
            if screenBounds.width > screenBounds.height {
                let center = convert(CGPoint(x: screenBounds.midX, y: screenBounds.midY), from: screen.coordinateSpace)
                if center.x >= minimumPage, bounds.width - center.x >= minimumPage {
                    state.spineX = center.x.rounded()
                }
            }
        }
        guard state != last else { return }
        last = state
        // Next turn of the main loop, so SwiftUI's state isn't changed in the middle of a layout pass.
        DispatchQueue.main.async { [onChange] in onChange?(state) }
    }
}
#endif
