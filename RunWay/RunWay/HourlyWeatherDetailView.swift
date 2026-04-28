import SwiftUI

struct HourlyWeatherDetailView: View {
    let cityName: String
    let neighborhoodName: String
    let currentTempText: String
    let currentDesc: String
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.35),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    header

                    sectionTitle("Saatlik Tahmin")
                    hourlyStrip

                    sectionTitle("10 Günlük Tahmin")
                    dailyList

                    Spacer().frame(height: 16)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Hava Durumu")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(neighborhoodName), \(cityName)")
                .font(.system(size: 20, weight: .bold, design: .rounded))

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(currentTempText)
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                Text(currentDesc)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Text("Bugün • Şu anki durum ve detaylı tahmin")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .padding(.horizontal, 4)
    }

    private var hourlyStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(hourly) { item in
                    VStack(spacing: 10) {
                        Text(item.hour)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)

                        WeatherSymbol(name: item.icon)
                            .font(.system(size: 22, weight: .semibold))

                        Text("\(item.temp)°")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                    }
                    .frame(width: 74, height: 110)
                    .background(Color(.systemBackground).opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.04), lineWidth: 1)
                    )
                }
            }
            .padding(.vertical, 2)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var dailyList: some View {
        VStack(spacing: 10) {
            ForEach(daily) { d in
                HStack(spacing: 12) {
                    Text(d.day)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(width: 70, alignment: .leading)

                    WeatherSymbol(name: d.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 26)

                    Spacer()

                    Text("\(d.minTemp)°")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)

                    Text("\(d.maxTemp)°")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color(.systemBackground).opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
