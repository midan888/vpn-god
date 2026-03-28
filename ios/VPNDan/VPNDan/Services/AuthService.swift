import Foundation

@MainActor
@Observable
final class AuthService {
    static let shared = AuthService()

    private(set) var isAuthenticated = false
    private(set) var userEmail: String?
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var isCodeSent = false
    private(set) var pendingEmail: String?

    private init() {}

    // MARK: - Session Check

    func checkSession() async {
        isLoading = true
        defer { isLoading = false }

        // Try silent refresh if we have a refresh token
        guard let refreshToken = KeychainService.getRefreshToken() else {
            isAuthenticated = false
            return
        }

        do {
            let response = try await APIClient.shared.refresh(token: refreshToken)
            KeychainService.saveTokens(access: response.accessToken, refresh: response.refreshToken)
            userEmail = KeychainService.getEmail()
            isAuthenticated = true
        } catch {
            KeychainService.clearTokens()
            isAuthenticated = false
        }
    }

    // MARK: - Passwordless Auth

    func sendCode(email: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            _ = try await APIClient.shared.sendCode(email: email)
            pendingEmail = email
            isCodeSent = true
        } catch let apiError as APIError {
            self.error = apiError.errorDescription
        } catch {
            self.error = "An unexpected error occurred."
        }
    }

    func verifyCode(code: String) async {
        guard let email = pendingEmail else { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await APIClient.shared.verifyCode(email: email, code: code)
            KeychainService.saveTokens(access: response.accessToken, refresh: response.refreshToken)
            KeychainService.saveEmail(email)
            userEmail = email
            isAuthenticated = true
            isCodeSent = false
            pendingEmail = nil
        } catch let apiError as APIError {
            self.error = apiError.errorDescription
        } catch {
            self.error = "An unexpected error occurred."
        }
    }

    func goBackToEmail() {
        isCodeSent = false
        error = nil
    }

    func logout() {
        KeychainService.clearTokens()
        userEmail = nil
        isAuthenticated = false
        isCodeSent = false
        pendingEmail = nil
    }

    func clearError() {
        error = nil
    }
}
