import Foundation

struct HourlyForecast: Identifiable {
    let id = UUID()
    let hour: String
    let temp: Int
    let icon: String
}

struct DailyForecast: Identifiable {
    let id = UUID()
    let day: String
    let icon: String
    let minTemp: Int
    let maxTemp: Int
}
