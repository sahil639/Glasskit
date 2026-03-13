//
//  ContentView.swift
//  GlassKit
//
//  Created by quminsoda on 16/02/26.
//

import SwiftUI

// MARK: - Favorites Manager

@Observable
class FavoritesManager {
    private static let key = "favoritedFolders"

    var favoritedIDs: Set<String> {
        didSet {
            let array = Array(favoritedIDs)
            UserDefaults.standard.set(array, forKey: Self.key)
        }
    }

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: Self.key) ?? []
        self.favoritedIDs = Set(saved)
    }

    func isFavorited(_ id: String) -> Bool { favoritedIDs.contains(id) }

    func toggle(_ id: String) {
        if favoritedIDs.contains(id) { favoritedIDs.remove(id) }
        else { favoritedIDs.insert(id) }
    }
}

// MARK: - Shared Toolbar

struct SharedToolbar: ToolbarContent {
    let title: String

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { } label: {
                Image(systemName: "heart")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 38, height: 38)
            }
        }
        ToolbarItem(placement: .principal) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { } label: {
                Image("profile_avatar")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(.circle)
            }
        }
    }
}

// MARK: - Reminder Card

struct ReminderCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.8))
            Spacer()
            Text(subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.35))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 130)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.8))
                .fill(LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0), location: 0),
                        .init(color: Color.white.opacity(1), location: 1)
                    ]),
                    startPoint: .top, endPoint: .bottom
                ))
                .stroke(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.15)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 2
                )
        )
        .glassEffect(.clear, in: .rect(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Update Card

struct UpdateCard: View {
    let imageName: String
    let heading: String
    let date: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text(heading)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.85))

                HStack(spacing: 5) {
                    Image(systemName: "calendar").font(.system(size: 13))
                    Text(date).font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.black.opacity(0.35))
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.8))
                .fill(LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0), location: 0),
                        .init(color: Color.white.opacity(1), location: 1)
                    ]),
                    startPoint: .top, endPoint: .bottom
                ))
                .stroke(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.15)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 2
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .glassEffect(.clear, in: .rect(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Home View

struct HomeView: View {
    let cards: [(title: String, subtitle: String)] = [
        ("とうきょう", "こうべ"), ("おおさか", "こうべ"),
        ("なごや", "こうべ"), ("さっぽろ", "こうべ")
    ]

    let updates: [(image: String, heading: String, date: String)] = [
        ("card1", "Here is a list of major Japanese cities with their Kanji, Hiragana, and English names", "12 March 2026"),
        ("card2", "Exploring the ancient temples of Kyoto during cherry blossom season", "8 March 2026"),
        ("card3", "Traditional Japanese pottery and ceramics", "2 March 2026"),
        ("card1", "A guide to navigating the Tokyo subway system for first-time visitors in Japan", "25 February 2026"),
        ("card2", "Street food in Osaka", "19 February 2026")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(0..<cards.count, id: \.self) { i in
                        ReminderCard(title: cards[i].title, subtitle: cards[i].subtitle)
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Latest Updates")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.5))

                    ForEach(0..<updates.count, id: \.self) { i in
                        UpdateCard(imageName: updates[i].image, heading: updates[i].heading, date: updates[i].date)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
}

// MARK: - Analytics Data Model

struct AnalyticsDataItem: Identifiable {
    let id = UUID()
    let label: String
    var percentage: Double
    var color: Color
}

// MARK: - Pie Slice Shape

struct PieSliceShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadiusRatio: CGFloat = 0.52
    private let gap: Double = 1.5

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set { startAngle = .degrees(newValue.first); endAngle = .degrees(newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = min(rect.width, rect.height) / 2
        let innerR = outerR * innerRadiusRatio
        let s = Angle(degrees: startAngle.degrees + gap)
        let e = Angle(degrees: endAngle.degrees - gap)
        guard e.degrees > s.degrees else { return Path() }
        var p = Path()
        p.move(to: CGPoint(x: c.x + innerR * CGFloat(cos(s.radians)), y: c.y + innerR * CGFloat(sin(s.radians))))
        p.addArc(center: c, radius: innerR, startAngle: s, endAngle: e, clockwise: false)
        p.addLine(to: CGPoint(x: c.x + outerR * CGFloat(cos(e.radians)), y: c.y + outerR * CGFloat(sin(e.radians))))
        p.addArc(center: c, radius: outerR, startAngle: e, endAngle: s, clockwise: true)
        p.closeSubpath()
        return p
    }
}

// MARK: - Analytics Card

struct AnalyticsCard: View {
    let title: String
    let categories: [String]
    @State private var items: [AnalyticsDataItem]
    @State private var chartType: ChartType = .pie
    @Namespace private var chartTypeNS
    @State private var editingID: UUID? = nil
    @State private var editingText: String = ""

    static let colorPalette: [Color] = [
        Color(red: 0.28, green: 0.16, blue: 0.72),
        Color(red: 0.62, green: 0.52, blue: 0.88),
        Color(red: 0.82, green: 0.78, blue: 0.94),
        Color(red: 0.56, green: 0.82, blue: 0.72),
        Color(red: 0.38, green: 0.65, blue: 0.58),
        Color(red: 0.82, green: 0.92, blue: 0.88),
    ]

    enum ChartType: String, CaseIterable {
        case pie = "Pie Chart"
        case gantt = "Gantt Chart"
    }

    init(title: String, categories: [String], items: [AnalyticsDataItem]) {
        self.title = title
        self.categories = categories
        self._items = State(initialValue: items)
    }

    // MARK: Slice computation

    struct Slice: Identifiable {
        let id: UUID
        var startAngle: Angle
        var endAngle: Angle
        let color: Color
    }

    var slices: [Slice] {
        var result: [Slice] = []
        var cursor = -90.0
        let total = items.reduce(0) { $0 + $1.percentage }
        guard total > 0 else { return [] }
        for item in items {
            let sweep = 360.0 * item.percentage / total
            result.append(Slice(id: item.id, startAngle: .degrees(cursor), endAngle: .degrees(cursor + sweep), color: item.color))
            cursor += sweep
        }
        return result
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {

            // TOP — visualization
            Group {
                if chartType == .pie { pieChartView } else { ganttChartView }
            }
            .frame(height: 240)
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Divider().padding(.top, 16).padding(.horizontal, 12)

            // BOTTOM — controls + list
            VStack(spacing: 14) {

                // Title pill
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 16).padding(.vertical, 7)
                    .background(Color.black.opacity(0.06), in: .capsule)

                // Chart type switcher
                HStack(spacing: 4) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { chartType = type }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: type == .pie ? "chart.pie.fill" : "chart.bar.fill")
                                    .font(.system(size: 11))
                                Text(type.rawValue)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background {
                                if chartType == type {
                                    Capsule().fill(Color.black.opacity(0.1))
                                        .matchedGeometryEffect(id: "chartTypePill", in: chartTypeNS)
                                }
                            }
                        }
                        .foregroundStyle(chartType == type ? .primary : .secondary)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.black.opacity(0.04), in: .capsule)

                // Items list
                itemListView
            }
            .padding(.top, 14).padding(.bottom, 8)
        }
        .background(Color(.systemGray6), in: .rect(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 12)
        .onTapGesture { editingID = nil }
    }

    // MARK: Item list view

    var itemListView: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                itemRow(index: index, item: item)
            }
            Divider().padding(.horizontal, 20)
            Button { addItem() } label: {
                Text("+ Add New Item")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
    }

    @ViewBuilder
    func itemRow(index: Int, item: AnalyticsDataItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                ColorPicker("", selection: $items[index].color, supportsOpacity: false)
                    .labelsHidden()
                    .opacity(0.015)
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(items[index].color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                    .allowsHitTesting(false)
            }
            .frame(width: 28, height: 28)
            Text(item.label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
            Spacer()
            if editingID == item.id {
                HStack(spacing: 2) {
                    TextField("0", text: $editingText)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 48)
                        .onChange(of: editingText) { _, val in
                            if let v = Double(val) { redistribute(for: item.id, to: v) }
                        }
                    Text("%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    editingID = item.id
                    editingText = "\(Int(item.percentage))"
                } label: {
                    Text("\(Int(item.percentage))%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .underline(color: .primary.opacity(0.25))
                }
                .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        if index < items.count - 1 { Divider().padding(.horizontal, 20) }
    }

    // MARK: Pie chart

    var pieChartView: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(slices) { slice in
                    PieSliceShape(startAngle: slice.startAngle, endAngle: slice.endAngle)
                        .fill(slice.color)
                        .glassEffect(.clear, in: PieSliceShape(startAngle: slice.startAngle, endAngle: slice.endAngle))
                }
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: slices.map { $0.startAngle.degrees })
        }
    }

    // MARK: Gantt chart

    var ganttChartView: some View {
        VStack(spacing: 12) {
            Spacer()
            ForEach(items) { item in
                HStack(spacing: 10) {
                    Text(item.label)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.black.opacity(0.05))
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(item.color)
                                .glassEffect(.clear, in: .rect(cornerRadius: 7, style: .continuous))
                                .frame(width: max(6, geo.size.width * item.percentage / 100))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: item.percentage)
                        }
                    }
                    .frame(height: 28)
                    Text("\(Int(item.percentage))%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .frame(width: 36, alignment: .trailing)
                }
            }
            Spacer()
        }
    }

    // MARK: Logic

    func redistribute(for id: UUID, to newValue: Double) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let clamped = min(100, max(0, newValue))
        let remaining = 100.0 - clamped
        let others = items.indices.filter { $0 != idx }
        let otherSum = others.reduce(0.0) { $0 + items[$1].percentage }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            items[idx].percentage = clamped
            if otherSum > 0 {
                let scale = remaining / otherSum
                for i in others { items[i].percentage = max(0, items[i].percentage * scale) }
            } else if !others.isEmpty {
                let share = remaining / Double(others.count)
                for i in others { items[i].percentage = share }
            }
        }
    }

    func addItem() {
        let colorIdx = items.count % Self.colorPalette.count
        let gap = max(0.0, 100.0 - items.reduce(0) { $0 + $1.percentage })
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            items.append(AnalyticsDataItem(
                label: "Item \(items.count + 1)",
                percentage: gap,
                color: Self.colorPalette[colorIdx]
            ))
        }
    }
}

// MARK: - Analytics View

struct AnalyticsView: View {
    @State private var selectedFilter = "All"
    @Namespace private var filterNamespace

    let filters: [(label: String, count: Int)] = [
        ("All", 24), ("Pie Chart", 12), ("Gantt Chart", 5),
        ("Histogram", 2), ("Diagrams", 4)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                let cardCategories = ["Pie Chart", "Gantt Chart"]
                if selectedFilter == "All" || cardCategories.contains(selectedFilter) {
                    AnalyticsCard(
                        title: "Simple Pie Chart",
                        categories: cardCategories,
                        items: [
                            AnalyticsDataItem(label: "Item 1", percentage: 32, color: AnalyticsCard.colorPalette[0]),
                            AnalyticsDataItem(label: "Item 2", percentage: 12, color: AnalyticsCard.colorPalette[1]),
                            AnalyticsDataItem(label: "Item 3", percentage: 56, color: AnalyticsCard.colorPalette[2]),
                        ]
                    )
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .safeAreaInset(edge: .top) {
            // Filter bar: ZStack so glass effect clips the scroll content correctly
            ZStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(filters, id: \.label) { filter in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    selectedFilter = filter.label
                                }
                            } label: {
                                HStack(spacing: 7) {
                                    Text(filter.label)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.black)

                                    Text("\(filter.count)")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(Color.blue, in: .capsule)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 9)
                                .background {
                                    if selectedFilter == filter.label {
                                        Capsule()
                                            .fill(Color.black.opacity(0.12))
                                            .matchedGeometryEffect(id: "filterSelection", in: filterNamespace)
                                    }
                                }
                            }
                        }
                    }
                    // Equal padding all sides (8pt) so left matches top/bottom
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
            }
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.gray.opacity(0.25), lineWidth: 1))
            .glassEffect(.clear, in: .capsule)
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Favorites View

struct FavoritesView: View {
    var body: some View {
        FolderExample(favoritesOnly: true)
    }
}

// MARK: - Search View

struct SearchView: View {
    @FocusState private var isSearchFocused: Bool
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @Namespace private var filterNamespace

    let filters: [(label: String, count: Int)] = [
        ("All", 24), ("Pie Chart", 12), ("Gantt Chart", 5),
        ("Histogram", 2), ("Diagrams", 4)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search bar + X button
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                    TextField("Search", text: $searchText)
                        .focused($isSearchFocused)
                        .font(.system(size: 16))
                        .submitLabel(.search)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .glassEffect(.regular, in: .capsule)

                // X button — dismisses keyboard
                Button {
                    isSearchFocused = false
                    searchText = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.primary.opacity(0.65))
                        .frame(width: 44, height: 44)
                }
                .glassEffect(.regular, in: .circle)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Filter bar — 16pt below search bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(filters, id: \.label) { filter in
                        let isSelected = selectedFilter == filter.label
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedFilter = filter.label
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(filter.label)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.5))
                                Text("\(filter.count)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue, in: .capsule)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background {
                                if isSelected {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.08))
                                        .matchedGeometryEffect(id: "searchFilterPill", in: filterNamespace)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            .padding(.top, 16)

            Spacer()
        }
        #if os(iOS)
        .toolbar(.hidden, for: .tabBar)
        #endif
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation { isSearchFocused = true }
            }
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                NavigationStack {
                    HomeView()
                        .toolbarTitleDisplayMode(.inline)
                        .toolbar { SharedToolbar(title: "Glasskit") }
                }
            }

            Tab("Folders", systemImage: "folder.fill") {
                NavigationStack {
                    FolderExample()
                        .toolbarTitleDisplayMode(.inline)
                        .toolbar { SharedToolbar(title: "Glass Folders") }
                }
            }

            Tab("Favourites", systemImage: "heart.fill") {
                NavigationStack {
                    FavoritesView()
                        .toolbarTitleDisplayMode(.inline)
                        .toolbar { SharedToolbar(title: "Favourites") }
                }
            }

            Tab("Analytics", systemImage: "chart.bar.fill") {
                NavigationStack {
                    AnalyticsView()
                        .toolbarTitleDisplayMode(.inline)
                        .toolbar { SharedToolbar(title: "Analytics") }
                }
            }

            Tab(role: .search) {
                EmptyView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(FavoritesManager())
}
