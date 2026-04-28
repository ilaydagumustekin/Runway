import SwiftUI

struct SettingsView: View {
    // MARK: - State (mock)
    @State private var locationEnabled = true
    @State private var micEnabled = true

    @State private var notificationsAllowed = true
    @State private var navInstantAlerts = true
    @State private var dailyRouteSuggestion = true
    @State private var dailySuggestionTime = Date()
    @State private var voiceEnabled = true

    @State private var airQualityThreshold = 80
    @State private var noiseThreshold = 70
    @State private var greenAreaThreshold = 20

    @State private var refreshIntervalIndex = 1 // 0: 5dk, 1: 15dk, 2: 30dk
    private let refreshOptions = [5, 15, 30]

    private var refreshText: String { "\(refreshOptions[refreshIntervalIndex]) dk" }
    
    private var dailySuggestionTimeText: String {
        dailySuggestionTime.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        NavigationStack {
            List {
                // İzinler
                Section("İzinler") {
                    ToggleRow(icon: "location.fill", title: "Konum", isOn: $locationEnabled)
                    ToggleRow(icon: "mic.fill", title: "Mikrofon", isOn: $micEnabled)
                }

                // Bildirimler (satıra tıkla -> detayda toggle)
                Section("Bildirimler") {
                    NavigationLink {
                        ToggleDetailView(
                            title: "Bildirimlere izin ver",
                            description: "Uygulama bildirim gönderebilsin.",
                            isOn: $notificationsAllowed
                        )
                    } label: {
                        TrailingStatusRow(title: "Bildirimlere izin ver", trailing: notificationsAllowed ? "Açık" : "Kapalı")
                    }

                    NavigationLink {
                        ToggleDetailView(
                            title: "Navigasyonda anlık uyarı",
                            description: "Rota sırasında anlık çevre uyarıları gösterilsin.",
                            isOn: $navInstantAlerts
                        )
                    } label: {
                        TrailingStatusRow(title: "Navigasyonda anlık uyarı", trailing: navInstantAlerts ? "Açık" : "Kapalı")
                    }

                    NavigationLink {
                        ToggleDetailView(
                            title: "Günlük rota önerisi",
                            description: "Her gün sana daha sağlıklı rota önerileri sunulsun.",
                            isOn: $dailyRouteSuggestion
                        )
                    } label: {
                        TrailingStatusRow(title: "Günlük rota önerisi", trailing: dailyRouteSuggestion ? "Açık" : "Kapalı")
                    }

                    NavigationLink {
                        DailyTimeDetailView(selectedTime: $dailySuggestionTime)
                    } label: {
                        TrailingStatusRow(
                            title: "Günlük öneri saati",
                            trailing: dailyRouteSuggestion ? dailySuggestionTimeText : "Kapalı"
                        )
                    }
                    .disabled(!dailyRouteSuggestion)

                    NavigationLink {
                        ToggleDetailView(
                            title: "Seslendirme",
                            description: "Navigasyon sırasında sesli yönlendirme kullan.",
                            isOn: $voiceEnabled
                        )
                    } label: {
                        TrailingStatusRow(title: "Seslendirme", trailing: voiceEnabled ? "Açık" : "Kapalı")
                    }
                }

                // Uyarı eşikleri
                Section("Uyarı Eşikleri") {
                    NavigationLink {
                        StepperDetailView(
                            title: "Hava kalitesi uyarısı",
                            subtitle: "AQI eşiğini belirle",
                            valueLabel: { "AQI \($0)" },
                            value: $airQualityThreshold,
                            range: 0...300,
                            step: 5
                        )
                    } label: {
                        TrailingStatusRow(title: "Hava kalitesi uyarısı", trailing: "AQI \(airQualityThreshold)")
                    }

                    NavigationLink {
                        StepperDetailView(
                            title: "Gürültü uyarısı",
                            subtitle: "dB eşiğini belirle",
                            valueLabel: { "\($0) dB" },
                            value: $noiseThreshold,
                            range: 30...120,
                            step: 1
                        )
                    } label: {
                        TrailingStatusRow(title: "Gürültü uyarısı", trailing: "\(noiseThreshold) dB")
                    }

                    NavigationLink {
                        StepperDetailView(
                            title: "Yeşil alan uyarısı",
                            subtitle: "Minimum yeşil alan yüzdesi",
                            valueLabel: { "%\($0)" },
                            value: $greenAreaThreshold,
                            range: 0...100,
                            step: 1
                        )
                    } label: {
                        TrailingStatusRow(title: "Yeşil alan uyarısı", trailing: "%\(greenAreaThreshold)")
                    }
                }

                // Otomatik veri yenileme
                Section {
                    NavigationLink {
                        RefreshIntervalDetailView(
                            options: refreshOptions,
                            selectedIndex: $refreshIntervalIndex
                        )
                    } label: {
                        TrailingStatusRow(title: "Otomatik veri yenileme", trailing: refreshText)
                    }
                }

                // Hakkında
                Section("Hakkında") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        TrailingStatusRow(title: "Sürüm", trailing: "1.0.0")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Reusable Rows

private struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(.primary)

            Toggle(title, isOn: $isOn)
        }
    }
}

private struct TrailingStatusRow: View {
    let title: String
    let trailing: String

    var body: some View {
        HStack {
            Text(title)
                .font(.body.weight(.semibold))
            Spacer()
            Text(trailing)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Detail Screens

private struct ToggleDetailView: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        List {
            Section {
                Toggle(isOn: $isOn) {
                    Text(title)
                        .font(.body.weight(.semibold))
                }
            }

            Section {
                Text(description)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StepperDetailView: View {
    let title: String
    let subtitle: String
    let valueLabel: (Int) -> String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(subtitle)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text(valueLabel(value))
                            .font(.title3.weight(.heavy))
                        Spacer()
                    }

                    Stepper(value: $value, in: range, step: step) {
                        Text("Değer")
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct RefreshIntervalDetailView: View {
    let options: [Int]
    @Binding var selectedIndex: Int

    var body: some View {
        List {
            Section("Otomatik veri yenileme") {
                ForEach(options.indices, id: \.self) { idx in
                    HStack {
                        Text("\(options[idx]) dk")
                        Spacer()
                        if idx == selectedIndex {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.bold))
                                .foregroundStyle(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedIndex = idx
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Otomatik yenileme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DailyTimeDetailView: View {
    @Binding var selectedTime: Date

    var body: some View {
        List {
            Section("Günlük öneri saati") {
                DatePicker("Saat", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Günlük öneri saati")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AboutView: View {
    var body: some View {
        List {
            Section("RunWay") {
                HStack {
                    Text("Sürüm")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text("100")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Hakkında")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}
