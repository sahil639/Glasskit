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
    var body: some ToolbarContent {
        // Edit — far right, bold, separate
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { } label: {
                Text("Edit")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.85))
            }
        }
        // Profile + Heart — grouped together, to the left of Edit
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 10) {
                // Heart — plain, no container
                Button { } label: {
                    Image(systemName: "heart")
                        .font(.system(size: 15))
                        .foregroundStyle(.black.opacity(0.65))
                }

                // Profile — image clipped to circle, no glass container
                Button { } label: {
                    Image("profilePhoto")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 28, height: 28)
                        .clipShape(.circle)
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
                Text("glasskit")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .center)

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

// MARK: - Analytics View

struct AnalyticsView: View {
    @State private var selectedFilter = "All"

    let filters: [(label: String, count: Int)] = [
        ("All", 24), ("Pie Chart", 12), ("Gantt Chart", 5),
        ("Histogram", 2), ("Diagrams", 4)
    ]

    var body: some View {
        ScrollView {
            // Chart content will go here
        }
        .safeAreaInset(edge: .top) {
            // Filter bar: ZStack so glass effect clips the scroll content correctly
            ZStack {
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
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
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

// MARK: - Content View

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
                    .navigationTitle("")
                    .toolbarTitleDisplayMode(.inline)
                    .toolbar { SharedToolbar() }
            }
            .tag(0)

            NavigationStack {
                FolderExample()
                    .navigationTitle("Glass Folders")
                    .toolbarTitleDisplayMode(.inline)
                    .toolbar { SharedToolbar() }
            }
            .tag(1)

            NavigationStack {
                FavoritesView()
                    .navigationTitle("Favourite GL Designs")
                    .toolbarTitleDisplayMode(.inline)
                    .toolbar { SharedToolbar() }
            }
            .tag(2)

            NavigationStack {
                AnalyticsView()
                    .navigationTitle("Analytics")
                    .toolbarTitleDisplayMode(.inline)
                    .toolbar { SharedToolbar() }
            }
            .tag(3)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 0) {
                tabButton(icon: "house.fill", tag: 0)
                tabButton(icon: "folder.fill", tag: 1)
                tabButton(icon: "heart.fill", tag: 2)
                tabButton(icon: "chart.bar.fill", tag: 3)
            }
            .frame(maxWidth: .infinity)
            .glassEffect(.clear, in: .capsule)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    private func tabButton(icon: String, tag: Int) -> some View {
        Button { selectedTab = tag } label: {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(selectedTab == tag ? Color.primary : Color.primary.opacity(0.35))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
        }
    }
}

#Preview {
    ContentView()
        .environment(FavoritesManager())
}
