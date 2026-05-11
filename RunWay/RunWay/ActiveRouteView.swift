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

    enum TravelMode: String, CaseIterable, Identifiable {
        case walk = "Yürüyüş"
        case bike = "Bisiklet"
        case scooter = "Scooter"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .walk: return "figure.walk"
            case .bike: return "bicycle"
            case .scooter: return "scooter"
            }
        }

        var speedKmh: Double {
            switch self { case .walk: return 5; case .bike: return 15; case .scooter: return 20 }
        }
    }

    @State private var mode: TravelMode = .walk
    @State private var sheetExpanded: Bool = false
    @State private var cameraFollowing: Bool = true

    // Navigation progress state
    @State private var remainingDistanceKm: Double = 0
    @State private var remainingDurationMin: Int = 0
    @State private var nextInstructionText: String = "Rota takip ediliyor"
    @State private var nextInstructionDistanceM: Double = 0
    @State private var arrivalTimeText: String = ""

    var body: some View {
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
            AppLocationManager.shared.requestPermission()
            AppLocationManager.shared.startUpdating()
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
            if cameraFollowing {
                followUser(location)
            }
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
                    Annotation("Başlangıç", coordinate: start) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }
                if let end = routeOverlay.pathCoordinates.last {
                    Annotation("Varış", coordinate: end) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }
            } else if let user = locationManager.lastLocation?.coordinate {
                Annotation("Konumun", coordinate: user) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.blue)
                        .shadow(radius: 4)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    // MARK: - Direction Banner

    private var directionBanner: some View {
        HStack(spacing: 12) {
            Button {
                selectedTab = .home
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: instructionIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.95))
                    Text(nextInstructionDistanceM > 0
                         ? (nextInstructionDistanceM >= 1000
                            ? String(format: "%.1f km", nextInstructionDistanceM / 1000)
                            : "\(Int(nextInstructionDistanceM)) m")
                         : "—")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text(nextInstructionText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            Button { } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial.opacity(0.25))
        .background(Color.black.opacity(0.25))
    }

    private var instructionIcon: String {
        switch nextInstructionText {
        case "Sağa dön":          return "arrow.turn.up.right"
        case "Sola dön":          return "arrow.turn.up.left"
        case "Geri dön":          return "arrow.uturn.backward"
        case "Hedefe ulaştınız":  return "mappin.and.ellipse"
        default:                  return "arrow.up"
        }
    }

    // MARK: - Floating Buttons

    private var floatingButtons: some View {
        VStack(spacing: 10) {
            Spacer()
            VStack(spacing: 10) {
                floatingCircleButton(system: cameraFollowing ? "location.fill" : "location") {
                    withAnimation { cameraFollowing.toggle() }
                    if cameraFollowing, let loc = locationManager.lastLocation {
                        followUser(loc)
                    } else if !cameraFollowing {
                        updateMapCamera()
                    }
                }
                floatingCircleButton(system: "map") { }
                floatingCircleButton(system: "bell") { }
            }
            .padding(.trailing, 16)
            .padding(.bottom, sheetExpanded ? 360 : 280)
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
            VStack(spacing: 12) {
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            sheetExpanded.toggle()
                        }
                    }

                routeSummaryRow

                modePicker

                warningRow

                if sheetExpanded {
                    expandedDetails
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer().frame(height: 14)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.black.opacity(0.68))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
    }

    private var routeSummaryRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: mode.icon)
                        .font(.system(size: 13, weight: .bold))
                    Text(mode.rawValue)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.75))

                HStack(spacing: 4) {
                    Text(String(format: "%.1f km", remainingDistanceKm))
                    Text("•").opacity(0.5)
                    Text("\(remainingDurationMin) dk")
                }
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                if !arrivalTimeText.isEmpty {
                    Label("varış \(arrivalTimeText)", systemImage: "mappin.and.ellipse")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        sheetExpanded.toggle()
                    }
                } label: {
                    Image(systemName: sheetExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(10)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private var modePicker: some View {
        HStack(spacing: 10) {
            ForEach(TravelMode.allCases) { m in
                Button {
                    mode = m
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: m.icon)
                            .font(.system(size: 14, weight: .bold))
                        Text(m.rawValue)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(mode == m ? .black : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(mode == m ? Color.white : Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private var warningRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.yellow)

            Text("Gürültülü alan olabilir")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    sheetExpanded = true
                }
            } label: {
                Text("Detay")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
    }

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rota Detayları")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                detailChip(title: "Süre", value: "\(remainingDurationMin) dk", icon: "clock")
                detailChip(
                    title: "Mesafe",
                    value: String(format: "%.1f km", remainingDistanceKm),
                    icon: "point.topleft.down.curvedto.point.bottomright.up"
                )
                detailChip(
                    title: "Skor",
                    value: routeOverlay.environmentalScore > 0
                        ? "%\(Int(routeOverlay.environmentalScore.rounded()))"
                        : "—",
                    icon: "gauge.with.dots.needle.50percent"
                )
            }

            Text("Notlar")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))

            VStack(alignment: .leading, spacing: 8) {
                bullet("Park içinden geçerse gürültü azalır.")
                bullet("Ana cadde yoğun saatlerde daha riskli olabilir.")
                bullet("Hava kalitesi iyi bölgeler tercih edildi.")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private func detailChip(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
                Text(value)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
        }
    }

    // MARK: - Navigation Logic

    private func initNavigationState() {
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
        nextInstructionDistanceM = 0

        RunWayDebugLog.activeRoute(
            "init totalDist=\(String(format: "%.2f", totalDist))km" +
            " mode=\(mode.rawValue) duration=\(remainingDurationMin)min arrival=\(arrivalTimeText)"
        )
    }

    private func updateNavigationProgress(userLocation: CLLocation) {
        let path = routeOverlay.pathCoordinates
        guard path.count >= 2 else { return }

        // Nearest point index on path
        var nearestIdx = 0
        var nearestDist = Double.infinity
        for (i, coord) in path.enumerated() {
            let d = userLocation.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
            if d < nearestDist { nearestDist = d; nearestIdx = i }
        }

        // Remaining distance from nearest index onward
        var remaining = 0.0
        for i in nearestIdx..<(path.count - 1) {
            remaining += haversineKm(path[i], path[i + 1])
        }
        remainingDistanceKm = max(0, remaining)
        remainingDurationMin = durationMin(distanceKm: remaining, speed: mode.speedKmh)
        arrivalTimeText = formatArrivalTime(minutesFromNow: remainingDurationMin)

        if nearestIdx + 1 < path.count {
            let nextCoord = path[nearestIdx + 1]
            nextInstructionDistanceM = userLocation.distance(
                from: CLLocation(latitude: nextCoord.latitude, longitude: nextCoord.longitude)
            )
            let pathBearing = bearingDegrees(from: path[nearestIdx], to: nextCoord)
            nextInstructionText = turnInstruction(pathBearing: pathBearing, userCourse: userLocation.course)
        } else {
            nextInstructionText = "Hedefe ulaştınız"
            nextInstructionDistanceM = 0
        }

        RunWayDebugLog.activeRoute(
            "progress idx=\(nearestIdx)/\(path.count)" +
            " remaining=\(String(format: "%.2f", remaining))km" +
            " duration=\(remainingDurationMin)min next=\(nextInstructionText)"
        )
    }

    private func recalculateDurationForMode(_ newMode: TravelMode) {
        guard remainingDistanceKm > 0 else { return }
        remainingDurationMin = durationMin(distanceKm: remainingDistanceKm, speed: newMode.speedKmh)
        arrivalTimeText = formatArrivalTime(minutesFromNow: remainingDurationMin)
        RunWayDebugLog.activeRoute(
            "mode=\(newMode.rawValue) speed=\(newMode.speedKmh)km/h" +
            " duration=\(remainingDurationMin)min arrival=\(arrivalTimeText)"
        )
    }

    private func followUser(_ location: CLLocation) {
        let heading = location.course >= 0 ? location.course : 0
        withAnimation(.easeInOut(duration: 0.6)) {
            mapPosition = .camera(
                MapCamera(centerCoordinate: location.coordinate, distance: 700, heading: heading, pitch: 40)
            )
        }
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
        let arrival = Date().addingTimeInterval(TimeInterval(minutesFromNow * 60))
        return arrival.formatted(date: .omitted, time: .shortened)
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
        } else if let user = locationManager.lastLocation?.coordinate {
            mapPosition = .region(
                MKCoordinateRegion(center: user, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            )
        } else {
            mapPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 37.7648, longitude: 30.5566),
                    span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
                )
            )
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
