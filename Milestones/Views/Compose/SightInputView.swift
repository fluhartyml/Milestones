//
//  SightInputView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import PhotosUI

/// Photo picker and camera input for the Sight sense. (2.1)
struct SightInputView: View {
    @Binding var selectedPhotos: [PhotosPickerItem]
    @Binding var photoData: [Data]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sight — What do you see?", systemImage: "eye")
                .font(.subheadline.bold())

            // Photo picker
            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 5,
                matching: .images
            ) {
                Label("Choose Photos", systemImage: "photo.on.rectangle")
            }
            .onChange(of: selectedPhotos) { _, newItems in
                Task {
                    photoData.removeAll()
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            photoData.append(data)
                        }
                    }
                }
            }

            // Preview thumbnails
            if !photoData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(photoData.indices, id: \.self) { index in
                            #if os(macOS)
                            if let image = NSImage(data: photoData[index]) {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            #else
                            if let image = UIImage(data: photoData[index]) {
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
        }
    }
}
