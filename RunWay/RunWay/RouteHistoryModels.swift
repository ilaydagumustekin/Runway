import Foundation

struct RouteHistoryItem: Decodable, Identifiable, Equatable {
    let id: Int
    let createdAt: String
    let isFavorite: Bool
    let target: String?
    let travelMode: String?
    let etaMinutes: Int?
    let distanceKm: Double?
    let routeScore: Double?
    let warningText: String?
    let fromName: String?
    let toName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case isFavorite = "is_favorite"
        case target
        case travelMode = "travel_mode"
        case etaMinutes = "eta_minutes"
        case distanceKm = "distance_km"
        case routeScore = "route_score"
        case warningText = "warning_text"
        case fromName = "from_name"
        case toName = "to_name"
    }

    init(
        id: Int,
        createdAt: String,
        isFavorite: Bool,
        target: String? = nil,
        travelMode: String? = nil,
        etaMinutes: Int? = nil,
        distanceKm: Double? = nil,
        routeScore: Double? = nil,
        warningText: String? = nil,
        fromName: String? = nil,
        toName: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.target = target
        self.travelMode = travelMode
        self.etaMinutes = etaMinutes
        self.distanceKm = distanceKm
        self.routeScore = routeScore
        self.warningText = warningText
        self.fromName = fromName
        self.toName = toName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)

        id = Self.decodeFirstInt(from: dynamicContainer, keys: ["id"]) ?? 0
        createdAt = (try? container.decode(String.self, forKey: .createdAt)) ?? ""
        isFavorite = Self.decodeFirstBool(from: dynamicContainer, keys: ["is_favorite"]) ?? false
        target = Self.decodeFirstString(
            from: dynamicContainer,
            keys: ["target", "destination", "destination_name", "to", "to_name"]
        )
        travelMode = (try? container.decode(String.self, forKey: .travelMode))
            ?? Self.decodeFirstString(from: dynamicContainer, keys: ["mode", "transport_mode"])
        etaMinutes = Self.decodeFirstInt(
            from: dynamicContainer,
            keys: ["eta_minutes", "duration_minutes", "duration"]
        )
        distanceKm = Self.decodeFirstDouble(
            from: dynamicContainer,
            keys: ["distance_km", "distance"]
        )
        routeScore = Self.decodeFirstDouble(
            from: dynamicContainer,
            keys: ["route_score", "score", "myki_score"]
        )
        warningText = Self.decodeFirstString(
            from: dynamicContainer,
            keys: ["warning_text", "warning", "note"]
        )
        fromName = Self.decodeFirstString(
            from: dynamicContainer,
            keys: ["from_name", "from", "origin_name", "origin", "start_name", "start_location_name"]
        )
        toName = Self.decodeFirstString(
            from: dynamicContainer,
            keys: ["to_name", "to", "destination_name", "destination", "target"]
        )
    }

    private static func decodeFirstString(
        from container: KeyedDecodingContainer<DynamicCodingKey>,
        keys: [String]
    ) -> String? {
        for key in keys {
            guard let codingKey = DynamicCodingKey(stringValue: key) else { continue }

            if let value = try? container.decodeIfPresent(String.self, forKey: codingKey), let value {
                return value
            }
        }

        return nil
    }

    private static func decodeFirstInt(
        from container: KeyedDecodingContainer<DynamicCodingKey>,
        keys: [String]
    ) -> Int? {
        for key in keys {
            guard let codingKey = DynamicCodingKey(stringValue: key) else { continue }

            if let value = try? container.decodeIfPresent(Int.self, forKey: codingKey), let value {
                return value
            }

            if let value = try? container.decodeIfPresent(Double.self, forKey: codingKey), let value {
                return Int(value.rounded())
            }

            if let value = try? container.decodeIfPresent(String.self, forKey: codingKey),
               let value,
               let intValue = Int(value) {
                return intValue
            }
        }

        return nil
    }

    private static func decodeFirstDouble(
        from container: KeyedDecodingContainer<DynamicCodingKey>,
        keys: [String]
    ) -> Double? {
        for key in keys {
            guard let codingKey = DynamicCodingKey(stringValue: key) else { continue }

            if let value = try? container.decodeIfPresent(Double.self, forKey: codingKey), let value {
                return value
            }

            if let value = try? container.decodeIfPresent(Int.self, forKey: codingKey), let value {
                return Double(value)
            }

            if let value = try? container.decodeIfPresent(String.self, forKey: codingKey),
               let value,
               let doubleValue = Double(value) {
                return doubleValue
            }
        }

        return nil
    }

    private static func decodeFirstBool(
        from container: KeyedDecodingContainer<DynamicCodingKey>,
        keys: [String]
    ) -> Bool? {
        for key in keys {
            guard let codingKey = DynamicCodingKey(stringValue: key) else { continue }

            if let value = try? container.decodeIfPresent(Bool.self, forKey: codingKey), let value {
                return value
            }

            if let value = try? container.decodeIfPresent(Int.self, forKey: codingKey), let value {
                return value != 0
            }

            if let value = try? container.decodeIfPresent(String.self, forKey: codingKey), let value {
                switch value.lowercased() {
                case "true", "1":
                    return true
                case "false", "0":
                    return false
                default:
                    continue
                }
            }
        }

        return nil
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
