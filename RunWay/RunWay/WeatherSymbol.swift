import SwiftUI

// MARK: - Colorful Weather Symbol
struct WeatherSymbol: View {
    let name: String

    var body: some View {
        Image(systemName: name)
            .symbolRenderingMode(.palette)
            .foregroundStyle(primaryColor(for: name), secondaryColor(for: name))
    }

    private func primaryColor(for symbol: String) -> Color {
        switch symbol {
        case "sun.max.fill", "sun.max":
            return .yellow
        case "cloud.sun.fill", "cloud.sun":
            return .yellow
        case "cloud.moon.fill", "cloud.moon":
            return .yellow
        case "cloud.rain.fill", "cloud.rain", "cloud.drizzle.fill", "cloud.drizzle":
            return .blue
        case "cloud.snow.fill", "cloud.snow":
            return .cyan
        case "cloud.bolt.rain.fill", "cloud.bolt.rain":
            return .yellow
        case "wind":
            return .mint
        case "cloud.fill", "cloud":
            return .gray
        case "moon.stars.fill", "moon.stars":
            return .yellow
        default:
            return .blue
        }
    }

    private func secondaryColor(for symbol: String) -> Color {
        switch symbol {
        case "sun.max.fill", "sun.max":
            return .orange
        case "cloud.sun.fill", "cloud.sun":
            return .gray.opacity(0.9)
        case "cloud.moon.fill", "cloud.moon":
            return .gray.opacity(0.9)
        case "cloud.rain.fill", "cloud.rain", "cloud.drizzle.fill", "cloud.drizzle":
            return .gray.opacity(0.9)
        case "cloud.snow.fill", "cloud.snow":
            return .gray.opacity(0.9)
        case "cloud.bolt.rain.fill", "cloud.bolt.rain":
            return .blue
        case "wind":
            return .gray.opacity(0.7)
        case "cloud.fill", "cloud":
            return .gray.opacity(0.6)
        case "moon.stars.fill", "moon.stars":
            return .blue.opacity(0.9)
        default:
            return .gray.opacity(0.8)
        }
    }
}
