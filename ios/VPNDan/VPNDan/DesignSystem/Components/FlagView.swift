import SwiftUI

/// Displays a country flag image loaded from flagcdn.com.
/// Falls back to the country code text if the image fails to load.
struct FlagView: View {
    let countryCode: String
    var size: CGFloat = 32

    // flagcdn.com only serves these widths
    private static let supportedWidths = [20, 40, 80, 160, 320, 640, 1280, 2560]

    private var flagWidth: CGFloat { size }
    private var flagHeight: CGFloat { size * 0.75 }

    private var flagURL: URL? {
        let code = countryCode.lowercased()
        let desired = Int(size * 3) // 3x for retina
        let width = Self.supportedWidths.first { $0 >= desired } ?? Self.supportedWidths.last!
        return URL(string: "https://flagcdn.com/w\(width)/\(code).png")
    }

    var body: some View {
        AsyncImage(url: flagURL, transaction: Transaction(animation: .easeIn(duration: 0.15))) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                fallbackContent
            case .empty:
                fallbackContent
                    .opacity(0.5)
            @unknown default:
                fallbackContent
            }
        }
        .frame(width: flagWidth, height: flagHeight)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
    }

    private var fallbackContent: some View {
        Text(countryCode.uppercased())
            .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: flagWidth, height: flagHeight)
            .background(Color.vpnPrimary.opacity(0.3))
    }
}

#Preview {
    ZStack {
        Color.vpnBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            FlagView(countryCode: "US", size: 48)
            FlagView(countryCode: "GB", size: 36)
            FlagView(countryCode: "JP", size: 32)
            FlagView(countryCode: "DE", size: 24)
            FlagView(countryCode: "XX", size: 32) // fallback test
        }
    }
}
