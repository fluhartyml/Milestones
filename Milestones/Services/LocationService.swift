//
//  LocationService.swift
//  Milestones
//
//  Created by Michael Fluharty on 4/1/26.
//

import Foundation
import CoreLocation

/// Manages location permissions and provides current + reverse-geocoded locations.
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    var currentLocation: CLLocation?
    var locationName: String?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Public

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    /// Reverse geocode a coordinate into a human-readable place name.
    func reverseGeocode(_ location: CLLocation) async -> String? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let parts = [placemark.locality, placemark.administrativeArea, placemark.country]
                return parts.compactMap { $0 }.joined(separator: ", ")
            }
        } catch {
            print("Geocoding failed: \(error.localizedDescription)")
        }
        return nil
    }

    /// Stamp an entry with the current location and reverse-geocoded name.
    func stampEntry(_ entry: MilestoneEntry) async {
        guard let location = currentLocation else { return }
        entry.latitude = location.coordinate.latitude
        entry.longitude = location.coordinate.longitude
        entry.locationName = await reverseGeocode(location)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        #if os(macOS)
        if authorizationStatus == .authorized || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
        #else
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
        #endif
    }
}
