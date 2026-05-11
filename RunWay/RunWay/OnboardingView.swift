import SwiftUI
import CoreLocation
import AVFoundation

/// İlk açılış: uygulama akışı ve konum + mikrofon izinleri.
struct OnboardingView: View {
    @AppStorage("RunWay.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        (
            "leaf.circle.fill",
            "Mahalle Çevre Kalitesi",
            "Hava, yeşil alan ve gürültü verileriyle mahallenizin yaşanabilirlik skorunu görün."
        ),
        (
            "map.fill",
            "Akıllı Yürüyüş Rotası",
            "Daha temiz hava ve daha az gürültü için size uygun yürüyüş güzergâhı önerilir."
        ),
        (
            "waveform.circle.fill",
            "Veri ve Doğrulama",
            "Tahminler ve resmi göstergelerle (TÜİK vb.) sonuçlar zamanla güçlendirilecek."
        ),
    ]

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(
                        systemImage: pages[index].0,
                        title: pages[index].1,
                        text: pages[index].2
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    requestPermissionsAndFinish()
                }
            } label: {
                Text(page == pages.count - 1 ? "İzinleri ver ve başla" : "Devam")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func onboardingPage(systemImage: String, title: String, text: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: systemImage)
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(.green)
                .padding(.top, 40)

            Text(title)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
    }

    private func requestPermissionsAndFinish() {
        AppLocationManager.shared.requestPermission()
        AppLocationManager.shared.startUpdating()

        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { _ in
                DispatchQueue.main.async {
                    hasCompletedOnboarding = true
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { _ in
                DispatchQueue.main.async {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
}
