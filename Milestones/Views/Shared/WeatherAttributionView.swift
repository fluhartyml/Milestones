//
//  WeatherAttributionView.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import SwiftUI
import WeatherKit

/// Apple WeatherKit compliance — displays the official  Weather attribution.
struct WeatherAttributionView: View {
    @State private var attribution: WeatherAttribution?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if let attribution {
                AsyncImage(
                    url: colorScheme == .dark
                        ? attribution.combinedMarkDarkURL
                        : attribution.combinedMarkLightURL
                ) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 12)
                } placeholder: {
                    appleWeatherFallback
                }
            } else {
                appleWeatherFallback
            }
        }
        .task {
            do {
                attribution = try await WeatherKit.WeatherService.shared.attribution
            } catch {
                // Fallback text will show
            }
        }
    }

    /// Fallback text if the attribution image can't load
    private var appleWeatherFallback: some View {
        HStack(spacing: 2) {
            Image(systemName: "apple.logo")
                .font(.caption2)
            Text("Weather")
                .font(.caption2)
        }
        .foregroundStyle(.tertiary)
    }
}
