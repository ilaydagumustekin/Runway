import Foundation
import CoreLocation
import Combine

final class AppLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = AppLocationManager()

    private let manager = CLLocationManager()

    @Published var lastLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    /// Süre boyunca gelen ölçümlerden en iyi doğruluğu seçer; mümkünse `desiredAccuracy` altına inene kadar bekler.
    func waitForBestLocation(
        timeoutSeconds: TimeInterval = 18,
        desiredAccuracy: CLLocationAccuracy = 45
    ) async -> CLLocation? {
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }

        let deadline = Date().addingTimeInterval(timeoutSeconds)
        var best: CLLocation?

        while Date() < deadline {
            if let location = lastLocation,
               location.horizontalAccuracy > 0,
               location.horizontalAccuracy <= 500 {
                if best == nil || location.horizontalAccuracy < best!.horizontalAccuracy {
                    best = location
                }
                if location.horizontalAccuracy <= desiredAccuracy {
                    return location
                }
            }
            try? await Task.sleep(nanoseconds: 350_000_000)
        }

        return best ?? lastLocation
    }

    /// Dashboard / en yakın mahalle için: mümkün olduğunca net konum.
    func waitForFirstCoordinate(timeoutSeconds: TimeInterval = 12) async -> CLLocationCoordinate2D? {
        let location = await waitForBestLocation(timeoutSeconds: timeoutSeconds, desiredAccuracy: 40)
        return location?.coordinate ?? lastLocation?.coordinate
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            startUpdating()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        guard latest.horizontalAccuracy > 0 else { return }

        if lastLocation == nil {
            if latest.horizontalAccuracy <= 2500 {
                lastLocation = latest
                RunWayDebugLog.location(
                    "raw device location: lat=\(latest.coordinate.latitude), lon=\(latest.coordinate.longitude), hAcc_m=\(latest.horizontalAccuracy)"
                )
            }
            return
        }

        guard latest.horizontalAccuracy <= 200 else { return }
        if latest.horizontalAccuracy < lastLocation!.horizontalAccuracy {
            lastLocation = latest
            RunWayDebugLog.location(
                "raw device location: lat=\(latest.coordinate.latitude), lon=\(latest.coordinate.longitude), hAcc_m=\(latest.horizontalAccuracy)"
            )
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }
}
