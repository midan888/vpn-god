import SwiftUI

struct HomeView: View {
    @Environment(VPNManager.self) private var vpn
    @State private var viewModel = ServerListViewModel.shared
    @State private var latency = LatencyService.shared
    @State private var showServerSheet = false
    @State private var selectedServer: Server?
    @State private var error: String?
    @State private var showError = false

    var body: some View {
        ZStack {
            // Background
            backgroundView

            // Content
            VStack(spacing: VPNSpacing.lg) {
                if viewModel.isLoading && viewModel.servers.isEmpty {
                    // Skeleton loading
                    SkeletonServerCard()
                    Spacer().frame(height: VPNSpacing.sm)
                    PowerButton(status: .disconnected) {}
                        .disabled(true)
                        .opacity(0.5)
                    Spacer().frame(height: VPNSpacing.sm)
                    SkeletonConnectionDetails()
                } else if viewModel.servers.isEmpty && viewModel.error != nil {
                    // Error state
                    Spacer().frame(height: VPNSpacing.xxl)
                    ErrorStateView(
                        message: L10n.Home.unableToLoadServers,
                        retryAction: { Task { await viewModel.loadServers() } }
                    )
                } else {
                    // Power button
                    PowerButton(status: vpn.status) {
                        handlePowerButtonTap()
                    }

                    // Status badge + text
                    VStack(spacing: VPNSpacing.sm) {
                        StatusBadge(status: vpn.status)

                        Text(statusMessage)
                            .vpnTextStyle(.body, color: .vpnTextSecondary)
                    }

                    Spacer()
                        .frame(height: VPNSpacing.xs)

                    // Server card
                    ServerCard(
                        server: displayServer,
                        latencyMs: displayServer.flatMap { latency.latency(for: $0.id) },
                        onChangeTapped: { showServerSheet = true }
                    )

                    // Connection details (expandable)
                    ConnectionDetailsCard(
                        isConnected: vpn.status == .connected,
                        connectedDate: vpn.connectedDate,
                        bytesReceived: vpn.bytesReceived,
                        bytesSent: vpn.bytesSent,
                        ip: vpn.publicIP,
                        location: vpn.status == .connected ? serverLocationString : nil,
                        latencyMs: latency.connectedLatency()
                    )
                }

                Spacer()
            }
            .padding(.horizontal, VPNSpacing.md)
            .safeAreaPadding(.top)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
        }
        .onChange(of: vpn.status) { oldStatus, newStatus in
            handleStatusChange(from: oldStatus, to: newStatus)
        }
        .sheet(isPresented: $showServerSheet) {
            ServerSelectionSheet(
                servers: viewModel.servers,
                selectedServerID: selectedServer?.id,
                connectedServerID: vpn.connectedServer?.id,
                onSelect: { server in selectServer(server) },
                onDismiss: { showServerSheet = false }
            )
        }
        .alert(L10n.Home.connectionError, isPresented: $showError) {
            Button(L10n.Common.ok) {}
        } message: {
            Text(error ?? "")
        }
        .task {
            async let serversTask: () = viewModel.loadServers()
            async let ipTask: () = vpn.fetchPublicIPOnLaunch()
            _ = await (serversTask, ipTask)
            // Auto-select first server if none selected
            if selectedServer == nil, let first = viewModel.servers.first(where: { $0.isActive }) {
                selectedServer = first
            }
            // If already connected, sync selected server
            if let connectedServer = vpn.connectedServer {
                selectedServer = connectedServer
            }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            Color.vpnBackground.ignoresSafeArea()

            // Gradient orb that changes with status
            RadialGradient(
                colors: [vpn.status.color.opacity(0.15), Color.clear],
                center: .center,
                startRadius: 20,
                endRadius: 300
            )
            .offset(y: -60)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.8), value: vpn.status)
        }
    }

    // MARK: - Computed Properties

    private var displayServer: Server? {
        vpn.connectedServer ?? selectedServer
    }

    private var statusMessage: String {
        switch vpn.status {
        case .connected: return L10n.Home.statusConnected
        case .connecting: return L10n.Home.statusConnecting
        case .disconnected: return L10n.Home.statusDisconnected
        case .disconnecting: return L10n.Home.statusDisconnecting
        }
    }

    private var serverLocationString: String? {
        guard let server = vpn.connectedServer else { return nil }
        return "\(server.name), \(server.country.uppercased())"
    }

    // MARK: - Actions

    private func handlePowerButtonTap() {
        triggerHaptic(for: vpn.status)

        Task {
            do {
                if vpn.status == .connected {
                    try await vpn.disconnect()
                } else if let server = selectedServer {
                    try await vpn.connect(server: server)
                } else {
                    showServerSheet = true
                }
            } catch let apiError as APIError {
                error = apiError.errorDescription
                showError = true
            } catch {
                self.error = L10n.Home.connectionFailed
                showError = true
            }
        }
    }

    private func selectServer(_ server: Server) {
        selectedServer = server
        showServerSheet = false

        // Auto-connect if currently disconnected
        if vpn.status == .disconnected {
            Task {
                do {
                    try await vpn.connect(server: server)
                } catch let apiError as APIError {
                    error = apiError.errorDescription
                    showError = true
                } catch {
                    self.error = L10n.Home.connectionFailed
                    showError = true
                }
            }
        } else if vpn.status == .connected {
            // Switch servers
            Task {
                do {
                    try await vpn.disconnect()
                    try await vpn.connect(server: server)
                } catch let apiError as APIError {
                    error = apiError.errorDescription
                    showError = true
                } catch {
                    self.error = L10n.Home.connectionFailed
                    showError = true
                }
            }
        }
    }

    // MARK: - Status Change Handling

    private func handleStatusChange(from oldStatus: VPNManager.VPNStatus, to newStatus: VPNManager.VPNStatus) {
        triggerHaptic(for: newStatus)
        latency.vpnConnected = newStatus == .connected
        if newStatus == .connected, let server = vpn.connectedServer {
            latency.startConnectedPing(server: server)
        } else if newStatus == .disconnected {
            latency.stopConnectedPing()
        }
    }

    // MARK: - Haptics

    private func triggerHaptic(for status: VPNManager.VPNStatus) {
        switch status {
        case .connected:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .disconnected:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .connecting:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .disconnecting:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

}

#Preview {
    HomeView()
        .environment(VPNManager.shared)
}
