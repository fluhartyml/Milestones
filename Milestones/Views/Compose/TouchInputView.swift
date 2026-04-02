//
//  TouchInputView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI

/// Text input for the Touch sense. (2.3)
struct TouchInputView: View {
    @Binding var description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Touch — What do you feel?", systemImage: "hand.raised")
                .font(.subheadline.bold())

            TextField("Describe the texture, temperature, sensation...", text: $description, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
        }
    }
}
