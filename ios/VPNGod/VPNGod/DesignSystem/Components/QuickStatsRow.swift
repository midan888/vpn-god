import SwiftUI

struct QuickStatsRow: View {
    let isConnected: Bool
    let connectedDate: Date?

    var body: some View {
        GlassCard(padding: VPNSpacing.sm + VPNSpacing.xs) {
            HStack(spacing: 0) {
                statItem(
                    icon: "arrow.down",
                    value: isConnected ? "--" : "--",
                    label: "Download"
                )

                divider

                statItem(
                    icon: "arrow.up",
                    value: isConnected ? "--" : "--",
                    label: "Upload"
                )

                divider

                statItem(
                    icon: "clock",
                    value: isConnected ? uptimeString : "--:--",
                    label: "Duration"
                )
            }
        }
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: VPNSpacing.xs) {
            HStack(spacing: VPNSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.vpnTextTertiary)

                Text(value)
                    .vpnTextStyle(.sectionHeader)
            }

            Text(label)
                .vpnTextStyle(.statusBadge, color: .vpnTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.vpnBorder.opacity(0.5))
            .frame(width: 1, height: 32)
    }

    private var uptimeString: String {
        guard let connectedDate else { return "--:--" }
        let interval = Date().timeIntervalSince(connectedDate)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ZStack {
        Color.vpnBackground.ignoresSafeArea()

        VStack(spacing: VPNSpacing.md) {
            QuickStatsRow(isConnected: true, connectedDate: Date().addingTimeInterval(-3672))
            QuickStatsRow(isConnected: false, connectedDate: nil)
        }
        .padding()
    }
}
