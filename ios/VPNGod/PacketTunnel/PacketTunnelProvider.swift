import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {

    override func startTunnel(options: [String: NSObject]? = nil) async throws {
        // Load WireGuard config from App Group
        guard let defaults = UserDefaults(suiteName: "group.com.vpngod.VPNGod"),
              let data = defaults.data(forKey: "wg_config") else {
            throw NSError(domain: "PacketTunnel", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No WireGuard configuration found"
            ])
        }

        let decoder = JSONDecoder()
        let config = try decoder.decode(WireGuardConfig.self, from: data)

        // TODO: Initialize WireGuard tunnel using wireguard-apple
        // This will be implemented in the VPN connection step (step 7)
        // For now, configure basic tunnel settings

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: config.peerEndpoint)

        let ipv4 = NEIPv4Settings(
            addresses: [config.interfaceAddress.components(separatedBy: "/").first ?? "10.0.0.2"],
            subnetMasks: ["255.255.255.255"]
        )
        ipv4.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4

        let dns = NEDNSSettings(servers: [config.interfaceDNS])
        settings.dnsSettings = dns

        try await setTunnelNetworkSettings(settings)
    }

    override func stopTunnel(with reason: NEProviderStopReason) async {
        // TODO: Tear down WireGuard tunnel
    }

    override func handleAppMessage(_ messageData: Data) async -> Data? {
        return nil
    }
}

// Local copy of WireGuardConfig for the extension target
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
