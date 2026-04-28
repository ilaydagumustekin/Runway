import SwiftUI

struct ActiveRouteView: View {
    @Binding var selectedTab: Tab

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
    }

    @State private var mode: TravelMode = .walk
    @State private var sheetExpanded: Bool = false

    var body: some View {
        ZStack {
            // Map full screen
            mapPlaceholder
                .ignoresSafeArea()

            // Top bar safe area içinde
            VStack(spacing: 0) {
                topNavBar
                Spacer()
            }

            // Floating buttons
            floatingButtons

            // Bottom sheet
            bottomSheet
        }
    }

    // MARK: - Map Placeholder

    private var mapPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.70),
                    Color.black.opacity(0.55),
                    Color.black.opacity(0.40)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                Path { p in
                    stride(from: 0.0, through: w, by: 36).forEach { x in
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: h))
                    }
                    stride(from: 0.0, through: h, by: 36).forEach { y in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: w, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
            }

            RouteCurve()
                .stroke(Color.green.opacity(0.85), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .padding(.horizontal, 24)
                .padding(.vertical, 140)
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 8)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        Circle().fill(Color.white.opacity(0.18)).frame(width: 58, height: 58)
                        Circle().fill(Color.white).frame(width: 44, height: 44)
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.75))
                    }
                    .padding(.trailing, 22)
                    .padding(.bottom, 280)
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topNavBar: some View {
        HStack(spacing: 12) {
            Button {
                // ana sayfaya dön
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
                    Image(systemName: "arrow.turn.up.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.95))
                    Text("150 m")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text("sonra sağa dön")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            Button {
                // options (şimdilik boş)
            } label: {
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

    // MARK: - Floating Buttons

    private var floatingButtons: some View {
        VStack(spacing: 10) {
            Spacer()

            VStack(spacing: 10) {
                floatingCircleButton(system: "scope") { }
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

                HStack(alignment: .center) {
                    HStack(spacing: 10) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 16, weight: .bold))
                        Text(mode.rawValue)
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(.white)

                    Spacer()

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
                .padding(.horizontal, 16)

                modePicker
                scoreCurve
                    .padding(.horizontal, 16)

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

    private var scoreCurve: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("myki değişim")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.75))
            }

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 64)

                ScoreLine()
                    .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .padding(.horizontal, 14)
                    .frame(height: 64)

                HStack {
                    Text("Başlangıçtan")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.70))
                    Spacer()
                    Text("80 puan")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.70))
                }
                .padding(.horizontal, 14)
            }

            HStack {
                Label("varış 4:11", systemImage: "mappin.and.ellipse")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Text("ortalama %60")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Text("OK")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
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
                detailChip(title: "Süre", value: "12 dk", icon: "clock")
                detailChip(title: "Mesafe", value: "1.8 km", icon: "point.topleft.down.curvedto.point.bottomright.up")
                detailChip(title: "Skor", value: "%60", icon: "gauge.with.dots.needle.50percent")
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
}

// MARK: - Shapes

private struct ScoreLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        p.move(to: CGPoint(x: 0, y: h * 0.62))
        p.addCurve(
            to: CGPoint(x: w * 0.55, y: h * 0.32),
            control1: CGPoint(x: w * 0.18, y: h * 0.70),
            control2: CGPoint(x: w * 0.35, y: h * 0.10)
        )
        p.addCurve(
            to: CGPoint(x: w, y: h * 0.55),
            control1: CGPoint(x: w * 0.72, y: h * 0.52),
            control2: CGPoint(x: w * 0.88, y: h * 0.72)
        )
        return p
    }
}

private struct RouteCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        p.move(to: CGPoint(x: w * 0.20, y: h * 0.90))
        p.addCurve(
            to: CGPoint(x: w * 0.65, y: h * 0.45),
            control1: CGPoint(x: w * 0.10, y: h * 0.70),
            control2: CGPoint(x: w * 0.40, y: h * 0.55)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.75, y: h * 0.25),
            control1: CGPoint(x: w * 0.86, y: h * 0.36),
            control2: CGPoint(x: w * 0.80, y: h * 0.30)
        )
        return p
    }
}

// MARK: - Preview

#Preview {
    ActiveRouteView(selectedTab: .constant(.activeRoute))
        .preferredColorScheme(.dark)
}
