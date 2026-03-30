import SwiftUI

struct ServerCard: View {
    let server: Server?
    var latencyMs: Int?
    let onChangeTapped: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: VPNSpacing.md) {
                if let server {
                    FlagView(countryCode: server.country, size: 36)

                    VStack(alignment: .leading, spacing: VPNSpacing.xs) {
                        Text(server.name)
                            .vpnTextStyle(.sectionHeader)
                        HStack(spacing: VPNSpacing.sm) {
                            Text(server.country.uppercased())
                                .vpnTextStyle(.caption, color: .vpnTextSecondary)
                            if let ms = latencyMs {
                                SignalBars(quality: LatencyQuality(ms: ms), size: .compact)
                                    .frame(width: 22, height: 16)
                            }
                        }
                    }
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.vpnTextTertiary)

                    VStack(alignment: .leading, spacing: VPNSpacing.xs) {
                        Text(L10n.ServerCard.noServerSelected)
                            .vpnTextStyle(.sectionHeader)
                        Text(L10n.ServerCard.tapToChoose)
                            .vpnTextStyle(.caption, color: .vpnTextSecondary)
                    }
                }

                Spacer()

                Button(action: onChangeTapped) {
                    Text(L10n.ServerCard.change)
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
