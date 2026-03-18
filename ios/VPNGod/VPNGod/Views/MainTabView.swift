import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: VPNTab = .home
    @Environment(VPNManager.self) private var vpn

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .servers:
                    ServersView(onServerSelected: { server in
                        connectToServer(server)
                        selectedTab = .home
                    })
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tab bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }

    private func connectToServer(_ server: Server) {
        Task {
            if vpn.status == .connected {
                try? await vpn.disconnect()
            }
            try? await vpn.connect(server: server)
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthService.shared)
        .environment(VPNManager.shared)
}
