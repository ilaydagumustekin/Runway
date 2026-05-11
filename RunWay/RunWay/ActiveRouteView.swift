import Combine
import CoreLocation
import MapKit
import SwiftUI

struct ActiveRouteView: View {
    @Binding var selectedTab: Tab

    @ObservedObject private var routeOverlay = RouteOverlayStore.shared
    @ObservedObject private var locationManager = AppLocationManager.shared
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var navigationRoute: MKRoute?

    @State private var mode: TravelMode = .walk
    @State private var cameraFollowing: Bool = true

    // Navigation progress
    @State private var remainingDistanceKm: Double = 0
    @State private var remainingDurationMin: Int = 0
    @State private var nextInstructionText: String = "Rota başlıyor"
    @State private var nextInstructionText2: String = ""
    @State private var nextInstructionDistanceM: Double = 0
    @State private var arrivalTimeText: String = ""

    private var hasRoute: Bool { routeOverlay.destinationCoordinate != nil }

    // MARK: - Body

    var body: some View {
        Group {
            if hasRoute {
                navigationContent
                    .toolbar(.hidden, for: .tabBar)
            } else {
                noRoutePlaceholder
            }
        }
        .onAppear {
            AppLocationManager.shared.requestPermission()
            AppLocationManager.shared.startUpdating()
        }
    }

    // MARK: - Navigation Content

    private var navigationContent: some View {
        ZStack {
            activeRouteMap
                .ignoresSafeArea()

            VStack(spacing: 0) {
                directionBanner
                Spacer()
            }

            floatingButtons

            bottomSheet
        }
        .onAppear {
            initNavigationState()
            updateMapCamera()
            Task { await buildMapKitNavigationRouteIfPossible() }
        }
        .onChange(of: routeOverlay.pathCoordinates.count) { _, _ in
            initNavigationState()
            updateMapCamera()
            Task { await buildMapKitNavigationRouteIfPossible() }
        }
        .onChange(of: mode) { _, newMode in
            recalculateDurationForMode(newMode)
        }
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { location in
            updateNavigationProgress(userLocation: location)
            if cameraFollowing { followUser(location) }
        }
    }

    // MARK: - No Route Placeholder

    private var noRoutePlaceholder: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "map")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            VStack(spacing: 8) {
                Text("Rota seçilmedi")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("Ana sayfadan bir hedef seçerek rota önerisi alın.")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Button { selectedTab = .home } label: {
                Text("Ana Sayfaya Dön")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            Spacer()
        }
    }

    // MARK: - Map

    private var activeRouteMap: some View {
        Map(position: $mapPosition) {
            if let navigationRoute {
                MapPolyline(navigationRoute.polyline)
                    .stroke(Color.blue.opacity(0.92), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            } else if routeOverlay.pathCoordinates.count >= 2 {
                MapPolyline(coordinates: routeOverlay.pathCoordinates)
                    .stroke(Color.green.opacity(0.92), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))

                if let start = routeOverlay.pathCoordinates.first {
                    Annotation("", coordinate: start) {
                        Circle().fill(Color.blue).frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }
                if let end = routeOverlay.pathCoordinates.last {
                    Annotation(routeOverlay.destinationName, coordinate: end) {
                        ZStack {
                            Circle().fill(Color.red).frame(width: 32, height: 32).shadow(radius: 3)
                            Image(systemName: "mappin.fill")
                                .font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                        }
                    }
                }
            } else if let dest = routeOverlay.destinationCoordinate {
                Annotation(routeOverlay.destinationName, coordinate: dest) {
                    ZStack {
                        Circle().fill(Color.red).frame(width: 32, height: 32).shadow(radius: 3)
                        Image(systemName: "mappin.fill")
                            .font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    // MARK: - Direction Banner

    private var directionBanner: some View {
        VStack(spacing: 0) {
            // Primary instruction card
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(instructionColor.opacity(0.12))
                        .frame(width: 54, height: 54)
                    Image(systemName: instructionIcon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(instructionColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(nextInstructionDistanceM > 0 ? formatDistance(nextInstructionDistanceM) : "—")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(nextInstructionText)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button { selectedTab = .home } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, nextInstructionText2.isEmpty ? 14 : 10)

            // Secondary "next" instruction
            if !nextInstructionText2.isEmpty {
                HStack(spacing: 10) {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 1, height: 18)
                        .padding(.leading, 83)
                    Text("Sonra: \(nextInstructionText2)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.bottom, 12)
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 14, y: 4)
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private var instructionIcon: String {
        switch nextInstructionText {
        case "Sağa dön":         return "arrow.turn.up.right"
        case "Sola dön":         return "arrow.turn.up.left"
        case "Geri dön":         return "arrow.uturn.backward"
        case "Hedefe ulaştınız": return "mappin.and.ellipse"
        default:                 return "arrow.up"
        }
    }

    private var instructionColor: Color {
        switch nextInstructionText {
        case "Hedefe ulaştınız": return .green
        case "Geri dön":         return .red
        default:                 return .blue
        }
    }

    // MARK: - Floating Buttons

    private var floatingButtons: some View {
        VStack {
            Spacer()
            floatingCircleButton(system: cameraFollowing ? "location.fill" : "location") {
                withAnimation { cameraFollowing.toggle() }
                if cameraFollowing, let loc = locationManager.lastLocation {
                    followUser(loc)
                } else {
                    updateMapCamera()
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 210)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func floatingCircleButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(Color.white.opacity(0.14))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 8)
    }

    // MARK: - Bottom Sheet

    private var bottomSheet: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)
                    .padding(.bottom, 16)

                // Duration + arrival
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .lastTextBaseline, spacing: 6) {
                            Text("\(remainingDurationMin)")
                                .font(.system(size: 38, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text("dk")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.70))
                                .padding(.bottom, 4)
                        }
                        Text(String(format: "%.1f km", remainingDistanceKm))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.70))
                    }

                    Spacer()

                    if !arrivalTimeText.isEmpty {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("varış")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.55))
                            Text(arrivalTimeText)
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)

                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                // Mode picker + exit
                HStack(spacing: 8) {
                    ForEach(TravelMode.allCases) { m in
                        Button { mode = m } label: {
                            HStack(spacing: 5) {
                                Image(systemName: m.icon)
                                    .font(.system(size: 12, weight: .bold))
                                Text(m.rawValue)
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                            }
                            .foregroundStyle(mode == m ? .black : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(mode == m ? Color.white : Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Button { selectedTab = .home } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                            Text("Çıkış")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 24)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.black.opacity(0.72))
            )
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Navigation Logic

    private func initNavigationState() {
        // Sync transport mode from RouteOverlayStore
        if let m = TravelMode.allCases.first(where: { $0.backendValue == routeOverlay.transportMode }) {
            mode = m
        }

        let path = routeOverlay.pathCoordinates
        let storedDist = routeOverlay.distanceKm

        let totalDist: Double
        if storedDist > 0 {
            totalDist = storedDist
        } else if path.count >= 2 {
            totalDist = pathDistanceKm(path)
        } else {
            totalDist = 0
        }

        remainingDistanceKm = totalDist
        remainingDurationMin = durationMin(distanceKm: totalDist, speed: mode.speedKmh)
        arrivalTimeText = formatArrivalTime(minutesFromNow: remainingDurationMin)
        nextInstructionText = path.isEmpty ? "Rota bekleniyor" : "Rota başlıyor"
        nextInstructionText2 = ""
        nextInstructionDistanceM = 0

        RunWayDebugLog.activeRoute(
            "init totalDist=\(String(format: "%.2f", totalDist))km" +
            " mode=\(mode.rawValue) duration=\(remainingDurationMin)min arrival=\(arrivalTimeText)"
        )
    }

    private func updateNavigationProgress(userLocation: CLLocation) {
        let path = routeOverlay.pathCoordinates
        guard path.count >= 2 else { return }

        RunWayDebugLog.activeRoute(
            "user location lat=\(String(format:"%.5f", userLocation.coordinate.latitude))" +
            " lon=\(String(format:"%.5f", userLocation.coordinate.longitude))"
        )

        // Nearest point index
        var nearestIdx = 0
        var nearestDist = Double.infinity
        for (i, coord) in path.enumerated() {
            let d = userLocation.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
            if d < nearestDist { nearestDist = d; nearestIdx = i }
        }

        // Remaining distance
        var remaining = 0.0
        for i in nearestIdx..<(path.count - 1) {
            remaining += haversineKm(path[i], path[i + 1])
        }
        remainingDistanceKm = max(0, remaining)
        remainingDurationMin = durationMin(distanceKm: remaining, speed: mode.speedKmh)
        arrivalTimeText = formatArrivalTime(minutesFromNow: remainingDurationMin)

        RunWayDebugLog.activeRoute(
            "remaining_distance_km=\(String(format:"%.2f", remaining))" +
            " remaining_duration_min=\(remainingDurationMin)"
        )

        // Primary instruction
        if nearestIdx + 1 < path.count {
            let nextCoord = path[nearestIdx + 1]
            nextInstructionDistanceM = userLocation.distance(
                from: CLLocation(latitude: nextCoord.latitude, longitude: nextCoord.longitude)
            )
            let pathBearing = bearingDegrees(from: path[nearestIdx], to: nextCoord)
            nextInstructionText = turnInstruction(pathBearing: pathBearing, userCourse: userLocation.course)
            // Secondary instruction (look ahead)
            nextInstructionText2 = computeNextInstruction(startingAfter: nearestIdx + 1, path: path)
        } else {
            nextInstructionText = "Hedefe ulaştınız"
            nextInstructionDistanceM = 0
            nextInstructionText2 = ""
        }

        RunWayDebugLog.activeRoute(
            "next_instruction=\(nextInstructionText)" +
            " next_instruction_distance_m=\(Int(nextInstructionDistanceM))"
        )
    }

    private func computeNextInstruction(startingAfter idx: Int, path: [CLLocationCoordinate2D]) -> String {
        guard idx + 1 < path.count else { return "" }
        let refBearing = bearingDegrees(from: path[idx], to: path[min(idx + 1, path.count - 1)])
        for i in (idx + 1)..<min(idx + 6, path.count - 1) {
            let b = bearingDegrees(from: path[i], to: path[i + 1])
            var diff = b - refBearing
            while diff < -180 { diff += 360 }
            while diff > 180 { diff -= 360 }
            if abs(diff) > 30 { return diff > 0 ? "Sağa dön" : "Sola dön" }
        }
        return ""
    }

    private func recalculateDurationForMode(_ newMode: TravelMode) {
        guard remainingDistanceKm > 0 else { return }
        remainingDurationMin = durationMin(distanceKm: remainingDistanceKm, speed: newMode.speedKmh)
        arrivalTimeText = formatArrivalTime(minutesFromNow: remainingDurationMin)
        RunWayDebugLog.activeRoute(
            "selected transport mode=\(newMode.rawValue) speed=\(newMode.speedKmh)km/h" +
            " remaining_duration_min=\(remainingDurationMin)"
        )
    }

    private func followUser(_ location: CLLocation) {
        let heading = location.course >= 0 ? location.course : 0
        withAnimation(.easeInOut(duration: 0.6)) {
            mapPosition = .camera(
                MapCamera(centerCoordinate: location.coordinate, distance: 700, heading: heading, pitch: 40)
            )
        }
        RunWayDebugLog.activeRoute("camera follow updated heading=\(Int(heading))")
    }

    // MARK: - Geo Helpers

    private func pathDistanceKm(_ coords: [CLLocationCoordinate2D]) -> Double {
        var total = 0.0
        for i in 0..<(coords.count - 1) { total += haversineKm(coords[i], coords[i + 1]) }
        return total
    }

    private func haversineKm(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let R = 6371.0
        let lat1 = a.latitude * .pi / 180, lat2 = b.latitude * .pi / 180
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let x = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return R * 2 * atan2(sqrt(x), sqrt(1 - x))
    }

    private func bearingDegrees(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let lat1 = a.latitude * .pi / 180, lat2 = b.latitude * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }

    private func turnInstruction(pathBearing: Double, userCourse: Double) -> String {
        guard userCourse >= 0 else { return "Düz devam et" }
        var diff = pathBearing - userCourse
        while diff < -180 { diff += 360 }
        while diff > 180 { diff -= 360 }
        if abs(diff) <= 20 { return "Düz devam et" }
        if diff > 20 && diff < 160 { return "Sağa dön" }
        if diff < -20 && diff > -160 { return "Sola dön" }
        return "Geri dön"
    }

    private func durationMin(distanceKm: Double, speed: Double) -> Int {
        guard speed > 0 else { return 1 }
        return max(1, Int((distanceKm / speed * 60).rounded()))
    }

    private func formatArrivalTime(minutesFromNow: Int) -> String {
        Date().addingTimeInterval(TimeInterval(minutesFromNow * 60))
            .formatted(date: .omitted, time: .shortened)
    }

    private func formatDistance(_ meters: Double) -> String {
        meters >= 1000
            ? String(format: "%.1f km", meters / 1000)
            : "\(Int(meters)) m"
    }

    // MARK: - Map Camera

    private func updateMapCamera() {
        if let route = navigationRoute {
            mapPosition = .region(MKCoordinateRegion(route.polyline.boundingMapRect))
            return
        }
        let coords = routeOverlay.pathCoordinates
        if coords.count >= 2 {
            mapPosition = .region(Self.regionFitting(coordinates: coords))
        } else if let dest = routeOverlay.destinationCoordinate,
                  let user = locationManager.lastLocation?.coordinate {
            let dLat = max(0.025, abs(user.latitude - dest.latitude) * 1.8)
            let dLon = max(0.025, abs(user.longitude - dest.longitude) * 1.8)
            mapPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: (user.latitude + dest.latitude) / 2,
                    longitude: (user.longitude + dest.longitude) / 2
                ),
                span: MKCoordinateSpan(latitudeDelta: dLat, longitudeDelta: dLon)
            ))
        } else if let user = locationManager.lastLocation?.coordinate {
            mapPosition = .region(
                MKCoordinateRegion(center: user, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            )
        } else {
            mapPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7648, longitude: 30.5566),
                span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
            ))
        }
    }

    private static func regionFitting(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0
        for c in coordinates {
            minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(
                latitudeDelta: max(0.012, (maxLat - minLat) * 1.8),
                longitudeDelta: max(0.012, (maxLon - minLon) * 1.8)
            )
        )
    }

    private func buildMapKitNavigationRouteIfPossible() async {
        guard
            let destination = routeOverlay.destinationCoordinate,
            let userCoord = locationManager.lastLocation?.coordinate
        else { return }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userCoord))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking

        do {
            let response = try await MKDirections(request: request).calculate()
            navigationRoute = response.routes.first
            if !cameraFollowing { updateMapCamera() }
        } catch {
            navigationRoute = nil
        }
    }
}

// MARK: - Preview

#Preview {
    ActiveRouteView(selectedTab: .constant(.activeRoute))
        .preferredColorScheme(.dark)
}
