//
//  TargetPickerView.swift
//  RunWay
//
//  Created by İlayda Gümüştekin on 22.02.2026.
//

import CoreLocation
import SwiftUI

// MARK: - Location Search Model

struct LocationSearchResult: Decodable, Identifiable, Hashable {
    var id: String { "\(name)-\(latitude)-\(longitude)" }
    let name: String
    let displayName: String
    let city: String?
    let district: String?
    let latitude: Double
    let longitude: Double
    let neighborhoodId: Int?
    let source: String

    enum CodingKeys: String, CodingKey {
        case name, city, district, latitude, longitude, source
        case displayName = "display_name"
        case neighborhoodId = "neighborhood_id"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Location Search Service

private enum LocationSearchService {
    static func search(query: String) async throws -> [LocationSearchResult] {
        try await APIClient.shared.get(
            path: "/location/search",
            queryItems: [URLQueryItem(name: "q", value: query)],
            token: nil
        )
    }
}

// MARK: - View

struct TargetPickerView: View {
    struct TargetOption: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D

        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(coordinate.latitude)
            hasher.combine(coordinate.longitude)
        }

        static func == (lhs: TargetOption, rhs: TargetOption) -> Bool {
            lhs.name == rhs.name &&
            lhs.coordinate.latitude == rhs.coordinate.latitude &&
            lhs.coordinate.longitude == rhs.coordinate.longitude
        }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchResults: [LocationSearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>? = nil

    let popular: [TargetOption] = [
        .init(name: "Merkez",       coordinate: .init(latitude: 37.7648, longitude: 30.5566)),
        .init(name: "Modernevler",  coordinate: .init(latitude: 37.7665, longitude: 30.5508)),
        .init(name: "Fatih",        coordinate: .init(latitude: 37.7725, longitude: 30.5438)),
        .init(name: "Çünür",        coordinate: .init(latitude: 37.7952, longitude: 30.5485)),
        .init(name: "Bahçelievler", coordinate: .init(latitude: 37.7678, longitude: 30.5566)),
    ]

    @State private var selectedTarget: TargetOption? = nil
    var onSelect: (TargetOption) -> Void

    private var displayedItems: [TargetOption] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return popular
        }
        return searchResults.map { TargetOption(name: $0.name, coordinate: $0.coordinate) }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {

                TextField("Hedef ara (mahalle/konum)", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.top, 8)
                    .onChange(of: searchText) { _, newValue in
                        handleSearchTextChange(newValue)
                    }

                if isSearching {
                    HStack(spacing: 8) {
                        ProgressView().scaleEffect(0.8)
                        Text("Aranıyor...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(searchText.trimmingCharacters(in: .whitespaces).isEmpty
                     ? "Popüler Mahalleler"
                     : "Arama Sonuçları")
                    .font(.headline)

                LazyVStack(spacing: 10) {
                    ForEach(displayedItems) { item in
                        Button {
                            selectedTarget = item
                            RunWayDebugLog.route(
                                "selected destination name=\(item.name)" +
                                " lat=\(item.coordinate.latitude)" +
                                " lon=\(item.coordinate.longitude)"
                            )
                        } label: {
                            HStack {
                                Text(item.name)
                                Spacer()
                                if selectedTarget == item {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }

                    if !searchText.trimmingCharacters(in: .whitespaces).isEmpty
                        && !isSearching
                        && searchResults.isEmpty {
                        Text("Sonuç bulunamadı.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }

                Spacer()

                Button {
                    if let selectedTarget {
                        RunWayDebugLog.route(
                            "route recommend destination" +
                            " lat=\(selectedTarget.coordinate.latitude)" +
                            " lon=\(selectedTarget.coordinate.longitude)"
                        )
                        onSelect(selectedTarget)
                        dismiss()
                    }
                } label: {
                    Text("Devam")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTarget == nil ? Color.gray.opacity(0.25) : Color.black.opacity(0.72))
                        .foregroundStyle(selectedTarget == nil ? Color.gray : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(selectedTarget == nil ? 0 : 0.25), radius: 8, y: 3)
                }
                .disabled(selectedTarget == nil)
            }
            .padding()
            .navigationTitle("Hedef Seç")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    // MARK: - Search

    private func handleSearchTextChange(_ query: String) {
        searchTask?.cancel()
        selectedTarget = nil

        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        RunWayDebugLog.route("query=\(trimmed)")

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }

            await MainActor.run { isSearching = true }

            do {
                let results = try await LocationSearchService.search(query: trimmed)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                    RunWayDebugLog.route("results count=\(results.count)")
                    for r in results {
                        RunWayDebugLog.route(
                            "result name=\(r.name)" +
                            " lat=\(r.latitude) lon=\(r.longitude)" +
                            " neighborhood_id=\(r.neighborhoodId.map(String.init) ?? "null")" +
                            " source=\(r.source)"
                        )
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }
}
