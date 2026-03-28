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
    @FocusState private var isCodeFieldFocused: Bool

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

            // OTP digit boxes
            OTPCodeView(code: $viewModel.code, isFocused: $isCodeFieldFocused)

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
        .onAppear { isCodeFieldFocused = true }
        .onDisappear { auth.clearError() }
    }
}

// MARK: - OTP Code View

struct OTPCodeView: View {
    @Binding var code: String
    var isFocused: FocusState<Bool>.Binding
    private let digitCount = 6

    var body: some View {
        ZStack {
            // Hidden text field that captures keyboard input + autofill
            TextField("", text: $code)
                .focused(isFocused)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: code) { _, newValue in
                    // Filter to digits only and cap at 6
                    let filtered = String(newValue.filter(\.isWholeNumber).prefix(digitCount))
                    if filtered != newValue {
                        code = filtered
                    }
                }

            // Visual digit boxes
            HStack(spacing: VPNSpacing.sm) {
                ForEach(0..<digitCount, id: \.self) { index in
                    DigitBox(
                        digit: digit(at: index),
                        isActive: index == code.count && (isFocused.wrappedValue),
                        isFilled: index < code.count
                    )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused.wrappedValue = true
            }
        }
    }

    private func digit(at index: Int) -> String {
        guard index < code.count else { return "" }
        return String(code[code.index(code.startIndex, offsetBy: index)])
    }
}

// MARK: - Single Digit Box

private struct DigitBox: View {
    let digit: String
    let isActive: Bool
    let isFilled: Bool

    var body: some View {
        Text(digit)
            .font(.system(size: 24, weight: .semibold, design: .monospaced))
            .foregroundStyle(Color.vpnTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: VPNRadius.textField)
                    .fill(Color.vpnSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: VPNRadius.textField)
                    .stroke(
                        isActive ? Color.vpnPrimary : (isFilled ? Color.vpnPrimary.opacity(0.4) : Color.vpnBorder),
                        lineWidth: isActive ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isActive)
            .animation(.easeInOut(duration: 0.15), value: isFilled)
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
