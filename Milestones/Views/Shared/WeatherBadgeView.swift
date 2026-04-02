//
//  WeatherBadgeView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI

/// Compact weather display for entry rows and detail views.
struct WeatherBadgeView: View {
    let entry: MilestoneEntry

    var body: some View {
        if entry.hasWeather {
            HStack(spacing: 6) {
                if let condition = entry.weatherCondition {
                    Image(systemName: weatherIcon(for: condition))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                if let temp = entry.weatherTemperature {
                    Text("\(Int(temp))°F")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let humidity = entry.weatherHumidity {
                    Text("\(Int(humidity))%")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private func weatherIcon(for condition: String) -> String {
        let lower = condition.lowercased()
        if lower.contains("clear") || lower.contains("sunny") {
            return "sun.max.fill"
        } else if lower.contains("cloud") {
            return "cloud.fill"
        } else if lower.contains("rain") {
            return "cloud.rain.fill"
        } else if lower.contains("snow") {
            return "cloud.snow.fill"
        } else if lower.contains("thunder") || lower.contains("storm") {
            return "cloud.bolt.fill"
        } else if lower.contains("fog") || lower.contains("haze") {
            return "cloud.fog.fill"
        } else if lower.contains("wind") {
            return "wind"
        } else {
            return "cloud.fill"
        }
    }
}
