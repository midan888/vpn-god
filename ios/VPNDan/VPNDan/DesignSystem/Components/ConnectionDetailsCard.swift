import SwiftUI

struct ConnectionDetailsCard: View {
    let isConnected: Bool
    let connectedDate: Date?
    let bytesReceived: UInt64
    let bytesSent: UInt64
    let ip: String?
    let location: String?
    let latencyMs: Int?

    @AppStorage("connectionDetailsExpanded") private var isExpanded = false

    private var quality: LatencyQuality? {
        guard isConnected, let ms = latencyMs else { return nil }
        return LatencyQuality(ms: ms)
    }

    var body: some View {
        GlassCard(padding: 0) {
            VStack(spacing: 0) {
                // Header — always visible
                header
                    .padding(.horizontal, VPNSpacing.md)
                    .padding(.vertical, VPNSpacing.sm + VPNSpacing.xs)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isExpanded.toggle()
                        }
                    }

                // Expanded content
                if isExpanded {
                    Divider()
                        .overlay(Color.vpnBorder.opacity(0.5))

                    // Connection quality row
                    if isConnected {
                        qualityRow
                            .padding(.horizontal, VPNSpacing.md)
                            .padding(.vertical, VPNSpacing.sm + VPNSpacing.xs)

                        Divider()
                            .overlay(Color.vpnBorder.opacity(0.5))
                    }

                    statsRow
                        .padding(.horizontal, VPNSpacing.md)
                        .padding(.vertical, VPNSpacing.sm + VPNSpacing.xs)

                    Divider()
                        .overlay(Color.vpnBorder.opacity(0.5))

                    ipRow
                        .padding(.horizontal, VPNSpacing.md)
                        .padding(.vertical, VPNSpacing.sm + VPNSpacing.xs)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: VPNSpacing.sm) {
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.vpnTextTertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))

            if isConnected, let quality {
                SignalBars(quality: quality, size: .compact)
                    .frame(width: 20, height: 14)

                Text(quality.label)
                    .vpnTextStyle(.caption, color: quality.color)
            } else {
                Text("Connection details")
                    .vpnTextStyle(.caption, color: .vpnTextSecondary)
            }

            Spacer()

            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                Text(isConnected ? uptimeString(at: context.date) : "--:--")
                    .vpnTextStyle(.caption, color: .vpnTextTertiary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Connection Quality Row

    private var qualityRow: some View {
        HStack(spacing: VPNSpacing.md) {
            SignalBars(quality: quality)
                .frame(width: 36, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                if let ms = latencyMs {
                    Text("\(ms) ms")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(quality?.color ?? Color.vpnTextTertiary)
                } else {
                    Text("-- ms")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.vpnTextTertiary)
                }
                Text("Connection Quality")
                    .vpnTextStyle(.caption, color: .vpnTextTertiary)
            }
            .contentTransition(.numericText())

            Spacer()

            if let quality {
                Image(systemName: quality.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(quality.color)
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(
                icon: "arrow.down",
                value: isConnected ? formatBytes(bytesReceived) : "--",
                label: "Download"
            )

            statDivider

            statItem(
                icon: "arrow.up",
                value: isConnected ? formatBytes(bytesSent) : "--",
                label: "Upload"
            )

            statDivider

            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                statItem(
                    icon: "clock",
                    value: isConnected ? uptimeString(at: context.date) : "--:--",
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

    private var statDivider: some View {
        Rectangle()
            .fill(Color.vpnBorder.opacity(0.5))
            .frame(width: 1, height: 32)
    }

    // MARK: - IP Row

    private var ipRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: VPNSpacing.xs) {
                Text("Your IP")
                    .vpnTextStyle(.caption, color: .vpnTextTertiary)

                Text(ip ?? "Not connected")
                    .vpnTextStyle(.sectionHeader, color: ip != nil ? .vpnTextPrimary : .vpnTextTertiary)

                if let location {
                    Text(location)
                        .vpnTextStyle(.caption, color: .vpnTextSecondary)
                }
            }

            Spacer()

            Image(systemName: ip != nil ? "lock.shield.fill" : "lock.shield")
                .font(.system(size: 24))
                .foregroundStyle(ip != nil ? Color.vpnConnected : Color.vpnTextTertiary)
                .symbolRenderingMode(.hierarchical)
        }
    }

    // MARK: - Formatting

    private func uptimeString(at now: Date) -> String {
        guard let connectedDate else { return "--:--" }
        let interval = now.timeIntervalSince(connectedDate)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        if bytes == 0 { return "0 B" }
        let units = ["B", "KB", "MB", "GB"]
        var value = Double(bytes)
        var unitIndex = 0
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        if unitIndex == 0 {
            return String(format: "%.0f %@", value, units[unitIndex])
        }
        return String(format: "%.1f %@", value, units[unitIndex])
    }
}

#Preview {
    ZStack {
        Color.vpnBackground.ignoresSafeArea()

        VStack(spacing: VPNSpacing.md) {
            ConnectionDetailsCard(
                isConnected: true,
                connectedDate: Date().addingTimeInterval(-3672),
                bytesReceived: 15_400_000,
                bytesSent: 2_300_000,
                ip: "185.243.112.47",
                location: "New York, US",
                latencyMs: 32
            )

            ConnectionDetailsCard(
                isConnected: false,
                connectedDate: nil,
                bytesReceived: 0,
                bytesSent: 0,
                ip: nil,
                location: nil,
                latencyMs: nil
            )
        }
        .padding()
    }
}
