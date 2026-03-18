import Foundation

struct APIErrorResponse: Decodable {
    let title: String?
    let detail: String?
    let status: Int?
}

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case conflict(String)
    case notFound(String)
    case badRequest(String)
    case serverError
    case networkError(Error)
    case decodingError
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .unauthorized:
            return "Invalid email or password"
        case .conflict(let message):
            return message
        case .notFound(let message):
            return message
        case .badRequest(let message):
            return message
        case .serverError:
            return "Something went wrong. Please try again."
        case .networkError:
            return "Unable to connect. Check your internet connection."
        case .decodingError:
            return "Unexpected response from server."
        case .sessionExpired:
            return "Session expired. Please log in again."
        }
    }
}
