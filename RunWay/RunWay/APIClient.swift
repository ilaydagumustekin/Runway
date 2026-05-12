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

        self.decoder = JSONDecoder()
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

    /// Decodes either a bare JSON array `[T]` or common FastAPI/Pydantic wrappers such as `{ "items": [...] }`, `{ "data": [...] }`.
    func getArray<Response: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        token: String? = nil
    ) async throws -> [Response] {
        let request = try makeRequest(
            path: path,
            method: "GET",
            queryItems: queryItems,
            token: token,
            body: nil
        )
        return try await sendArray(request, element: Response.self)
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

    func post<Response: Decodable>(
        path: String,
        token: String? = nil
    ) async throws -> Response {
        let request = try makeRequest(
            path: path,
            method: "POST",
            queryItems: [],
            token: token,
            body: nil
        )

        return try await send(request, decode: Response.self)
    }

    func delete<Response: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        token: String? = nil
    ) async throws -> Response {
        let request = try makeRequest(
            path: path,
            method: "DELETE",
            queryItems: queryItems,
            token: token,
            body: nil
        )

        return try await send(request, decode: Response.self)
    }

    func patch<Response: Decodable>(
        path: String,
        token: String? = nil
    ) async throws -> Response {
        let request = try makeRequest(
            path: path,
            method: "PATCH",
            queryItems: [],
            token: token,
            body: nil
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

    private func validatedResponseData(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
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

        return (data, httpResponse)
    }

    private func send<Response: Decodable>(
        _ request: URLRequest,
        decode type: Response.Type
    ) async throws -> Response {
        let urlString = request.url?.absoluteString ?? "(unknown URL)"
        do {
            let (data, httpResponse) = try await validatedResponseData(for: request)

            do {
                return try decoder.decode(Response.self, from: data)
            } catch let error as DecodingError {
                Self.logDecodingError(
                    error,
                    statusCode: httpResponse.statusCode,
                    urlString: urlString,
                    responseData: data
                )
                throw APIClientError.decodingFailed
            } catch {
                Self.logNonDecodingDecodeFailure(
                    error,
                    statusCode: httpResponse.statusCode,
                    urlString: urlString,
                    responseData: data
                )
                throw APIClientError.decodingFailed
            }
        } catch let error as APIClientError {
            throw error
        } catch {
            throw APIClientError.networkError(error)
        }
    }

    private func sendArray<Response: Decodable>(
        _ request: URLRequest,
        element: Response.Type
    ) async throws -> [Response] {
        let urlString = request.url?.absoluteString ?? "(unknown URL)"
        do {
            let (data, httpResponse) = try await validatedResponseData(for: request)

            do {
                return try Self.decodeJSONArray(Response.self, from: data, decoder: decoder)
            } catch let error as DecodingError {
                Self.logDecodingError(
                    error,
                    statusCode: httpResponse.statusCode,
                    urlString: urlString,
                    responseData: data
                )
                throw APIClientError.decodingFailed
            } catch {
                Self.logNonDecodingDecodeFailure(
                    error,
                    statusCode: httpResponse.statusCode,
                    urlString: urlString,
                    responseData: data
                )
                throw APIClientError.decodingFailed
            }
        } catch let error as APIClientError {
            throw error
        } catch {
            throw APIClientError.networkError(error)
        }
    }

    /// Tries `[T]` first, then `{ items|data|favorites|notifications|results|payload: [T] }`.
    private static func decodeJSONArray<T: Decodable>(_ type: T.Type, from data: Data, decoder: JSONDecoder) throws -> [T] {
        if let direct = try? decoder.decode([T].self, from: data) {
            return direct
        }

        let envelope = try decoder.decode(JSONArrayEnvelope<T>.self, from: data)
        if let list = envelope.items
            ?? envelope.data
            ?? envelope.favorites
            ?? envelope.notifications
            ?? envelope.results
            ?? envelope.payload {
            return list
        }

        throw DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "Expected a JSON array or an object wrapping an array under a known key.")
        )
    }

    private static func decodeErrorMessage(from data: Data) -> String {
        guard !data.isEmpty else {
            return "Bilinmeyen hata"
        }

        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            return String(data: data, encoding: .utf8) ?? "Bilinmeyen hata"
        }

        if let dict = jsonObject as? [String: Any] {
            if let detail = dict["detail"] as? String {
                return detail
            }

            if let detailArr = dict["detail"] as? [String] {
                let joined = detailArr.filter { !$0.isEmpty }.joined(separator: "; ")
                if !joined.isEmpty {
                    return joined
                }
            }

            if let detailArr = dict["detail"] as? [[String: Any]] {
                let msgs = detailArr.compactMap { $0["msg"] as? String }
                if !msgs.isEmpty {
                    return msgs.joined(separator: "; ")
                }
                let fallback = detailArr.map { item -> String in
                    if let msg = item["msg"] as? String { return msg }
                    return (item as NSDictionary).description
                }
                .joined(separator: "; ")
                if !fallback.isEmpty {
                    return fallback
                }
            }

            if let msg = dict["message"] as? String {
                return msg
            }
        }

        if let errorResponse = try? JSONDecoder().decode(APIErrorDetailString.self, from: data) {
            return errorResponse.detail
        }

        return String(data: data, encoding: .utf8) ?? "Bilinmeyen hata"
    }

    private static func logDecodingError(
        _ error: DecodingError,
        statusCode: Int,
        urlString: String,
        responseData: Data
    ) {
        let responseText = String(data: responseData, encoding: .utf8) ?? "<response is not valid UTF-8>"
        print("[APIClient] decode failure")
        print("[APIClient] URL:", urlString)
        print("[APIClient] HTTP status:", statusCode)
        print("[APIClient] Raw JSON body:", responseText)
        print("[APIClient] DecodingError:", Self.detailedDescription(for: error))

        switch error {
        case let .typeMismatch(type, context):
            print(
                "DecodingError.typeMismatch:",
                type,
                context.debugDescription,
                "path:",
                context.codingPath.map(\.stringValue).joined(separator: ".")
            )
        case let .valueNotFound(type, context):
            print(
                "DecodingError.valueNotFound:",
                type,
                context.debugDescription,
                "path:",
                context.codingPath.map(\.stringValue).joined(separator: ".")
            )
        case let .keyNotFound(key, context):
            print(
                "DecodingError.keyNotFound:",
                key.stringValue,
                context.debugDescription,
                "path:",
                context.codingPath.map(\.stringValue).joined(separator: ".")
            )
        case let .dataCorrupted(context):
            print(
                "DecodingError.dataCorrupted:",
                context.debugDescription,
                "path:",
                context.codingPath.map(\.stringValue).joined(separator: ".")
            )
        @unknown default:
            print("Unknown DecodingError:", error.localizedDescription)
        }
    }

    private static func detailedDescription(for error: DecodingError) -> String {
        switch error {
        case let .typeMismatch(type, context):
            return "typeMismatch(\(type)): \(context.debugDescription) codingPath=\(context.codingPath.map(\.stringValue).joined(separator: "."))"
        case let .valueNotFound(type, context):
            return "valueNotFound(\(type)): \(context.debugDescription) codingPath=\(context.codingPath.map(\.stringValue).joined(separator: "."))"
        case let .keyNotFound(key, context):
            return "keyNotFound(\(key.stringValue)): \(context.debugDescription) codingPath=\(context.codingPath.map(\.stringValue).joined(separator: "."))"
        case let .dataCorrupted(context):
            return "dataCorrupted: \(context.debugDescription) codingPath=\(context.codingPath.map(\.stringValue).joined(separator: "."))"
        @unknown default:
            return error.localizedDescription
        }
    }

    private static func logNonDecodingDecodeFailure(
        _ error: Error,
        statusCode: Int,
        urlString: String,
        responseData: Data
    ) {
        let responseText = String(data: responseData, encoding: .utf8) ?? "<response is not valid UTF-8>"
        print("[APIClient] decode failure (non-DecodingError)")
        print("[APIClient] URL:", urlString)
        print("[APIClient] HTTP status:", statusCode)
        print("[APIClient] Raw JSON body:", responseText)
        print("[APIClient] Error:", error)
    }
}

struct EmptyAPIResponse: Decodable {}

/// FastAPI simple `{ "detail": "..." }` shape (still used as fallback).
private struct APIErrorDetailString: Decodable {
    let detail: String
}

/// Wraps list payloads when the API returns `{ "items": [...] }` (etc.) instead of a bare array.
private struct JSONArrayEnvelope<T: Decodable>: Decodable {
    let items: [T]?
    let data: [T]?
    let favorites: [T]?
    let notifications: [T]?
    let results: [T]?
    let payload: [T]?
}
