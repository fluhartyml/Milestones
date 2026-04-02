//
//  SmellInputView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import PhotosUI

/// Text and optional photo input for the Smell sense. (2.4)
struct SmellInputView: View {
    @Binding var description: String
    @Binding var photoItem: PhotosPickerItem?
    @Binding var photoData: Data?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Smell — What do you smell?", systemImage: "nose")
                .font(.subheadline.bold())

            TextField("Describe the scent...", text: $description, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Attach Photo", systemImage: "camera")
                    .font(.subheadline)
            }
            .onChange(of: photoItem) { _, newItem in
                Task {
                    photoData = try? await newItem?.loadTransferable(type: Data.self)
                }
            }

            if let data = photoData {
                #if os(macOS)
                if let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                #else
                if let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                #endif
            }
        }
    }
}
