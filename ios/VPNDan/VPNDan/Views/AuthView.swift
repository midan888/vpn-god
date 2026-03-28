import SwiftUI

struct AuthView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        ZStack {
            // Background
            Color.vpnBackground.ignoresSafeArea()

            // Gradient orb
            RadialGradient(
                colors: [Color.vpnPrimary.opacity(0.2), Color.clear],
                center: .top,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: VPNSpacing.xl) {
                    // Logo
                    VStack(spacing: VPNSpacing.sm) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.vpnPrimaryGradient)

                        Text(L10n.Auth.appName)
                            .font(.system(size: 32, weight: .bold, design: .default))
                            .foregroundStyle(Color.vpnTextPrimary)
                    }
                    .padding(.top, 60)

                    // Form
                    Group {
                        if auth.isCodeSent {
                            CodeEntryFormView()
                        } else {
                            EmailFormView()
                        }
                    }
                    .padding(.horizontal, VPNSpacing.xl)
                    .animation(.easeInOut(duration: 0.25), value: auth.isCodeSent)
                }
                .padding(.bottom, VPNSpacing.xxl)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

// MARK: - Email Form

struct EmailFormView: View {
    @State private var viewModel = LoginViewModel()
    @Environment(AuthService.self) private var auth
    @State private var shakeError = false

    var body: some View {
        VStack(spacing: VPNSpacing.md) {
            // Error message
            if let error = auth.error {
                errorBanner(error)
            }

            Text(L10n.Auth.enterEmail)
                .vpnTextStyle(.caption, color: .vpnTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VPNTextField(
                placeholder: L10n.Auth.email,
                text: $viewModel.email,
                textContentType: .emailAddress,
                keyboardType: .emailAddress
            )

            // Continue button
            GradientButton(
                title: L10n.Auth.continueButton,
                isLoading: auth.isLoading,
                isDisabled: !viewModel.isEmailValid
            ) {
                Task { await auth.sendCode(email: viewModel.email) }
            }
            .padding(.top, VPNSpacing.sm)
        }
        .modifier(ShakeModifier(shakes: shakeError ? 2 : 0))
        .onChange(of: auth.error) { _, newError in
            if newError != nil {
                withAnimation(.default) { shakeError = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { shakeError = false }
            }
        }
        .onDisappear { auth.clearError() }
    }
}

// MARK: - Code Entry Form

struct CodeEntryFormView: View {
    @State private var viewModel = LoginViewModel()
    @Environment(AuthService.self) private var auth
    @State private var shakeError = false

    var body: some View {
        VStack(spacing: VPNSpacing.md) {
            // Error message
            if let error = auth.error {
                errorBanner(error)
            }

            VStack(spacing: VPNSpacing.xs) {
                Text(L10n.Auth.checkEmail)
                    .vpnTextStyle(.caption, color: .vpnTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let email = auth.pendingEmail {
                    Text(email)
                        .vpnTextStyle(.caption, color: .vpnTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            VPNTextField(
                placeholder: L10n.Auth.codePlaceholder,
                text: $viewModel.code,
                textContentType: .oneTimeCode,
                keyboardType: .numberPad
            )

            // Verify button
            GradientButton(
                title: L10n.Auth.verifyCode,
                isLoading: auth.isLoading,
                isDisabled: !viewModel.isCodeValid
            ) {
                Task { await auth.verifyCode(code: viewModel.code) }
            }
            .padding(.top, VPNSpacing.sm)

            // Resend / Back row
            HStack {
                Button {
                    auth.goBackToEmail()
                } label: {
                    Text(L10n.Auth.changeEmail)
                        .vpnTextStyle(.caption, color: .vpnPrimary)
                }

                Spacer()

                Button {
                    Task {
                        if let email = auth.pendingEmail {
                            await auth.sendCode(email: email)
                        }
                    }
                } label: {
                    Text(L10n.Auth.resendCode)
                        .vpnTextStyle(.caption, color: .vpnPrimary)
                }
            }
            .padding(.top, VPNSpacing.sm)
        }
        .modifier(ShakeModifier(shakes: shakeError ? 2 : 0))
        .onChange(of: auth.error) { _, newError in
            if newError != nil {
                withAnimation(.default) { shakeError = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { shakeError = false }
            }
        }
        .onDisappear { auth.clearError() }
    }
}

// MARK: - Shared Components

private func errorBanner(_ message: String) -> some View {
    HStack(spacing: VPNSpacing.sm) {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 14))
            .foregroundStyle(Color.vpnDisconnected)

        Text(message)
            .vpnTextStyle(.caption, color: .vpnDisconnected)
            .multilineTextAlignment(.leading)

        Spacer()
    }
    .padding(VPNSpacing.md)
    .background(
        RoundedRectangle(cornerRadius: VPNRadius.small)
            .fill(Color.vpnDisconnected.opacity(0.1))
    )
    .overlay(
        RoundedRectangle(cornerRadius: VPNRadius.small)
            .stroke(Color.vpnDisconnected.opacity(0.3), lineWidth: 1)
    )
    .transition(.opacity.combined(with: .move(edge: .top)))
}

// MARK: - Shake Animation Modifier

struct ShakeModifier: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: 8 * sin(shakes * .pi * 2), y: 0)
        )
    }
}

#Preview {
    AuthView()
        .environment(AuthService.shared)
}
