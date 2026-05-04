import Foundation

struct FavoriteNeighborhoodResponse: Decodable, Identifiable {
    let id: Int
    let userId: Int?
    let neighborhoodId: Int
    let createdAt: String
    let neighborhood: FavoriteNeighborhood?
    let name: String?
    let city: String?
    let district: String?
    let mykiScore: Double?
    let mykiCategory: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case neighborhoodId = "neighborhood_id"
        case createdAt = "created_at"
        case neighborhood
        case name
        case city
        case district
        case mykiScore = "myki_score"
        case mykiCategory = "myki_category"
    }

    init(
        id: Int = 0,
        userId: Int? = nil,
        neighborhoodId: Int = 0,
        createdAt: String = "",
        neighborhood: FavoriteNeighborhood? = nil,
        name: String? = nil,
        city: String? = nil,
        district: String? = nil,
        mykiScore: Double? = nil,
        mykiCategory: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.neighborhoodId = neighborhoodId
        self.createdAt = createdAt
        self.neighborhood = neighborhood
        self.name = name
        self.city = city
        self.district = district
        self.mykiScore = mykiScore
        self.mykiCategory = mykiCategory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        userId = try container.decodeIfPresent(Int.self, forKey: .userId)
        neighborhoodId = try container.decodeIfPresent(Int.self, forKey: .neighborhoodId) ?? 0
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        neighborhood = try container.decodeIfPresent(FavoriteNeighborhood.self, forKey: .neighborhood)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        district = try container.decodeIfPresent(String.self, forKey: .district)
        mykiScore = try container.decodeFlexibleDoubleIfPresent(forKey: .mykiScore)
        mykiCategory = try container.decodeIfPresent(String.self, forKey: .mykiCategory)
    }
}

struct FavoriteNeighborhood: Decodable {
    let id: Int
    let name: String
    let city: String
    let district: String
    let latitude: Double?
    let longitude: Double?
    let mykiScore: Double?
    let mykiCategory: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case city
        case district
        case latitude
        case longitude
        case mykiScore = "myki_score"
        case mykiCategory = "myki_category"
    }

    init(
        id: Int = 0,
        name: String = "",
        city: String = "",
        district: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        mykiScore: Double? = nil,
        mykiCategory: String? = nil
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.district = district
        self.latitude = latitude
        self.longitude = longitude
        self.mykiScore = mykiScore
        self.mykiCategory = mykiCategory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        city = try container.decodeIfPresent(String.self, forKey: .city) ?? ""
        district = try container.decodeIfPresent(String.self, forKey: .district) ?? ""
        latitude = try container.decodeFlexibleDoubleIfPresent(forKey: .latitude)
        longitude = try container.decodeFlexibleDoubleIfPresent(forKey: .longitude)
        mykiScore = try container.decodeFlexibleDoubleIfPresent(forKey: .mykiScore)
        mykiCategory = try container.decodeIfPresent(String.self, forKey: .mykiCategory)
    }
}
