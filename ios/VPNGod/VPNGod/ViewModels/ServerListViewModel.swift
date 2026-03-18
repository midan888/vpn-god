import Foundation

@MainActor
@Observable
final class ServerListViewModel {
    private(set) var servers: [Server] = []
    private(set) var isLoading = false
    var error: String?
    var showError = false

    func loadServers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            servers = try await APIClient.shared.getServers()
        } catch let apiError as APIError {
            error = apiError.errorDescription
            showError = true
        } catch {
            self.error = "Failed to load servers."
            showError = true
        }
    }
}
