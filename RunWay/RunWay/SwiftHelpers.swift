import CoreLocation
import Foundation

extension KeyedDecodingContainer {
    func decodeFlexibleDouble(forKey key: Key) throws -> Double {
        if let doubleValue = try decodeIfPresent(Double.self, forKey: key) {
            return doubleValue
        }

        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return Double(intValue)
        }

        if let stringValue = try decodeIfPresent(String.self, forKey: key),
           let doubleValue = Double(stringValue) {
            return doubleValue
        }

        throw DecodingError.typeMismatch(
            Double.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected Double-compatible value for '\(key.stringValue)'."
            )
        )
    }

    func decodeFlexibleDoubleIfPresent(forKey key: Key) throws -> Double? {
        if let doubleValue = try decodeIfPresent(Double.self, forKey: key) {
            return doubleValue
        }

        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return Double(intValue)
        }

        if let stringValue = try decodeIfPresent(String.self, forKey: key),
           let doubleValue = Double(stringValue) {
            return doubleValue
        }

        return nil
    }

    /// Accepts `true`/`false`, `0`/`1`, or common string forms — avoids throws from `decodeIfPresent(Bool.self, …)` when API sends integers.
    func decodeFlexibleBoolIfPresent(forKey key: Key) throws -> Bool? {
        if let boolValue = try decodeIfPresent(Bool.self, forKey: key) {
            return boolValue
        }
        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return intValue != 0
        }
        if let stringValue = try decodeIfPresent(String.self, forKey: key) {
            switch stringValue.lowercased() {
            case "1", "true", "yes", "y":
                return true
            case "0", "false", "no", "n":
                return false
            default:
                return nil
            }
        }
        return nil
    }

    func decodeFlexibleBool(forKey key: Key, default defaultValue: Bool = false) throws -> Bool {
        try decodeFlexibleBoolIfPresent(forKey: key) ?? defaultValue
    }

    func decodeFlexibleIntIfPresent(forKey key: Key) throws -> Int? {
        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }
        if let stringValue = try decodeIfPresent(String.self, forKey: key) {
            return Int(stringValue)
        }
        return nil
    }

    func decodeFlexibleDoubleArrayIfPresent(forKey key: Key) throws -> [Double]? {
        if let values = try decodeIfPresent([Double].self, forKey: key) {
            return values
        }

        if let values = try decodeIfPresent([Int].self, forKey: key) {
            return values.map(Double.init)
        }

        if let values = try decodeIfPresent([String].self, forKey: key) {
            return values.compactMap(Double.init)
        }

        return nil
    }
}

extension Double {
    var formattedMetricValue: String {
        if truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(self))
        }

        return String(format: "%.1f", self)
    }
}

extension CLLocationCoordinate2D {
    func distanceKm(to other: CLLocationCoordinate2D) -> Double {
        let a = CLLocation(latitude: latitude, longitude: longitude)
        let b = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return a.distance(from: b) / 1000.0
    }
}

func polylineDistanceKm(coordinates: [CLLocationCoordinate2D]) -> Double {
    guard coordinates.count >= 2 else { return 0 }
    var total = 0.0
    for index in 1 ..< coordinates.count {
        total += coordinates[index - 1].distanceKm(to: coordinates[index])
    }
    return total
}
