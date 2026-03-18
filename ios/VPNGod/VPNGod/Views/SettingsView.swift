import SwiftUI

struct SettingsView: View {
    @Environment(AuthService.self) private var auth
    @Environment(VPNManager.self) private var vpn
    @State private var showLogoutConfirmation = false

    var body: some View {
        List {
            Section("Account") {
                if let email = auth.userEmail {
                    LabeledContent("Email", value: email)
                }
            }

            Section {
                Button("Logout", role: .destructive) {
                    showLogoutConfirmation = true
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Logout", isPresented: $showLogoutConfirmation) {
            Button("Logout", role: .destructive) {
                Task {
                    if vpn.status == .connected {
                        try? await vpn.disconnect()
                    }
                    auth.logout()
                }
            }
        } message: {
            if vpn.status == .connected {
                Text("You are currently connected to a VPN. Logging out will disconnect you.")
            } else {
                Text("Are you sure you want to logout?")
            }
        }
    }
}
