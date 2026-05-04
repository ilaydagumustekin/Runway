import Foundation

enum APIClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case emptyResponse
    case decodingFailed
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Gecersiz API adresi."
        case .invalidResponse:
            return "Sunucudan gecersiz bir yanit alindi."
        case let .httpError(statusCode, message):
            return "API hatasi (\(statusCode)): \(message)"
        case .emptyResponse:
            return "Sunucudan bos yanit alindi."
        case .decodingFailed:
            return "Sunucu yaniti beklenen formatta degil."
        case let .networkError(error):
            return "Ag hatasi: \(error.localizedDescription)"
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(Self.decodeDate)
        self.decoder = decoder
    }

    func get<Response: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        token: String? = nil
    ) async throws -> Response {
        let request = try makeRequest(
            path: path,
            method: "GET",
            queryItems: queryItems,
            token: token,
            body: nil
        )

        return try await send(request, decode: Response.self)
    }

    func post<RequestBody: Encodable, Response: Decodable>(
        path: String,
        body: RequestBody,
        token: String? = nil
    ) async throws -> Response {
        let requestBody = try encoder.encode(body)
        let request = try makeRequest(
            path: path,
            method: "POST",
            queryItems: [],
            token: token,
            body: requestBody
        )

        return try await send(request, decode: Response.self)
    }

    private func makeRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem],
        token: String?,
        body: Data?
    ) throws -> URLRequest {
        guard var components = URLComponents(string: APIConfig.baseURL + path) else {
            throw APIClientError.invalidURL
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func send<Response: Decodable>(
        _ request: URLRequest,
        decode type: Response.Type
    ) async throws -> Response {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIClientError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = Self.decodeErrorMessage(from: data)
                throw APIClientError.httpError(statusCode: httpResponse.statusCode, message: message)
            }

            guard !data.isEmpty else {
                throw APIClientError.emptyResponse
            }

            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw APIClientError.decodingFailed
            }
        } catch let error as APIClientError {
            throw error
        } catch {
            throw APIClientError.networkError(error)
        }
    }

    private static func decodeErrorMessage(from data: Data) -> String {
        guard !data.isEmpty else {
            return "Bilinmeyen hata"
        }

        if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            return errorResponse.detail
        }

        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let detail = jsonObject["detail"] as? String {
            return detail
        }

        return String(data: data, encoding: .utf8) ?? "Bilinmeyen hata"
    }

    private static func decodeDate(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: value) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime]

        if let date = formatter.date(from: value) {
            return date
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Tarih formati desteklenmiyor: \(value)"
        )
    }
}

private struct APIErrorResponse: Decodable {
    let detail: String
}
