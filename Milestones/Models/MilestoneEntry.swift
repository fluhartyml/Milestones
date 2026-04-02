//
//  MilestoneEntry.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class MilestoneEntry {

    // MARK: - Core (1.0.1, 1.0.2, 1.0.3)

    /// The event date — past, present, or future. The arbiter of truth.
    var eventDate: Date

    /// User's title or description for the entry
    var title: String

    /// User's journal text — the body of the entry
    var body: String

    /// When the entry was actually created (distinct from eventDate)
    var createdAt: Date

    // MARK: - Location (3.3, 3.4)

    var latitude: Double?
    var longitude: Double?
    var locationName: String?

    // MARK: - Weather (3.1, 3.2)

    var weatherCondition: String?
    var weatherTemperature: Double?
    var weatherHumidity: Double?
    var weatherWindSpeed: Double?
    var weatherUVIndex: Int?
    var weatherDescription: String?

    // MARK: - Sight (2.1)

    /// Photo attachments stored as JPEG data
    @Attribute(.externalStorage)
    var sightPhotos: [Data]?

    // MARK: - Touch (2.3)

    var touchDescription: String?

    // MARK: - Smell (2.4)

    var smellDescription: String?

    @Attribute(.externalStorage)
    var smellPhoto: Data?

    // MARK: - Taste (2.5)

    var tasteDescription: String?

    @Attribute(.externalStorage)
    var tastePhoto: Data?

    // MARK: - Index / Milestone (1.0.5, 4.1)

    /// Whether this entry has been promoted to a milestone in the index
    var isMilestone: Bool

    /// Which senses the user tagged on this entry
    var activeSenses: [String]

    // MARK: - Init

    init(
        eventDate: Date,
        title: String,
        body: String = "",
        isMilestone: Bool = false
    ) {
        self.eventDate = eventDate
        self.title = title
        self.body = body
        self.createdAt = Date()
        self.isMilestone = isMilestone
        self.activeSenses = []
    }
}

// MARK: - Computed Properties

extension MilestoneEntry {

    /// Formatted filing name: YYYY MMM DD HHMM Title
    var filingName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM dd HHmm"
        let stamp = formatter.string(from: eventDate).uppercased()
        return "\(stamp) \(title)"
    }

    /// Whether this entry has any weather data
    var hasWeather: Bool {
        weatherCondition != nil || weatherTemperature != nil
    }

    /// Whether this entry has any location data
    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    /// Whether this entry has any photos attached
    var hasPhotos: Bool {
        if let photos = sightPhotos, !photos.isEmpty { return true }
        if smellPhoto != nil { return true }
        if tastePhoto != nil { return true }
        return false
    }
}
