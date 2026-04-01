//
//  MapExampleView.swift
//  GlassKit
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Country Details

struct CountryDetails: Equatable {
    let name: String
    let isoCode: String
    let capital: String
    let region: String
    let population: Int
    let flag: String
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: CountryDetails, rhs: CountryDetails) -> Bool {
        lhs.isoCode == rhs.isoCode
    }
}

// MARK: - Geo Helpers

private func douglasPeucker(_ pts: [CLLocationCoordinate2D], epsilon: Double) -> [CLLocationCoordinate2D] {
    guard pts.count > 2 else { return pts }
    let start = pts.first!
    let end   = pts.last!
    var maxDist = 0.0
    var maxIdx  = 0
    for i in 1..<pts.count - 1 {
        let d = perpendicularDist(pts[i], from: start, to: end)
        if d > maxDist { maxDist = d; maxIdx = i }
    }
    if maxDist > epsilon {
        let l = douglasPeucker(Array(pts[0...maxIdx]), epsilon: epsilon)
        let r = douglasPeucker(Array(pts[maxIdx...]), epsilon: epsilon)
        return Array(l.dropLast()) + r
    }
    return [start, end]
}

private func perpendicularDist(
    _ p: CLLocationCoordinate2D,
    from s: CLLocationCoordinate2D,
    to e: CLLocationCoordinate2D
) -> Double {
    let dx = e.longitude - s.longitude
    let dy = e.latitude  - s.latitude
    let d  = sqrt(dx*dx + dy*dy)
    guard d > 0 else {
        return sqrt(pow(p.longitude - s.longitude, 2) + pow(p.latitude - s.latitude, 2))
    }
    return abs((p.longitude - s.longitude) * dy - (p.latitude - s.latitude) * dx) / d
}

private func parseGeoRings(from json: [String: Any]) -> [[CLLocationCoordinate2D]] {
    guard let type = json["type"] as? String else { return [] }

    func ringFromRaw(_ raw: [[Double]]) -> [CLLocationCoordinate2D] {
        raw.compactMap { pair in
            guard pair.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
        }
    }

    func simplify(_ ring: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        var r = douglasPeucker(ring, epsilon: 0.04)
        if r.count > 400 { r = Array(r.prefix(400)) }
        return r
    }

    switch type {
    case "Polygon":
        guard let coords = json["coordinates"] as? [[[Double]]] else { return [] }
        return coords.map { simplify(ringFromRaw($0)) }.filter { $0.count >= 3 }

    case "MultiPolygon":
        guard let coords = json["coordinates"] as? [[[[Double]]]] else { return [] }
        return coords.flatMap { poly in
            poly.map { simplify(ringFromRaw($0)) }
        }.filter { $0.count >= 3 }

    default:
        return []
    }
}

// MARK: - REST Countries Response

private struct RestCountry: Codable {
    let name: Name
    let capital: [String]?
    let region: String?
    let population: Int?
    let flag: String?
    struct Name: Codable { let common: String }
}

// MARK: - Map Example View

struct MapExampleView: View {
    @State private var position: MapCameraPosition = .camera(
        MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 20, longitude: 10),
                  distance: 30_000_000)
    )
    @State private var geoRings: [[CLLocationCoordinate2D]] = []
    @State private var selectedCountry: CountryDetails? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var cameraVersion = 0
    @State private var fetchTask: Task<Void, Never>? = nil
    @State private var gradientAngle: Double = 0

    var body: some View {
        MapReader { proxy in
            ZStack {
                Map(position: $position)
                    .mapStyle(.standard(elevation: .flat, emphasis: .muted))
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { val in
                                if let coord = proxy.convert(val.location, from: .local) {
                                    handleTap(coord: coord)
                                }
                            }
                    )
                    .onMapCameraChange(frequency: .continuous) { _ in
                        cameraVersion &+= 1
                    }

                // Country shape overlay
                if !geoRings.isEmpty {
                    countryShapeLayer(proxy: proxy)
                        .id(cameraVersion)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                // Loading indicator
                if isLoading {
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            ProgressView()
                                .tint(.white)
                            Text("Loading country…")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: .capsule)
                        .padding(.bottom, selectedCountry != nil ? 260 : 40)
                    }
                    .transition(.opacity)
                }
            }
            .overlay(alignment: .bottom) {
                if let country = selectedCountry {
                    CountryInfoCard(country: country) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            selectedCountry = nil
                            geoRings = []
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: selectedCountry)
        .animation(.easeInOut(duration: 0.4), value: geoRings.isEmpty)
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: true)) {
                gradientAngle = 360
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Country Shape Layer

    @ViewBuilder
    private func countryShapeLayer(proxy: MapProxy) -> some View {
        let paths: [Path] = geoRings.compactMap { ring in
            let pts = ring.compactMap { proxy.convert($0, to: .local) }
            guard pts.count >= 3 else { return nil }
            var p = Path()
            p.move(to: pts[0])
            pts.dropFirst().forEach { p.addLine(to: $0) }
            p.closeSubpath()
            return p
        }

        ZStack {
            // Gradient fill
            ForEach(paths.indices, id: \.self) { i in
                paths[i]
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.25, green: 0.55, blue: 1.0).opacity(0.55),
                                Color(red: 0.55, green: 0.20, blue: 0.95).opacity(0.50),
                                Color(red: 0.90, green: 0.30, blue: 0.65).opacity(0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Glass effect layer
            ForEach(paths.indices, id: \.self) { i in
                paths[i]
                    .glassEffect(.clear, in: paths[i])
            }

            // Border
            ForEach(paths.indices, id: \.self) { i in
                paths[i]
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
            }
        }
    }

    // MARK: - Tap Handler

    private func handleTap(coord: CLLocationCoordinate2D) {
        fetchTask?.cancel()
        fetchTask = Task { @MainActor in
            isLoading = true
            errorMessage = nil
            withAnimation { geoRings = []; selectedCountry = nil }

            do {
                // Step 1: Reverse geocode to get country name + ISO
                let placemark = try await reverseGeocode(coord)
                guard !Task.isCancelled else { return }
                guard let countryName = placemark.country,
                      let isoCode = placemark.isoCountryCode else {
                    isLoading = false; return
                }

                // Step 2: Fetch shape + details in parallel
                async let shapeTask   = fetchShape(countryName: countryName)
                async let detailsTask = fetchDetails(iso: isoCode.lowercased(), fallbackName: countryName, coord: coord)

                let (rings, details) = try await (shapeTask, detailsTask)
                guard !Task.isCancelled else { return }

                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    geoRings = rings
                    selectedCountry = details
                }
            } catch {
                if !Task.isCancelled { errorMessage = error.localizedDescription }
            }
            isLoading = false
        }
    }

    // MARK: - Reverse Geocode

    private func reverseGeocode(_ coord: CLLocationCoordinate2D) async throws -> CLPlacemark {
        try await withCheckedThrowingContinuation { cont in
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { placemarks, error in
                if let error { cont.resume(throwing: error); return }
                guard let p = placemarks?.first else {
                    cont.resume(throwing: URLError(.cannotFindHost)); return
                }
                cont.resume(returning: p)
            }
        }
    }

    // MARK: - Fetch Country Shape (Nominatim)

    private func fetchShape(countryName: String) async throws -> [[CLLocationCoordinate2D]] {
        let encoded = countryName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? countryName
        let urlStr = "https://nominatim.openstreetmap.org/search?q=\(encoded)&polygon_geojson=1&format=json&limit=1&featuretype=country"
        guard let url = URL(string: urlStr) else { return [] }

        var req = URLRequest(url: url)
        req.setValue("GlasskitApp/1.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: req)
        guard let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let first = arr.first,
              let geoJSON = first["geojson"] as? [String: Any] else { return [] }

        return parseGeoRings(from: geoJSON)
    }

    // MARK: - Fetch Country Details (RestCountries)

    private func fetchDetails(iso: String, fallbackName: String, coord: CLLocationCoordinate2D) async throws -> CountryDetails {
        let url = URL(string: "https://restcountries.com/v3.1/alpha/\(iso)?fields=name,capital,region,population,flag")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let c = try JSONDecoder().decode(RestCountry.self, from: data)
        return CountryDetails(
            name:       c.name.common,
            isoCode:    iso.uppercased(),
            capital:    c.capital?.first ?? "—",
            region:     c.region ?? "—",
            population: c.population ?? 0,
            flag:       c.flag ?? "🏳️",
            coordinate: coord
        )
    }
}

// MARK: - Country Info Card

private struct CountryInfoCard: View {
    let country: CountryDetails
    let onDismiss: () -> Void

    private var formattedPop: String {
        let n = country.population
        if n >= 1_000_000_000 { return String(format: "%.2fB", Double(n) / 1_000_000_000) }
        if n >= 1_000_000     { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000         { return String(format: "%.1fK", Double(n) / 1_000) }
        return "\(n)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.primary.opacity(0.2))
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 14)

            // Flag + name row
            HStack(alignment: .center, spacing: 14) {
                Text(country.flag)
                    .font(.system(size: 52))

                VStack(alignment: .leading, spacing: 4) {
                    Text(country.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text(country.region)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color.primary.opacity(0.08), in: .circle)
                }
            }
            .padding(.horizontal, 20)

            // Stats row
            HStack(spacing: 0) {
                statCell(icon: "building.columns", label: "Capital", value: country.capital)
                Divider().frame(height: 36)
                statCell(icon: "person.2.fill", label: "Population", value: formattedPop)
                Divider().frame(height: 36)
                statCell(icon: "globe", label: "ISO", value: country.isoCode)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: .rect(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 12)
    }

    private func statCell(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
