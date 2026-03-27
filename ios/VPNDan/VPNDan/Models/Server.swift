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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        country = try container.decode(String.self, forKey: .country)
        host = try container.decode(String.self, forKey: .host)
        pingPort = try container.decodeIfPresent(Int.self, forKey: .pingPort) ?? 8080
        isActive = try container.decode(Bool.self, forKey: .isActive)
    }

    init(id: UUID, name: String, country: String, host: String, pingPort: Int = 8080, isActive: Bool) {
        self.id = id
        self.name = name
        self.country = country
        self.host = host
        self.pingPort = pingPort
        self.isActive = isActive
    }
}
