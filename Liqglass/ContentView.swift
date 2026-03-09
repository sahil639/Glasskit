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

    func isFavorited(_ id: String) -> Bool {
        favoritedIDs.contains(id)
    }

    func toggle(_ id: String) {
        if favoritedIDs.contains(id) {
            favoritedIDs.remove(id)
        } else {
            favoritedIDs.insert(id)
        }
    }
}

// MARK: - Shared Toolbar

struct SharedToolbar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 10) {
                // Profile button
                Button { } label: {
                    Image(systemName: "person.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.black.opacity(0.7))
                        .frame(width: 30, height: 30)
                }
                .glassEffect(.clear, in: .circle)

                // Favorites heart button
                Button { } label: {
                    Image(systemName: "heart")
                        .font(.system(size: 13))
                        .foregroundStyle(.black.opacity(0.7))
                        .frame(width: 30, height: 30)
                }
                .glassEffect(.clear, in: .circle)

                // Edit
                Button { } label: {
                    Text("Edit")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.black.opacity(0.8))
                }
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
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .stroke(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
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
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                    Text(date)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
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
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .stroke(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
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
        ("とうきょう", "こうべ"),
        ("おおさか", "こうべ"),
        ("なごや", "こうべ"),
        ("さっぽろ", "こうべ")
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
                // Title
                Text("glasskit")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Cards grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(0..<cards.count, id: \.self) { i in
                        ReminderCard(
                            title: cards[i].title,
                            subtitle: cards[i].subtitle
                        )
                    }
                }

                // Latest Updates
                VStack(alignment: .leading, spacing: 14) {
                    Text("Latest Updates")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.5))

                    ForEach(0..<updates.count, id: \.self) { i in
                        UpdateCard(
                            imageName: updates[i].image,
                            heading: updates[i].heading,
                            date: updates[i].date
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
}

// MARK: - Chart Card

struct ChartCard: View {
    let title: String
    let category: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(.black.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)

            Spacer()

            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.black.opacity(0.8))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(category)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.35))
                .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.8))
                .fill(LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0), location: 0),
                        .init(color: Color.white.opacity(1), location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .stroke(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
        )
        .glassEffect(.clear, in: .rect(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Analytics View

struct AnalyticsView: View {
    @State private var selectedFilter = "All"

    let filters: [(label: String, count: Int)] = [
        ("All", 24),
        ("Pie Chart", 12),
        ("Gantt Chart", 5),
        ("Histogram", 2),
        ("Diagrams", 4)
    ]

    struct ChartItem: Identifiable {
        let id = UUID()
        let title: String
        let category: String
        let icon: String
    }

    let chartItems: [ChartItem] = [
        // Pie Charts (12)
        ChartItem(title: "Revenue Distribution", category: "Pie Chart", icon: "chart.pie.fill"),
        ChartItem(title: "Market Share", category: "Pie Chart", icon: "chart.pie.fill"),
        ChartItem(title: "Budget Allocation", category: "Pie Chart", icon: "chart.pie.fill"),
        ChartItem(title: "User Demographics", category: "Pie Chart", icon: "chart.pie.fill"),
        ChartItem(title: "Traffic Sources", category: "Pie Chart", icon: "chart.pie.fill"),
        ChartItem(title: "Product Categories", category: "Pie Chart", icon: "chart.pie.fill"),
        ChartItem(title: "Regional Sales", category: "Pie Chart", icon: "chart.pie.fill"),
        ChartItem(title: "Platform Usage", category: "Pie Chart", icon: "chart.pie.fill"),
        ChartItem(title: "Cost Breakdown", category: "Pie Chart", icon: "chart.pie.fill"),
        ChartItem(title: "Time Allocation", category: "Pie Chart", icon: "chart.pie.fill"),
        ChartItem(title: "Resource Split", category: "Pie Chart", icon: "chart.pie.fill"),
        ChartItem(title: "Department Budget", category: "Pie Chart", icon: "chart.pie.fill"),
        // Gantt Charts (5)
        ChartItem(title: "Project Roadmap", category: "Gantt Chart", icon: "chart.bar.xaxis.ascending"),
        ChartItem(title: "Sprint Timeline", category: "Gantt Chart", icon: "chart.bar.xaxis.ascending"),
        ChartItem(title: "Release Schedule", category: "Gantt Chart", icon: "chart.bar.xaxis.ascending"),
        ChartItem(title: "Campaign Calendar", category: "Gantt Chart", icon: "chart.bar.xaxis.ascending"),
        ChartItem(title: "Milestone Tracker", category: "Gantt Chart", icon: "chart.bar.xaxis.ascending"),
        // Histograms (2)
        ChartItem(title: "Score Distribution", category: "Histogram", icon: "chart.bar.fill"),
        ChartItem(title: "Age Demographics", category: "Histogram", icon: "chart.bar.fill"),
        // Diagrams (4)
        ChartItem(title: "System Architecture", category: "Diagrams", icon: "square.and.line.vertical.and.square.fill"),
        ChartItem(title: "User Flow", category: "Diagrams", icon: "arrow.triangle.branch"),
        ChartItem(title: "Data Pipeline", category: "Diagrams", icon: "arrow.triangle.branch"),
        ChartItem(title: "Network Map", category: "Diagrams", icon: "square.and.line.vertical.and.square.fill")
    ]

    var filteredItems: [ChartItem] {
        if selectedFilter == "All" { return chartItems }
        return chartItems.filter { $0.category == selectedFilter }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(filteredItems) { item in
                    ChartCard(title: item.title, category: item.category, icon: item.icon)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .animation(.easeInOut(duration: 0.2), value: selectedFilter)
        }
        .safeAreaInset(edge: .top) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(filters, id: \.label) { filter in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter.label
                            }
                        } label: {
                            HStack(spacing: 7) {
                                Text(filter.label)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.black)

                                Text("\(filter.count)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue, in: .capsule)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 9)
                            .background(
                                selectedFilter == filter.label
                                    ? Color.black.opacity(0.12)
                                    : Color.clear,
                                in: .capsule
                            )
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .background(.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
            )
            .glassEffect(.clear, in: .rect(cornerRadius: 20, style: .continuous))
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

// MARK: - Content View

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                NavigationStack {
                    HomeView()
                        .navigationTitle("")
                        .toolbarTitleDisplayMode(.inline)
                        .toolbar { SharedToolbar() }
                }
            }

            Tab("Folders", systemImage: "folder.fill") {
                NavigationStack {
                    FolderExample()
                        .navigationTitle("Glass Folders")
                        .toolbarTitleDisplayMode(.inline)
                        .toolbar { SharedToolbar() }
                }
            }

            Tab("Favorites", systemImage: "heart.fill") {
                NavigationStack {
                    FavoritesView()
                        .navigationTitle("Favourite GL Designs")
                        .toolbarTitleDisplayMode(.inline)
                        .toolbar { SharedToolbar() }
                }
            }

            Tab("Analytics", systemImage: "chart.bar.fill") {
                NavigationStack {
                    AnalyticsView()
                        .navigationTitle("Analytics")
                        .toolbarTitleDisplayMode(.inline)
                        .toolbar { SharedToolbar() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(FavoritesManager())
}
