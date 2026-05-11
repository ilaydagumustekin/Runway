import SwiftUI

struct AuthGateView: View {
    @EnvironmentObject private var authSession: AuthSession

    @State private var selectedMode: AuthMode = .login
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""

    enum AuthMode: String, CaseIterable, Identifiable {
        case login = "Giriş Yap"
        case register = "Kayıt Ol"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("RunWay")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                    Text("Hesabınla giriş yap veya yeni hesap oluştur.")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Auth Mode", selection: $selectedMode) {
                    ForEach(AuthMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    if selectedMode == .register {
                        TextField("Ad Soyad", text: $fullName)
                            .textInputAutocapitalization(.words)
                    }

                    TextField("E-posta", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)

                    SecureField("Şifre", text: $password)
                }
                .textFieldStyle(.roundedBorder)

                if let authErrorMessage = authSession.authErrorMessage, !authErrorMessage.isEmpty {
                    Text(authErrorMessage)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task {
                        switch selectedMode {
                        case .login:
                            _ = await authSession.login(email: email, password: password)
                        case .register:
                            _ = await authSession.register(
                                fullName: fullName,
                                email: email,
                                password: password
                            )
                        }
                    }
                } label: {
                    HStack {
                        if authSession.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(selectedMode.rawValue)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(authSession.isLoading || !isFormValid)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Hesap")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var isFormValid: Bool {
        if selectedMode == .register {
            return !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                email.contains("@") &&
                password.count >= 6
        }
        return email.contains("@") && password.count >= 6
    }
}

#Preview {
    AuthGateView()
        .environmentObject(AuthSession.shared)
}
