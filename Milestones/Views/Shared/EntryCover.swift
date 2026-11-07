//
//  EntryCover.swift
//  Milestones
//
//  REM: 2026-11-07 — the Mac build was failing: fullScreenCover doesn't exist on macOS. Found while
//  checking line 001.12 on the Mac. iPhone, iPad and Vision Pro keep the full-screen cover unchanged;
//  the Mac shows the same entry as a sheet, Apple's equivalent there.
//

import SwiftUI

extension View {
    func entryCover<Content: View>(isPresented: Binding<Bool>,
                                   @ViewBuilder content: @escaping () -> Content) -> some View {
        #if os(macOS)
        sheet(isPresented: isPresented, content: content)
        #else
        fullScreenCover(isPresented: isPresented, content: content)
        #endif
    }
}
