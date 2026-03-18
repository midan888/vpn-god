import SwiftUI

@main
struct VPNGodApp: App {
    @State private var auth = AuthService.shared
    @State private var vpn = VPNManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isLoading {
                    ProgressView("Loading...")
                } else if auth.isAuthenticated {
                    HomeView()
                } else {
                    AuthView()
                }
            }
            .environment(auth)
            .environment(vpn)
            .task {
                await auth.checkSession()
                await vpn.syncStatus()
            }
        }
    }
}
