//
//  WeatherService.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import Foundation
import WeatherKit
import CoreLocation

/// Fetches current and historical weather via Apple WeatherKit.
@Observable
final class WeatherService {

    private let service = WeatherKit.WeatherService.shared

    // MARK: - Current Weather (3.1)

    /// Fetch current conditions for a location and stamp them onto an entry.
    func stampCurrentWeather(on entry: MilestoneEntry, at location: CLLocation) async {
        do {
            let weather = try await service.weather(for: location)
            let current = weather.currentWeather
            entry.weatherCondition = current.condition.description
            entry.weatherTemperature = current.temperature.converted(to: .fahrenheit).value
            entry.weatherHumidity = current.humidity * 100
            entry.weatherWindSpeed = current.wind.speed.converted(to: .milesPerHour).value
            entry.weatherUVIndex = current.uvIndex.value
            entry.weatherDescription = current.condition.description
        } catch {
            print("Current weather fetch failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Historical Weather (3.2)

    /// Fetch historical weather for a past date and location, stamp onto an entry.
    func stampHistoricalWeather(on entry: MilestoneEntry, at location: CLLocation, for date: Date) async {
        guard date < Date() else {
            // Future date — fetch forecast instead or skip
            await stampCurrentWeather(on: entry, at: location)
            return
        }

        do {
            let startOfDay = Calendar.current.startOfDay(for: date)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

            let weather = try await service.weather(
                for: location,
                including: .hourly(startDate: startOfDay, endDate: endOfDay)
            )

            // Use noon hour as representative weather for the day
            let noonComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
            var noon = Calendar.current.date(from: noonComponents)!
            noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: noon)!

            // Find the hourly forecast closest to noon
            let closest = weather.forecast.min(by: {
                abs($0.date.timeIntervalSince(noon)) < abs($1.date.timeIntervalSince(noon))
            })

            if let hour = closest {
                entry.weatherCondition = hour.condition.description
                entry.weatherTemperature = hour.temperature.converted(to: .fahrenheit).value
                entry.weatherHumidity = hour.humidity * 100
                entry.weatherWindSpeed = hour.wind.speed.converted(to: .milesPerHour).value
                entry.weatherUVIndex = hour.uvIndex.value
                entry.weatherDescription = hour.condition.description
            }
        } catch {
            print("Historical weather fetch failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Smart Stamp

    /// Automatically chooses current or historical weather based on the entry's event date.
    func stampWeather(on entry: MilestoneEntry, at location: CLLocation) async {
        let isToday = Calendar.current.isDateInToday(entry.eventDate)
        if isToday {
            await stampCurrentWeather(on: entry, at: location)
        } else {
            await stampHistoricalWeather(on: entry, at: location, for: entry.eventDate)
        }
    }
}
