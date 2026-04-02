//
//  SensePicker.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI

/// Grid of seven sense tiles — tap to activate/deactivate senses for an entry. (2.1–2.7)
struct SensePicker: View {
    @Binding var activeSenses: Set<SenseType>

    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(SenseType.allCases) { sense in
                senseTile(sense)
            }
        }
    }

    private func senseTile(_ sense: SenseType) -> some View {
        let isActive = activeSenses.contains(sense)
        let isAvailable = SenseType.v1Senses.contains(sense)

        return Button {
            if isAvailable {
                if isActive {
                    activeSenses.remove(sense)
                } else {
                    activeSenses.insert(sense)
                }
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: sense.icon)
                    .font(.title2)
                Text(sense.displayName)
                    .font(.caption2)
            }
            .frame(width: 80, height: 70)
            .foregroundStyle(isActive ? .white : isAvailable ? .primary : .secondary)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.accentColor : Color.gray.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isActive ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
    }
}
