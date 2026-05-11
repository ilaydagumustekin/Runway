import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var authSession: AuthSession

    var body: some View {
        List {
            if let user = authSession.currentUser {
                Section("Hesap Bilgileri") {
                    infoRow(title: "Ad Soyad", value: user.fullName)
                    infoRow(title: "E-posta", value: user.email)
                    infoRow(title: "Rol", value: user.role)
                }
            } else {
                Section {
                    Text("Kullanıcı bilgisi yüklenemedi.")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    Task {
                        await authSession.logout()
                    }
                } label: {
                    Text("Çıkış Yap")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Hesabım")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await authSession.loadCurrentUserIfNeeded()
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        AccountView()
            .environmentObject(AuthSession.shared)
    }
}
