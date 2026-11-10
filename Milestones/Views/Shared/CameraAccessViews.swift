//
//  CameraAccessViews.swift
//  Milestones
//
//  REM: amber B-183.7.1 / B-183.2: "a camera glyph on Sight (take a picture)" — the camera tile in a sense's sheet.
//  REM: His rule (002.2, 11-06): every permission has an Access button in Settings that shows on / off, and you can
//  REM: always take it back. iPhone and iPad only: the Mac and Vision Pro don't give the camera to an app this way,
//  REM: so there the tile picks a photo instead and asks for nothing (the photo picker needs no permission).
//

import SwiftUI
#if os(iOS)
import AVFoundation
import UIKit

enum CameraAccess {
    enum State { case notAsked, allowed, denied }

    static var state: State {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: .allowed
        case .notDetermined: .notAsked
        default: .denied
        }
    }

    /// True when this device has a camera an app can use.
    static var isAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    /// Asks Apple's Camera question when it hasn't been asked. True when the camera is on.
    static func request() async -> Bool {
        if state == .notAsked { return await AVCaptureDevice.requestAccess(for: .video) }
        return state == .allowed
    }
}

/// The system camera, handing back the picture as JPEG data.
struct CameraPicker: UIViewControllerRepresentable {
    let onPicture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: AppConstants.photoCompressionQuality) {
                parent.onPicture(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// Settings: Camera — on or off, and the Access Camera button.
struct CameraSection: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var state = CameraAccess.state
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .headline) private var headingSize: CGFloat = 20

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text("Camera").font(.system(size: headingSize, weight: .semibold))
                } icon: {
                    Image(systemName: "camera.fill").foregroundStyle(.tint)
                }
                Text("Milestones uses the camera when you tap Take Picture in a sense's sheet, to add a picture to your entry.")
                    .font(.system(size: bodySize))
                Label(words, systemImage: symbol)
                    .font(.system(size: bodySize, weight: .semibold))
                    .foregroundStyle(state == .allowed ? Color.green : Color.secondary)
                    .accessibilityIdentifier("cameraStatus")
                Button(action: access) {
                    Text("Access Camera").font(.system(size: bodySize, weight: .semibold))
                        .foregroundStyle(SettingsView.buttonBlue)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("accessCamera")
                .accessibilityHint(state == .notAsked ? "Brings up Apple's Camera question." : "Opens the Settings app.")
                Text(footnote).font(.system(size: bodySize)).foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
        .onChange(of: scenePhase) { _, phase in if phase == .active { state = CameraAccess.state } }
    }

    private var words: String {
        switch state {
        case .allowed: "Camera is on"
        case .denied: "Camera is off"
        case .notAsked: "Not asked yet"
        }
    }

    private var symbol: String {
        switch state {
        case .allowed: "checkmark.circle.fill"
        case .denied: "xmark.circle.fill"
        case .notAsked: "questionmark.circle"
        }
    }

    private var footnote: String {
        switch state {
        case .notAsked: "Tap Access Camera and Apple asks whether Milestones may use it."
        case .denied: "Apple won't ask again after a no. Tap Access Camera to turn it on in the Settings app, under Milestones."
        case .allowed: "To turn it off, tap Access Camera and change it in the Settings app, under Milestones."
        }
    }

    private func access() {
        if state == .notAsked {
            Task { _ = await CameraAccess.request(); state = CameraAccess.state }
            return
        }
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
    }
}
#endif
