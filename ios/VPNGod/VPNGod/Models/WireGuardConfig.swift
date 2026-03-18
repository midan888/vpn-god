import Foundation

struct WireGuardConfig: Decodable {
    let interfacePrivateKey: String
    let interfaceAddress: String
    let interfaceDNS: String
    let peerPublicKey: String
    let peerEndpoint: String
    let peerAllowedIPs: String

    enum CodingKeys: String, CodingKey {
        case interfacePrivateKey = "interface_private_key"
        case interfaceAddress = "interface_address"
        case interfaceDNS = "interface_dns"
        case peerPublicKey = "peer_public_key"
        case peerEndpoint = "peer_endpoint"
        case peerAllowedIPs = "peer_allowed_ips"
    }
}

struct ConnectRequest: Encodable {
    let serverID: UUID

    enum CodingKeys: String, CodingKey {
        case serverID = "server_id"
    }
}

struct DisconnectResponse: Decodable {
    let message: String
}
