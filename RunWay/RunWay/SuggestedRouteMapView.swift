import SwiftUI
import MapKit
import CoreLocation
import Combine

struct SuggestedRouteMapView: View {
    let destinationName: String
    let destinationCoordinate: CLLocationCoordinate2D

    @ObservedObject private var locationManager = AppLocationManager.shared

    @State private var route: MKRoute?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isLoadingRoute = false
    @State private var errorText: String?

    var body: some View {
        ZStack(alignment: .top) {

            Map(position: $cameraPosition) {
                UserAnnotation()
                Marker(destinationName, coordinate: destinationCoordinate)

                if let route {
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 6)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .onAppear {
                locationManager.requestPermission()
                locationManager.startUpdating()
            }
            .onReceive(locationManager.$lastLocation.compactMap { $0 }) { loc in
                Task { await buildRoute(from: loc.coordinate) }
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Önerilen Rota")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                    Text(destinationName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isLoadingRoute {
                    ProgressView()
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 10)

            if let errorText {
                VStack {
                    Spacer()
                    Text(errorText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.bottom, 18)
                }
            }
        }
        .navigationTitle("Harita")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func buildRoute(from userCoord: CLLocationCoordinate2D) async {
        if isLoadingRoute { return }
        isLoadingRoute = true
        errorText = nil

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userCoord))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
        request.transportType = .walking

        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()

            guard let first = response.routes.first else {
                throw NSError(domain: "Route", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Rota bulunamadı."])
            }

            route = first
            zoomToRoute(first)

        } catch {
            errorText = "Rota alınamadı. Konum iznini kontrol et."
        }

        isLoadingRoute = false
    }

    private func zoomToRoute(_ route: MKRoute) {
        let rect = route.polyline.boundingMapRect
        let region = MKCoordinateRegion(rect)
        withAnimation(.easeInOut(duration: 0.3)) {
            cameraPosition = .region(region)
        }
    }
}
