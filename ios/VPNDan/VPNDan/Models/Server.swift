import Foundation

struct Server: Codable, Identifiable {
    let id: UUID
    let name: String
    let country: String
    let host: String
    let pingPort: Int
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, country, host
        case pingPort = "ping_port"
        case isActive = "is_active"
    }
}
