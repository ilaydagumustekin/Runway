import Combine
import CoreLocation
import Foundation

@MainActor
final class RouteOverlayStore: ObservableObject {
    static let shared = RouteOverlayStore()

    /// Son başarılı `POST /routes/recommend` cevabından gelen güzergâh (haritada gösterilir).
    @Published private(set) var pathCoordinates: [CLLocationCoordinate2D] = []
    @Published private(set) var routeTitle: String = ""
    @Published private(set) var destinationName: String = ""
    @Published private(set) var destinationCoordinate: CLLocationCoordinate2D?
    @Published private(set) var distanceKm: Double = 0
    @Published private(set) var environmentalScore: Double = 0
    @Published private(set) var transportMode: String = "walking"

    func setRoute(
        title: String,
        path: [CLLocationCoordinate2D],
        destinationName: String = "",
        destinationCoordinate: CLLocationCoordinate2D? = nil,
        distanceKm: Double = 0,
        environmentalScore: Double = 0,
        transportMode: String = "walking"
    ) {
        routeTitle = title
        pathCoordinates = path
        self.destinationName = destinationName
        self.destinationCoordinate = destinationCoordinate
        self.distanceKm = distanceKm
        self.environmentalScore = environmentalScore
        self.transportMode = transportMode
    }

    func clear() {
        routeTitle = ""
        pathCoordinates = []
        destinationName = ""
        destinationCoordinate = nil
        distanceKm = 0
        environmentalScore = 0
        transportMode = "walking"
    }
}
