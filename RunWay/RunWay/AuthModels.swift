import Foundation

struct RegisterRequest: Encodable {
    let fullName: String
    let email: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case email
        case password
    }
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable {
    let accessToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}

struct UserProfileResponse: Decodable {
    let id: Int
    let fullName: String
    let email: String
    let role: String

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
        case role
    }
}
