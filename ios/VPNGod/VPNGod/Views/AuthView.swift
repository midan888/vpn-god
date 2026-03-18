import SwiftUI

struct AuthView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Text("VPN God")
                .font(.largeTitle.bold())
                .padding(.top, 60)
                .padding(.bottom, 32)

            Picker("", selection: $selectedTab) {
                Text("Login").tag(0)
                Text("Register").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 32)

            TabView(selection: $selectedTab) {
                LoginView()
                    .tag(0)
                RegisterView()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Login View

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @Environment(AuthService.self) private var auth

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            if let error = auth.error {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            TextField("Email", text: $viewModel.email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)

            Button {
                Task { await auth.login(email: viewModel.email, password: viewModel.password) }
            } label: {
                if auth.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.isValid || auth.isLoading)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onDisappear { auth.clearError() }
    }
}

// MARK: - Register View

struct RegisterView: View {
    @State private var viewModel = RegisterViewModel()
    @Environment(AuthService.self) private var auth

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            if let error = auth.error {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            TextField("Email", text: $viewModel.email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.newPassword)

            SecureField("Confirm Password", text: $viewModel.confirmPassword)
                .textFieldStyle(.roundedBorder)
                .textContentType(.newPassword)

            if !viewModel.passwordsMatch && !viewModel.confirmPassword.isEmpty {
                Text("Passwords don't match")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await auth.register(email: viewModel.email, password: viewModel.password) }
            } label: {
                if auth.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.isValid || auth.isLoading)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onDisappear { auth.clearError() }
    }
}
