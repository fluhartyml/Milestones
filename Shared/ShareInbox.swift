//
//  ShareInbox.swift
//  Milestones (app and Share extension)
//
//  REM: amber B-031.3 / B-031.5 (locked 2026-11-09, "yes lock all three"). His words 2026-11-06: "at a minimum they
//  can share the transcriptions or summaries from the Siri app so a share to our app is important linchpin" ·
//  "milestones would definitely need a share entrypoint" · "you can also share photos to milestones where it should
//  receive them, and if a group of photos, even if just one photo, you get to add an entry or description of the photo
//  stack."
//
//  HOW A SHARE BECOMES AN ENTRY. The Share extension can't open the journal's SwiftData store — that store lives in
//  the app's own container, and moving it into the App Group would mean migrating every journal already written. So
//  the extension drops what you shared (your words, the photos) into an inbox folder in the App Group, and the app,
//  each time it comes to the front, turns every item in that inbox into a new entry and opens the newest one to edit
//  (ShareInbox+Import.swift). An item leaves the inbox only after its entry is saved, so nothing shared is lost.
//
//  An item is written to "<id>.partial" and renamed to "<id>" only once every file is down, so the app never reads
//  half an item.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#else
import UIKit
#endif

nonisolated enum ShareInbox {

    /// The App Group the app and its Share extension both belong to.
    static let appGroup = "group.com.inkwell.Milestones"

    /// What one share holds: your words and the names of its photo files (the photo stack, in order).
    struct Item: Codable {
        var text: String
        var sharedAt: Date
        var photoFiles: [String]
    }

    /// An item waiting in the inbox, with the folder it sits in.
    struct Pending {
        let folder: URL
        let item: Item
    }

    private static let itemFile = "item.json"
    private static let partial = "partial"

    /// The inbox folder in the App Group. Nil when the App Group isn't available (a build signed without it).
    static var folder: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent("ShareInbox", isDirectory: true)
    }

    enum SaveError: Error { case noAppGroup }

    // MARK: - Extension side

    /// Puts one share in the inbox: the words and the photo stack (JPEG data, in order).
    static func save(text: String, photos: [Data], sharedAt: Date = Date()) throws {
        guard let inbox = folder else { throw SaveError.noAppGroup }
        let fm = FileManager.default
        try fm.createDirectory(at: inbox, withIntermediateDirectories: true)
        let id = UUID().uuidString
        let working = inbox.appendingPathComponent(id).appendingPathExtension(partial)
        try fm.createDirectory(at: working, withIntermediateDirectories: true)
        do {
            var names: [String] = []
            for (index, photo) in photos.enumerated() {
                let name = "photo-\(index).jpg"
                try photo.write(to: working.appendingPathComponent(name), options: .atomic)
                names.append(name)
            }
            let item = Item(text: text, sharedAt: sharedAt, photoFiles: names)
            try JSONEncoder().encode(item).write(to: working.appendingPathComponent(itemFile), options: .atomic)
            try fm.moveItem(at: working, to: inbox.appendingPathComponent(id, isDirectory: true))
        } catch {
            try? fm.removeItem(at: working)
            throw error
        }
    }

    // MARK: - App side

    /// Every finished item in the inbox, oldest share first.
    static func pending() -> [Pending] {
        guard let inbox = folder,
              let folders = try? FileManager.default.contentsOfDirectory(at: inbox, includingPropertiesForKeys: nil)
        else { return [] }
        return folders
            .filter { $0.pathExtension != partial }
            .compactMap { folder in
                guard let data = try? Data(contentsOf: folder.appendingPathComponent(itemFile)),
                      let item = try? JSONDecoder().decode(Item.self, from: data) else { return nil }
                return Pending(folder: folder, item: item)
            }
            .sorted { $0.item.sharedAt < $1.item.sharedAt }
    }

    /// The photo stack of a waiting item, in the order it was shared.
    static func photos(of pending: Pending) -> [Data] {
        pending.item.photoFiles.compactMap { try? Data(contentsOf: pending.folder.appendingPathComponent($0)) }
    }

    /// Takes an item out of the inbox once its entry is saved.
    static func remove(_ pending: Pending) {
        try? FileManager.default.removeItem(at: pending.folder)
    }

    // MARK: - Reading what was shared (extension side)

    /// The text in one shared attachment, plain or styled. Nil when it holds no text.
    static func loadText(from provider: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            if provider.canLoadObject(ofClass: NSString.self) {
                _ = provider.loadObject(ofClass: NSString.self) { object, _ in
                    continuation.resume(returning: (object as? NSString).map { String($0) })
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.rtf.identifier) {
                _ = provider.loadDataRepresentation(forTypeIdentifier: UTType.rtf.identifier) { data, _ in
                    let styled = data.flatMap {
                        try? NSAttributedString(data: $0, options: [.documentType: NSAttributedString.DocumentType.rtf],
                                                documentAttributes: nil)
                    }
                    continuation.resume(returning: styled?.string)
                }
            } else {
                continuation.resume(returning: nil)
            }
        }
    }

    /// One shared photo, downsized and saved as JPEG the way the app stores photos. Nil when it can't be read.
    static func loadPhoto(from provider: NSItemProvider) async -> Data? {
        let type = UTType.image.identifier
        // A file first: ImageIO reads only what it needs from it, which keeps a big photo within the extension's memory.
        let fromFile: Data? = await withCheckedContinuation { continuation in
            _ = provider.loadFileRepresentation(forTypeIdentifier: type) { url, _ in
                continuation.resume(returning: url.flatMap { entryPhoto(CGImageSourceCreateWithURL($0 as CFURL, nil)) })
            }
        }
        if let fromFile { return fromFile }
        // Some apps hand a photo over only as data.
        return await withCheckedContinuation { continuation in
            _ = provider.loadDataRepresentation(forTypeIdentifier: type) { data, _ in
                continuation.resume(returning: data.flatMap { entryPhoto(CGImageSourceCreateWithData($0 as CFData, nil)) })
            }
        }
    }

    /// A small picture of a stored photo, for the stack shown while you write.
    static func preview(of photo: Data, maxPixels: CGFloat) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(photo as CFData, nil) else { return nil }
        return thumbnail(source, maxPixels: maxPixels)
    }

    private static func entryPhoto(_ source: CGImageSource?) -> Data? {
        guard let source, let image = thumbnail(source, maxPixels: AppConstants.maxPhotoSize) else { return nil }
        let out = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(out, UTType.jpeg.identifier as CFString, 1, nil)
        else { return nil }
        let options = [kCGImageDestinationLossyCompressionQuality: AppConstants.photoCompressionQuality] as CFDictionary
        CGImageDestinationAddImage(destination, image, options)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return out as Data
    }

    private static func thumbnail(_ source: CGImageSource, maxPixels: CGFloat) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
