import CoreLocation
import Foundation

private func flexibleDoubleFromString(_ stringValue: String) -> Double? {
    let trimmed = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    if let d = Double(trimmed) { return d }
    return Double(trimmed.replacingOccurrences(of: ",", with: "."))
}

extension KeyedDecodingContainer {
    /// Decodes a numeric metric from loose JSON: missing/null → `0`; bool → 0/1; numbers; numeric strings.
    /// Avoids `decodeIfPresent(Double.self)` on mixed-type APIs (e.g. `null` or bool) which throws `typeMismatch`.
    func decodeFlexibleDouble(forKey key: Key) throws -> Double {
        try decodeFlexibleDoubleIfPresent(forKey: key) ?? 0
    }

    func decodeFlexibleDoubleIfPresent(forKey key: Key) throws -> Double? {
        guard contains(key) else { return nil }
        if try decodeNil(forKey: key) { return nil }

        if let boolValue = try? decode(Bool.self, forKey: key) {
            return boolValue ? 1.0 : 0.0
        }
        if let doubleValue = try? decode(Double.self, forKey: key) {
            return doubleValue
        }
        if let intValue = try? decode(Int.self, forKey: key) {
            return Double(intValue)
        }
        if let stringValue = try? decode(String.self, forKey: key) {
            let trimmed = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if let d = Double(trimmed) { return d }
            let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
            return Double(normalized)
        }

        throw DecodingError.typeMismatch(
            Double.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected Double-compatible value for '\(key.stringValue)'."
            )
        )
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
        guard contains(key) else { return nil }
        if try decodeNil(forKey: key) { return nil }

        // APIs may send `[null, 42.0, …]`; `[Double]` / `decodeIfPresent([Double])` throws `valueNotFound(Double)`.
        if let sparse = try? decode([Double?].self, forKey: key) {
            return sparse.compactMap { $0 }
        }
        if let sparse = try? decode([Int?].self, forKey: key) {
            return sparse.compactMap { $0 }.map(Double.init)
        }
        if let values = try? decode([Int].self, forKey: key) {
            return values.map(Double.init)
        }
        if let strings = try? decode([String?].self, forKey: key) {
            return strings.compactMap { $0 }.compactMap(flexibleDoubleFromString)
        }
        if let strings = try? decode([String].self, forKey: key) {
            return strings.compactMap(flexibleDoubleFromString)
        }

        var nested = try nestedUnkeyedContainer(forKey: key)
        var result: [Double] = []
        while !nested.isAtEnd {
            if try nested.decodeNil() { continue }
            if let d = try? nested.decode(Double.self) {
                result.append(d)
            } else if let i = try? nested.decode(Int.self) {
                result.append(Double(i))
            } else if let s = try? nested.decode(String.self), let d = flexibleDoubleFromString(s) {
                result.append(d)
            } else if let b = try? nested.decode(Bool.self) {
                result.append(b ? 1.0 : 0.0)
            } else {
                _ = try? nested.decode(DecodableJSONSkip.self)
            }
        }
        return result
    }
}

/// Consumes one JSON value from an unkeyed container when chart arrays contain unexpected nested structures.
private struct DecodableJSONSkip: Decodable {
    private struct AnyCodingKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        if var unkeyed = try? decoder.unkeyedContainer() {
            while !unkeyed.isAtEnd {
                _ = try? unkeyed.decode(DecodableJSONSkip.self)
            }
            return
        }
        if let keyed = try? decoder.container(keyedBy: AnyCodingKey.self) {
            for key in keyed.allKeys {
                _ = try? keyed.decode(DecodableJSONSkip.self, forKey: key)
            }
            return
        }
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { return }
        if (try? c.decode(Bool.self)) != nil { return }
        if (try? c.decode(Int.self)) != nil { return }
        if (try? c.decode(Double.self)) != nil { return }
        _ = try? c.decode(String.self)
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

// MARK: - API date / time (Turkish UI)

/// API'den gelen ISO benzeri anlık metnini Türkçe takvim + saat ile gösterir (görüntüleme `Europe/Istanbul`).
enum RunWayAPIInstantFormatting {
    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let displayTR: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.timeZone = TimeZone(identifier: "Europe/Istanbul")
        f.dateStyle = .long
        f.timeStyle = .short
        return f
    }()

    /// Örnek çıktı: `12 Mayıs 2026 18:34`. Çözümlenemezse `nil`.
    static func turkishDisplayString(from raw: String) -> String? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }

        let candidates = [s, s.replacingOccurrences(of: " ", with: "T")]

        for c in candidates {
            if let d = isoFractional.date(from: c) ?? isoPlain.date(from: c) {
                return displayTR.string(from: d)
            }
        }

        let istanbul = TimeZone(identifier: "Europe/Istanbul") ?? .current
        let posix = DateFormatter()
        posix.locale = Locale(identifier: "en_US_POSIX")
        posix.timeZone = istanbul

        let patterns = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss.SSSSSS",
            "yyyy-MM-dd HH:mm:ss",
        ]

        for c in candidates {
            for p in patterns {
                posix.dateFormat = p
                if let d = posix.date(from: c) {
                    return displayTR.string(from: d)
                }
            }
        }

        return nil
    }
}
