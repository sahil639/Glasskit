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
