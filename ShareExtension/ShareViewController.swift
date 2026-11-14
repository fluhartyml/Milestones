//
//  ShareViewController.swift
//  MilestonesShare (Share extension)
//
//  REM: amber B-031.3 / B-031.5. His word 2026-11-06: "milestones would definitely need a share entrypoint." This is
//  the entry point: Milestones in the share sheet of any app — iPhone, iPad, Mac and Vision Pro. It holds the
//  compose screen (ShareComposeView) and closes the share sheet when you save or cancel.
//

import SwiftUI
#if os(macOS)
import AppKit
typealias SharePlatformViewController = NSViewController
#else
import UIKit
typealias SharePlatformViewController = UIViewController
#endif

final class ShareViewController: SharePlatformViewController {

    #if os(macOS)
    override func loadView() {
        // No nib: the screen is SwiftUI.
        view = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 560))
        preferredContentSize = NSSize(width: 480, height: 560)
    }
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()
        let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
        let compose = ShareComposeView(items: items) { [weak self] saved in
            self?.finish(saved: saved)
        }
        #if os(macOS)
        let host = NSHostingController(rootView: compose)
        #else
        let host = UIHostingController(rootView: compose)
        #endif
        addChild(host)
        host.view.frame = view.bounds
        #if os(macOS)
        host.view.autoresizingMask = [.width, .height]
        #else
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        #endif
        view.addSubview(host.view)
        #if !os(macOS)
        host.didMove(toParent: self)
        #endif
    }

    private func finish(saved: Bool) {
        if saved {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        } else {
            extensionContext?.cancelRequest(withError: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError))
        }
    }
}
