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
