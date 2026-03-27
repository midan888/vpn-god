import SwiftUI

struct StatusBadge: View {
    let status: VPNManager.VPNStatus

    var body: some View {
        HStack(spacing: VPNSpacing.xs) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(status.color.opacity(0.4))
                        .frame(width: 16, height: 16)
                )

            Text(status.label)
                .vpnTextStyle(.statusBadge, color: status.color)
        }
        .padding(.horizontal, VPNSpacing.sm + VPNSpacing.xs)
        .padding(.vertical, VPNSpacing.xs + 2)
        .background(
            Capsule()
                .fill(status.color.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(status.color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityLabel(L10n.VPNStatus.accessibilityLabel(status.label))
    }
}

extension VPNManager.VPNStatus {
    var label: String {
        switch self {
        case .connected: return L10n.VPNStatus.protected
        case .connecting: return L10n.VPNStatus.connecting
        case .disconnected: return L10n.VPNStatus.notProtected
        case .disconnecting: return L10n.VPNStatus.disconnecting
        }
    }
}

#Preview {
    ZStack {
        Color.vpnBackground.ignoresSafeArea()

        VStack(spacing: VPNSpacing.md) {
            StatusBadge(status: .connected)
            StatusBadge(status: .connecting)
            StatusBadge(status: .disconnected)
            StatusBadge(status: .disconnecting)
        }
    }
}
