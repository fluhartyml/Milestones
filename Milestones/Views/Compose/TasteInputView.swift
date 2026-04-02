//
//  TasteInputView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import PhotosUI

/// Photo and text input for the Taste sense. (2.5)
struct TasteInputView: View {
    @Binding var description: String
    @Binding var photoItem: PhotosPickerItem?
    @Binding var photoData: Data?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Taste — What do you taste?", systemImage: "mouth")
                .font(.subheadline.bold())

            TextField("Describe the flavor...", text: $description, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Photo of Food/Drink", systemImage: "camera")
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
