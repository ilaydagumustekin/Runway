import Foundation

struct AirQualityForecastPoint: Decodable {
    let timestamp: String
    let predictedAqi: Double
    let predictedPm25: Double

    enum CodingKeys: String, CodingKey {
        case timestamp
        case time
        case validAt = "valid_at"
        case predictedAqi = "predicted_aqi"
        case aqi
        case value
        case predictedPm25 = "predicted_pm25"
        case pm25
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try c.decodeIfPresent(String.self, forKey: .timestamp), !s.isEmpty {
            timestamp = s
        } else if let s = try c.decodeIfPresent(String.self, forKey: .time), !s.isEmpty {
            timestamp = s
        } else if let s = try c.decodeIfPresent(String.self, forKey: .validAt), !s.isEmpty {
            timestamp = s
        } else {
            timestamp = ""
        }

        predictedAqi =
            (try? c.decodeFlexibleDoubleIfPresent(forKey: .predictedAqi))
            ?? (try? c.decodeFlexibleDoubleIfPresent(forKey: .aqi))
            ?? (try? c.decodeFlexibleDoubleIfPresent(forKey: .value))
            ?? 0

        predictedPm25 =
            (try? c.decodeFlexibleDoubleIfPresent(forKey: .predictedPm25))
            ?? (try? c.decodeFlexibleDoubleIfPresent(forKey: .pm25))
            ?? 0
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
        case predictions
        case series
        case data
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        neighborhoodId = try c.decodeIfPresent(Int.self, forKey: .neighborhoodId) ?? 0
        horizonHours = try c.decodeIfPresent(Int.self, forKey: .horizonHours) ?? 0
        source = try c.decodeIfPresent(String.self, forKey: .source) ?? ""

        let candidates: [[AirQualityForecastPoint]?] = [
            try? c.decode([AirQualityForecastPoint].self, forKey: .forecast),
            try? c.decode([AirQualityForecastPoint].self, forKey: .predictions),
            try? c.decode([AirQualityForecastPoint].self, forKey: .series),
            try? c.decode([AirQualityForecastPoint].self, forKey: .data),
        ]
        forecast = candidates.compactMap { $0 }.first { !$0.isEmpty } ?? []
    }
}

/// Back-end iki şema kullanabilir: eski placeholder (`message` + `supported_future_providers`)
/// veya yeni analiz (`analysis.green_percentage`, `confidence`, `detected_areas`).
struct GreenAreaAnalysisDetail: Decodable {
    let greenPercentage: Double
    let confidence: Double
    let detectedAreas: [String]

    enum CodingKeys: String, CodingKey {
        case greenPercentage = "green_percentage"
        case confidence
        case detectedAreas = "detected_areas"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        greenPercentage = try c.decodeFlexibleDouble(forKey: .greenPercentage)
        confidence = try c.decodeFlexibleDouble(forKey: .confidence)
        detectedAreas = try c.decodeIfPresent([String].self, forKey: .detectedAreas) ?? []
    }
}

struct GreenAreaAnalysisResponse: Decodable {
    let neighborhoodId: Int
    let status: String
    /// Eski placeholder yanıtları için.
    let message: String?
    let supportedFutureProviders: [String]?
    /// Yeni başarılı analiz gövdesi.
    let analysis: GreenAreaAnalysisDetail?

    enum CodingKeys: String, CodingKey {
        case neighborhoodId = "neighborhood_id"
        case status
        case message
        case supportedFutureProviders = "supported_future_providers"
        case analysis
    }
}

/// Tek gösterge satırı (`validations[]`).
struct TuikIndicatorValidation: Decodable {
    let indicator: String
    let measuredValue: Double
    let referenceValue: Double
    let absoluteError: Double
    let percentageError: Double
    let isValid: Bool
    let statusMessage: String

    enum CodingKeys: String, CodingKey {
        case indicator
        case measuredValue = "measured_value"
        case referenceValue = "reference_value"
        case absoluteError = "absolute_error"
        case percentageError = "percentage_error"
        case isValid = "is_valid"
        case statusMessage = "status_message"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        indicator = try c.decode(String.self, forKey: .indicator)
        measuredValue = try c.decodeFlexibleDouble(forKey: .measuredValue)
        referenceValue = try c.decodeFlexibleDouble(forKey: .referenceValue)
        absoluteError = try c.decodeFlexibleDouble(forKey: .absoluteError)
        percentageError = try c.decodeFlexibleDouble(forKey: .percentageError)
        isValid = try c.decode(Bool.self, forKey: .isValid)
        statusMessage = try c.decode(String.self, forKey: .statusMessage)
    }

    var metricsCaption: String {
        "Ölçüm \(measuredValue.formattedMetricValue) · Referans \(referenceValue.formattedMetricValue) · Mutlak sapma \(absoluteError.formattedMetricValue)"
    }
}

/// Yerel API: `city`, `district`, `overall_accuracy`, `validations[]`.
/// Eski placeholder: `status`, `source`, `message`, isteğe bağlı `validation` / `details` (JSON).
struct TuikValidationResponse: Decodable {
    let neighborhoodId: Int
    let status: String?
    let source: String?
    let message: String?
    let validation: JSONValue?
    let city: String?
    let district: String?
    let overallAccuracy: Double?
    let validations: [TuikIndicatorValidation]?

    enum CodingKeys: String, CodingKey {
        case neighborhoodId = "neighborhood_id"
        case status
        case source
        case message
        case dataSource = "data_source"
        case summary
        case validation
        case details
        case city
        case district
        case overallAccuracy = "overall_accuracy"
        case validations
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        neighborhoodId = try c.decode(Int.self, forKey: .neighborhoodId)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        source = try c.decodeIfPresent(String.self, forKey: .source)
            ?? c.decodeIfPresent(String.self, forKey: .dataSource)
        message = try c.decodeIfPresent(String.self, forKey: .message)
            ?? c.decodeIfPresent(String.self, forKey: .summary)
        validation = try c.decodeIfPresent(JSONValue.self, forKey: .validation)
            ?? c.decodeIfPresent(JSONValue.self, forKey: .details)
        city = try c.decodeIfPresent(String.self, forKey: .city)
        district = try c.decodeIfPresent(String.self, forKey: .district)
        overallAccuracy = try c.decodeFlexibleDoubleIfPresent(forKey: .overallAccuracy)
        validations = try c.decodeIfPresent([TuikIndicatorValidation].self, forKey: .validations)
    }

    /// Sunucu şehir/ilçe + doğrulama listesi döndüğünde kart bu düzeni kullanır.
    var usesStructuredTuikPayload: Bool {
        if overallAccuracy != nil { return true }
        if let v = validations, !v.isEmpty { return true }
        let hasPlace = [city, district].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.contains { !$0.isEmpty }
        return hasPlace
    }

    /// Üst başlık satırı: mümkünse `overall_accuracy`, yoksa `status`.
    var headlineCaption: String {
        if let acc = overallAccuracy {
            return String(format: "Genel doğruluk: %.1f%%", acc)
        }
        if let s = status?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            return "Durum: \(s)"
        }
        return "TÜİK karşılaştırması"
    }

    var locationCaption: String {
        let parts = [city, district]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.joined(separator: " · ")
    }

    /// Başlık altı kaynak satırı (eski şema veya konum).
    var displaySource: String {
        if usesStructuredTuikPayload {
            let loc = locationCaption
            if !loc.isEmpty { return loc }
            return "Mahalle #\(neighborhoodId)"
        }
        let s = source?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return s.isEmpty ? "Kaynak belirtilmedi" : s
    }

    /// Ana metin: düz `message` veya iç içe `validation`/`details` özeti (eski şema).
    var displayBody: String {
        if usesStructuredTuikPayload {
            if let v = validations, !v.isEmpty {
                return v.map { row in
                    let tag = row.isValid ? "✓" : "!"
                    return "\(tag) \(row.indicator): \(row.statusMessage)"
                }.joined(separator: "\n")
            }
            if overallAccuracy != nil {
                return "Gösterge listesi boş."
            }
            return "Detay yok."
        }
        if let m = message?.trimmingCharacters(in: .whitespacesAndNewlines), !m.isEmpty {
            return m
        }
        if let v = validation {
            let t = v.tuikFlatDisplayText
            return t.isEmpty ? "Detay yok." : t
        }
        return "Detay yok."
    }
}

private extension JSONValue {
    /// Çok satırlı kısa özet (TÜİK kartı için).
    var tuikFlatDisplayText: String {
        switch self {
        case .string(let s):
            return s
        case .number(let n):
            return n.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(n))
                : String(format: "%.2f", n)
        case .bool(let b):
            return b ? "evet" : "hayır"
        case .array(let items):
            return items.map { $0.tuikFlatDisplayText }.filter { !$0.isEmpty }.joined(separator: ", ")
        case .object(let dict):
            return dict
                .sorted { $0.key < $1.key }
                .map { "\($0.key): \($0.value.tuikFlatDisplayText)" }
                .joined(separator: "\n")
        case .null:
            return ""
        }
    }
}
