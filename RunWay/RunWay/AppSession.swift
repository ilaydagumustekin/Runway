import Combine
import Foundation

/// Anasayfa `/dashboard/home` özeti; AQI `quick_metrics` iken yeşil mümkünse `/integrations/green-area-analysis` ile doldurulur (analiz sekmesiyle aynı).
struct DashboardQuickMetricsHint: Equatable {
    let neighborhoodId: Int
    let airQualityAqi: Double
    let greenAreaPercent: Double
}

/// Uygulama genelinde seçilen analiz mahallesi ve odak bilgisi.
@MainActor
final class AppSession: ObservableObject {
    /// Haritadan seçilen mahalle; `nil` ise dashboard GPS ile çözülür.
    @Published var manualNeighborhoodId: Int?
    @Published var manualNeighborhoodName: String?

    /// Son yüklenen analiz mahallesi (entegrasyon uçları için).
    @Published var currentAnalysisNeighborhoodId: Int?

    /// Son başarılı dashboard yüklemesinden özet AQI / yeşil (ML analiziyle aynı mahalle için gösterilir).
    @Published private(set) var dashboardQuickMetricsHint: DashboardQuickMetricsHint?

    func setManualNeighborhood(id: Int, name: String) {
        manualNeighborhoodId = id
        manualNeighborhoodName = name
        RunWayDebugLog.state("selectedNeighborhoodId (manual) updated to id=\(id) name=\(name)")
    }

    func clearManualSelection() {
        manualNeighborhoodId = nil
        manualNeighborhoodName = nil
        RunWayDebugLog.state("manual selectedNeighborhoodId cleared")
    }

    func updateAnalysisNeighborhood(id: Int?) {
        currentAnalysisNeighborhoodId = id
        RunWayDebugLog.state("currentAnalysisNeighborhoodId updated to \(id.map(String.init) ?? "nil")")
    }

    func setDashboardQuickMetricsHint(neighborhoodId: Int, airQualityAqi: Double, greenAreaPercent: Double) {
        guard neighborhoodId > 0 else {
            dashboardQuickMetricsHint = nil
            return
        }
        dashboardQuickMetricsHint = DashboardQuickMetricsHint(
            neighborhoodId: neighborhoodId,
            airQualityAqi: airQualityAqi,
            greenAreaPercent: greenAreaPercent
        )
    }

    func clearDashboardQuickMetricsHint() {
        dashboardQuickMetricsHint = nil
    }
}
