import Foundation
import CoreLocation

struct NeighborhoodMarkerWithScore: Decodable, Identifiable {
    let id: Int
    let name: String
    let city: String
    let district: String
    let latitude: Double
    let longitude: Double
    let mykiScore: Double?
    let mykiCategory: String?

    enum CodingKeys: String, CodingKey {
        case id, name, city, district, latitude, longitude
        case mykiScore = "myki_score"
        case mykiCategory = "myki_category"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        city = try c.decode(String.self, forKey: .city)
        district = try c.decode(String.self, forKey: .district)
        latitude = try c.decodeFlexibleDouble(forKey: .latitude)
        longitude = try c.decodeFlexibleDouble(forKey: .longitude)
        mykiScore = try c.decodeFlexibleDoubleIfPresent(forKey: .mykiScore)
        mykiCategory = try c.decodeIfPresent(String.self, forKey: .mykiCategory)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var displayTitle: String {
        "\(name) · \(district)"
    }
}
