import Combine
import Foundation

/// Uygulama genelinde seçilen analiz mahallesi ve odak bilgisi.
@MainActor
final class AppSession: ObservableObject {
    /// Haritadan seçilen mahalle; `nil` ise dashboard GPS ile çözülür.
    @Published var manualNeighborhoodId: Int?
    @Published var manualNeighborhoodName: String?

    /// Son yüklenen analiz mahallesi (entegrasyon uçları için).
    @Published var currentAnalysisNeighborhoodId: Int?

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
}
