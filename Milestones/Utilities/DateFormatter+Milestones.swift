//
//  DateFormatter+Milestones.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import Foundation

extension DateFormatter {

    /// Filing format: YYYY MMM DD HHMM (e.g. "2026 APR 01 1735")
    static let filingStamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM dd HHmm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Display format for timeline rows: "APR 01, 2026 — 5:35 PM"
    static let timelineDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy — h:mm a"
        return formatter
    }()

    /// Short date for index rows: "APR 01, 2026"
    static let indexDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter
    }()

    /// Year only for time machine: "2026"
    static let yearOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
}

extension Date {

    /// Returns the filing stamp string: "2026 APR 01 1735"
    var filingStamp: String {
        DateFormatter.filingStamp.string(from: self).uppercased()
    }

    /// Returns the timeline display string: "APR 01, 2026 — 5:35 PM"
    var timelineDisplay: String {
        DateFormatter.timelineDisplay.string(from: self).uppercased()
    }
}
