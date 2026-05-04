import Foundation

struct NeighborhoodDetailResponse: Decodable {
    let neighborhood: NeighborhoodInfo
    let latestEnvironmentalData: LatestEnvironmentalData?
    let myki: MykiInfo?
    let chartSummary: ChartSummary
    let dataSources: [DataSourceSummary]

    enum CodingKeys: String, CodingKey {
        case neighborhood
        case latestEnvironmentalData = "latest_environmental_data"
        case myki
        case chartSummary = "chart_summary"
        case dataSources = "data_sources"
    }

    init(
        neighborhood: NeighborhoodInfo = NeighborhoodInfo(),
        latestEnvironmentalData: LatestEnvironmentalData? = nil,
        myki: MykiInfo? = nil,
        chartSummary: ChartSummary = ChartSummary(),
        dataSources: [DataSourceSummary] = []
    ) {
        self.neighborhood = neighborhood
        self.latestEnvironmentalData = latestEnvironmentalData
        self.myki = myki
        self.chartSummary = chartSummary
        self.dataSources = dataSources
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        neighborhood = try container.decodeIfPresent(NeighborhoodInfo.self, forKey: .neighborhood) ?? NeighborhoodInfo()
        latestEnvironmentalData = try container.decodeIfPresent(LatestEnvironmentalData.self, forKey: .latestEnvironmentalData)
        myki = try container.decodeIfPresent(MykiInfo.self, forKey: .myki)
        chartSummary = try container.decodeIfPresent(ChartSummary.self, forKey: .chartSummary) ?? ChartSummary()
        dataSources = try container.decodeIfPresent([DataSourceSummary].self, forKey: .dataSources) ?? []
    }
}

struct NeighborhoodInfo: Decodable {
    let id: Int
    let name: String
    let city: String
    let district: String
    let latitude: Double
    let longitude: Double
    let boundaryData: JSONValue?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case city
        case district
        case latitude
        case longitude
        case boundaryData = "boundary_data"
    }

    init(
        id: Int = 0,
        name: String = "",
        city: String = "",
        district: String = "",
        latitude: Double = 0,
        longitude: Double = 0,
        boundaryData: JSONValue? = nil
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.district = district
        self.latitude = latitude
        self.longitude = longitude
        self.boundaryData = boundaryData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        city = try container.decodeIfPresent(String.self, forKey: .city) ?? ""
        district = try container.decodeIfPresent(String.self, forKey: .district) ?? ""
        latitude = try container.decodeFlexibleDoubleIfPresent(forKey: .latitude) ?? 0
        longitude = try container.decodeFlexibleDoubleIfPresent(forKey: .longitude) ?? 0
        boundaryData = try container.decodeIfPresent(JSONValue.self, forKey: .boundaryData)
    }
}

struct LatestEnvironmentalData: Decodable {
    let id: Int
    let aqi: Double
    let pm25: Double
    let pm10: Double
    let no2: Double
    let o3: Double
    let greenAreaRatio: Double
    let noiseLevelDba: Double
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case aqi
        case pm25
        case pm10
        case no2
        case o3
        case greenAreaRatio = "green_area_ratio"
        case noiseLevelDba = "noise_level_dba"
        case createdAt = "created_at"
    }

    init(
        id: Int = 0,
        aqi: Double = 0,
        pm25: Double = 0,
        pm10: Double = 0,
        no2: Double = 0,
        o3: Double = 0,
        greenAreaRatio: Double = 0,
        noiseLevelDba: Double = 0,
        createdAt: String = ""
    ) {
        self.id = id
        self.aqi = aqi
        self.pm25 = pm25
        self.pm10 = pm10
        self.no2 = no2
        self.o3 = o3
        self.greenAreaRatio = greenAreaRatio
        self.noiseLevelDba = noiseLevelDba
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        aqi = try container.decodeFlexibleDoubleIfPresent(forKey: .aqi) ?? 0
        pm25 = try container.decodeFlexibleDoubleIfPresent(forKey: .pm25) ?? 0
        pm10 = try container.decodeFlexibleDoubleIfPresent(forKey: .pm10) ?? 0
        no2 = try container.decodeFlexibleDoubleIfPresent(forKey: .no2) ?? 0
        o3 = try container.decodeFlexibleDoubleIfPresent(forKey: .o3) ?? 0
        greenAreaRatio = try container.decodeFlexibleDoubleIfPresent(forKey: .greenAreaRatio) ?? 0
        noiseLevelDba = try container.decodeFlexibleDoubleIfPresent(forKey: .noiseLevelDba) ?? 0
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
    }
}

struct MykiInfo: Decodable {
    let score: Double
    let category: String

    enum CodingKeys: String, CodingKey {
        case score
        case category
    }

    init(score: Double = 0, category: String = "") {
        self.score = score
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decodeFlexibleDoubleIfPresent(forKey: .score) ?? 0
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
    }
}

struct ChartSummary: Decodable {
    let labels: [String]
    let aqi: [Double]
    let noiseLevelDba: [Double]
    let greenAreaRatio: [Double]
    let mykiScore: [Double]

    enum CodingKeys: String, CodingKey {
        case labels
        case aqi
        case noiseLevelDba = "noise_level_dba"
        case greenAreaRatio = "green_area_ratio"
        case mykiScore = "myki_score"
    }

    init(
        labels: [String] = [],
        aqi: [Double] = [],
        noiseLevelDba: [Double] = [],
        greenAreaRatio: [Double] = [],
        mykiScore: [Double] = []
    ) {
        self.labels = labels
        self.aqi = aqi
        self.noiseLevelDba = noiseLevelDba
        self.greenAreaRatio = greenAreaRatio
        self.mykiScore = mykiScore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        labels = try container.decodeIfPresent([String].self, forKey: .labels) ?? []
        aqi = try container.decodeFlexibleDoubleArrayIfPresent(forKey: .aqi) ?? []
        noiseLevelDba = try container.decodeFlexibleDoubleArrayIfPresent(forKey: .noiseLevelDba) ?? []
        greenAreaRatio = try container.decodeFlexibleDoubleArrayIfPresent(forKey: .greenAreaRatio) ?? []
        mykiScore = try container.decodeFlexibleDoubleArrayIfPresent(forKey: .mykiScore) ?? []
    }
}

struct DataSourceSummary: Decodable, Identifiable {
    let name: String
    let type: String
    let status: String

    var id: String { "\(name)-\(type)-\(status)" }

    init(name: String = "", type: String = "", status: String = "") {
        self.name = name
        self.type = type
        self.status = status
    }
}

enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .number(doubleValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let arrayValue = try? container.decode([JSONValue].self) {
            self = .array(arrayValue)
        } else if let objectValue = try? container.decode([String: JSONValue].self) {
            self = .object(objectValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value.")
        }
    }
}
