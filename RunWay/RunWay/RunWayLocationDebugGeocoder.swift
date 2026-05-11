import CoreLocation
import Foundation

#if DEBUG
/// Reverse geocode yalnızca konsol debug içindir; üretimde çağrılmaz.
enum RunWayLocationDebugGeocoder {
    static func logReverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error {
                RunWayDebugLog.location("reverse geocode: error=\(error.localizedDescription)")
                return
            }
            guard let p = placemarks?.first else {
                RunWayDebugLog.location("reverse geocode: no placemark")
                return
            }
            let admin = p.administrativeArea ?? "nil"
            let locality = p.locality ?? "nil"
            let subLoc = p.subLocality ?? "nil"
            let thoroughfare = p.thoroughfare ?? "nil"
            let subThoroughfare = p.subThoroughfare ?? "nil"
            RunWayDebugLog.location(
                "reverse geocode: administrativeArea=\(admin) locality=\(locality) subLocality=\(subLoc) thoroughfare=\(thoroughfare) subThoroughfare=\(subThoroughfare)"
            )
        }
    }
}
#endif
