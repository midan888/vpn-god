import SwiftUI

struct ServerCard: View {
    let server: Server?
    var latencyMs: Int?
    let onChangeTapped: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: VPNSpacing.md) {
                if let server {
                    Text(flag(for: server.country))
                        .font(.system(size: 36))

                    VStack(alignment: .leading, spacing: VPNSpacing.xs) {
                        Text(server.name)
                            .vpnTextStyle(.sectionHeader)
                        HStack(spacing: VPNSpacing.sm) {
                            Text(server.country.uppercased())
                                .vpnTextStyle(.caption, color: .vpnTextSecondary)
                            if let ms = latencyMs {
                                Text("\(ms) ms")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(latencyColor(ms: ms))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(latencyColor(ms: ms).opacity(0.12))
                                    )
                            }
                        }
                    }
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.vpnTextTertiary)

                    VStack(alignment: .leading, spacing: VPNSpacing.xs) {
                        Text("No Server Selected")
                            .vpnTextStyle(.sectionHeader)
                        Text("Tap to choose a server")
                            .vpnTextStyle(.caption, color: .vpnTextSecondary)
                    }
                }

                Spacer()

                Button(action: onChangeTapped) {
                    Text("Change")
                        .vpnTextStyle(.caption, color: .vpnPrimary)
                        .padding(.horizontal, VPNSpacing.sm + VPNSpacing.xs)
                        .padding(.vertical, VPNSpacing.xs + 2)
                        .background(
                            Capsule()
                                .fill(Color.vpnPrimary.opacity(0.15))
                        )
                }
            }
        }
    }

    private func latencyColor(ms: Int) -> Color {
        switch LatencyQuality(ms: ms) {
        case .excellent, .good: .vpnConnected
        case .fair: .vpnConnecting
        case .poor: .vpnDisconnected
        }
    }

    private func flag(for countryCode: String) -> String {
        let base: UInt32 = 127397
        return countryCode
            .uppercased()
            .unicodeScalars
            .compactMap { UnicodeScalar(base + $0.value) }
            .map { String($0) }
            .joined()
    }
}

#Preview {
    ZStack {
        Color.vpnBackground.ignoresSafeArea()

        VStack(spacing: VPNSpacing.md) {
            ServerCard(
                server: Server(id: UUID(), name: "New York", country: "US", host: "10.0.0.1", pingPort: 8080, isActive: true),
                onChangeTapped: {}
            )
            ServerCard(server: nil, onChangeTapped: {})
        }
        .padding()
    }
}
