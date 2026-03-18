import SwiftUI

extension Color {
    // MARK: - Backgrounds
    static let vpnBackground = Color(hex: 0x0A0E1A)
    static let vpnSurface = Color(hex: 0x141929)
    static let vpnSurfaceLight = Color(hex: 0x1E2438)
    static let vpnBorder = Color(hex: 0x2A3050)

    // MARK: - Accent
    static let vpnPrimary = Color(hex: 0x7B5EFF)
    static let vpnPrimaryLight = Color(hex: 0xA78BFA)
    static let vpnGradientStart = Color(hex: 0x7B5EFF)
    static let vpnGradientEnd = Color(hex: 0x00D4AA)

    // MARK: - Status
    static let vpnConnected = Color(hex: 0x00D4AA)
    static let vpnConnecting = Color(hex: 0xFFB800)
    static let vpnDisconnected = Color(hex: 0xFF4757)
    static let vpnInactive = Color(hex: 0x4A5068)

    // MARK: - Text
    static let vpnTextPrimary = Color.white
    static let vpnTextSecondary = Color(hex: 0x8B92A8)
    static let vpnTextTertiary = Color(hex: 0x5A6180)

    // MARK: - Gradients
    static var vpnPrimaryGradient: LinearGradient {
        LinearGradient(
            colors: [.vpnGradientStart, .vpnGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var vpnPrimaryGradientColors: [Color] {
        [.vpnGradientStart, .vpnGradientEnd]
    }

    // MARK: - Hex Init
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

// MARK: - VPN Status Color Mapping

extension VPNManager.VPNStatus {
    var color: Color {
        switch self {
        case .connected: return .vpnConnected
        case .connecting: return .vpnConnecting
        case .disconnected: return .vpnDisconnected
        case .disconnecting: return .vpnConnecting
        }
    }
}
