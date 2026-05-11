import Foundation

struct AirQualityForecastPoint: Decodable {
    let timestamp: String
    let predictedAqi: Double
    let predictedPm25: Double

    enum CodingKeys: String, CodingKey {
        case timestamp
        case predictedAqi = "predicted_aqi"
        case predictedPm25 = "predicted_pm25"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try c.decode(String.self, forKey: .timestamp)
        predictedAqi = try c.decodeFlexibleDouble(forKey: .predictedAqi)
        predictedPm25 = try c.decodeFlexibleDouble(forKey: .predictedPm25)
    }
}

struct AirQualityPredictionResponse: Decodable {
    let neighborhoodId: Int
    let horizonHours: Int
    let source: String
    let forecast: [AirQualityForecastPoint]

    enum CodingKeys: String, CodingKey {
        case neighborhoodId = "neighborhood_id"
        case horizonHours = "horizon_hours"
        case source
        case forecast
    }
}

struct GreenAreaAnalysisResponse: Decodable {
    let neighborhoodId: Int
    let status: String
    let message: String
    let supportedFutureProviders: [String]?

    enum CodingKeys: String, CodingKey {
        case neighborhoodId = "neighborhood_id"
        case status
        case message
        case supportedFutureProviders = "supported_future_providers"
    }
}

struct TuikValidationResponse: Decodable {
    let neighborhoodId: Int
    let status: String
    let source: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case neighborhoodId = "neighborhood_id"
        case status
        case source
        case message
    }
}
