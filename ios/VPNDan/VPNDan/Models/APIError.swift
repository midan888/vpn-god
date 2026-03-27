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
    case serverUnavailable
    case serverAtCapacity
    case serverError
    case networkError(Error)
    case decodingError
    case sessionExpired
    case vpnPermissionRequired
    case vpnConnectionFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return L10n.Errors.invalidURL
        case .unauthorized:
            return L10n.Errors.unauthorized
        case .conflict(let message):
            return message
        case .notFound(let message):
            return message
        case .badRequest(let message):
            return message
        case .serverUnavailable:
            return L10n.Errors.serverUnavailable
        case .serverAtCapacity:
            return L10n.Errors.serverAtCapacity
        case .serverError:
            return L10n.Errors.serverError
        case .networkError:
            return L10n.Errors.networkError
        case .decodingError:
            return L10n.Errors.decodingError
        case .sessionExpired:
            return L10n.Errors.sessionExpired
        case .vpnPermissionRequired:
            return L10n.Errors.vpnPermissionRequired
        case .vpnConnectionFailed:
            return L10n.Errors.vpnConnectionFailed
        }
    }
}
