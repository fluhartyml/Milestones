//
//  DateStampView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI

/// Displays the filing timestamp: YYYY MMM DD HHMM
struct DateStampView: View {
    let date: Date

    var body: some View {
        Text(date.filingStamp)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
    }
}

#Preview {
    DateStampView(date: .now)
}
