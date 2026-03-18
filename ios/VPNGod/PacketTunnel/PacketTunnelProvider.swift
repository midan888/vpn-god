import NetworkExtension

#if !targetEnvironment(simulator)
import WireGuardKit
#endif

class PacketTunnelProvider: NEPacketTunnelProvider {

    #if !targetEnvironment(simulator)
    private lazy var adapter = WireGuardAdapter(with: self) { _, message in
        NSLog("WireGuard: %@", message)
    }
    #endif

    override func startTunnel(options: [String: NSObject]? = nil) async throws {
        // Load WireGuard config from App Group
        guard let defaults = UserDefaults(suiteName: "group.com.vpngod.VPNGod"),
              let data = defaults.data(forKey: "wg_config") else {
            throw PacketTunnelError.missingConfiguration
        }

        let config = try JSONDecoder().decode(WGConfig.self, from: data)

        #if targetEnvironment(simulator)
        // Simulator: just configure network settings without WireGuard
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: config.peerEndpoint)
        let ipv4 = NEIPv4Settings(
            addresses: [config.interfaceAddress.components(separatedBy: "/").first ?? "10.0.0.2"],
            subnetMasks: ["255.255.255.255"]
        )
        ipv4.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4
        settings.dnsSettings = NEDNSSettings(servers: [config.interfaceDNS])
        try await setTunnelNetworkSettings(settings)
        #else
        let tunnelConfig = try config.toTunnelConfiguration()
        return try await withCheckedThrowingContinuation { continuation in
            adapter.start(tunnelConfiguration: tunnelConfig) { adapterError in
                if let adapterError {
                    NSLog("WireGuard adapter start error: \(adapterError)")
                    continuation.resume(throwing: adapterError)
                } else {
                    continuation.resume()
                }
            }
        }
        #endif
    }

    override func stopTunnel(with reason: NEProviderStopReason) async {
        #if !targetEnvironment(simulator)
        return await withCheckedContinuation { continuation in
            adapter.stop { _ in
                continuation.resume()
            }
        }
        #endif
    }

    override func handleAppMessage(_ messageData: Data) async -> Data? {
        return nil
    }
}

// MARK: - Error

enum PacketTunnelError: LocalizedError {
    case missingConfiguration
    case invalidConfiguration(String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "No WireGuard configuration found"
        case .invalidConfiguration(let detail):
            return "Invalid WireGuard configuration: \(detail)"
        }
    }
}

// MARK: - Config

private struct WGConfig: Decodable {
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

    #if !targetEnvironment(simulator)
    func toTunnelConfiguration() throws -> TunnelConfiguration {
        guard let privateKey = PrivateKey(base64Key: interfacePrivateKey) else {
            throw PacketTunnelError.invalidConfiguration("invalid client private key")
        }

        guard let serverPublicKey = PublicKey(base64Key: peerPublicKey) else {
            throw PacketTunnelError.invalidConfiguration("invalid server public key")
        }

        guard let endpoint = Endpoint(from: peerEndpoint) else {
            throw PacketTunnelError.invalidConfiguration("invalid server endpoint: \(peerEndpoint)")
        }

        var interface = InterfaceConfiguration(privateKey: privateKey)
        interface.addresses = interfaceAddress
            .split(separator: ",")
            .compactMap { IPAddressRange(from: String($0).trimmingCharacters(in: .whitespaces)) }

        interface.dns = interfaceDNS
            .split(separator: ",")
            .compactMap { DNSServer(from: String($0).trimmingCharacters(in: .whitespaces)) }

        var peer = PeerConfiguration(publicKey: serverPublicKey)
        peer.endpoint = endpoint
        peer.allowedIPs = peerAllowedIPs
            .split(separator: ",")
            .compactMap { IPAddressRange(from: String($0).trimmingCharacters(in: .whitespaces)) }

        return TunnelConfiguration(name: "VPN God", interface: interface, peers: [peer])
    }
    #endif
}
