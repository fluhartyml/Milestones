//
//  SenseIconsView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI

/// Displays small icons for which senses are active on an entry.
struct SenseIconsView: View {
    let activeSenses: [String]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(activeSenses, id: \.self) { sense in
                if let senseType = SenseType(rawValue: sense) {
                    Image(systemName: senseType.icon)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
