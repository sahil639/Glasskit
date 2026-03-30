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

// MARK: - Library Destination

enum LibraryDestination: Hashable {
    case folders, analytics, clock, badges
}

// MARK: - Design Item (for global search)

struct DesignItem: Identifiable {
    let id = UUID()
    let name: String
    let tag: String
    let destination: LibraryDestination
}

let allDesigns: [DesignItem] = {
    var items: [DesignItem] = []

    let folderNames = (1...14).map { "Folder Design \($0)" }
    items += folderNames.map { DesignItem(name: $0, tag: "Folder Design", destination: .folders) }

    let analyticsNames = [
        "Pie Chart", "Half Donut", "Multi Ring", "Radial Chart", "Polar Area",
        "Bar Chart", "Dumbbell Chart", "Lollipop Chart", "Floating Bar", "Range Bar",
        "Stacked Bar", "Grouped Bar", "Line Chart", "Multi-Line Chart", "Step Line",
        "Spline Curve", "Area Line", "Stacked Area", "Gradient Area", "Sparkline",
        "Scatter Plot", "Bubble Chart", "Timeline", "Roadmap", "Histogram",
        "Density Curve", "Tree Diagram", "Treemap", "Network Graph", "Sankey Diagram",
        "Flow Chart", "Circle Packing", "Gantt Chart"
    ]
    items += analyticsNames.map { DesignItem(name: $0, tag: "Analytics Design", destination: .analytics) }

    items += (1...2).map { DesignItem(name: "Clock Design \($0)", tag: "Clock Design", destination: .clock) }
    items += (1...4).map { DesignItem(name: "Badge Design \($0)", tag: "Badge Design", destination: .badges) }

    return items
}()

// MARK: - Shared Toolbar

struct SharedToolbar: ToolbarContent {
    let title: String
    var onSearchTap: (() -> Void)? = nil
    var onFavoritesTap: (() -> Void)? = nil

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { onSearchTap?() } label: {
                Image(systemName: "magnifyingglass")
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
            Button { onFavoritesTap?() } label: {
                Image(systemName: "heart")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 38, height: 38)
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

// MARK: - Update Card (kept for potential reuse)

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

// MARK: - Library View

struct LibraryView: View {
    private let cardData: [(title: String, subtitle: String, destination: LibraryDestination)] = [
        ("Folders",   "12 designs", .folders),
        ("Analytics", "24 designs", .analytics),
        ("Clock",     "2 designs",  .clock),
        ("Badges",    "4 designs",  .badges)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Card grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(cardData, id: \.title) { card in
                        NavigationLink(value: card.destination) {
                            ReminderCard(title: card.title, subtitle: card.subtitle)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // TODO: Dynamic content container (145px height)
                Color(uiColor: .systemGray5)
                    .frame(maxWidth: .infinity)
                    .frame(height: 145)
                    .clipShape(.rect(cornerRadius: 16, style: .continuous))

                // TODO: Secondary action bar (48px height)
                Color.blue.opacity(0.18)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .navigationDestination(for: LibraryDestination.self) { dest in
            switch dest {
            case .folders:
                FolderExample()
                    .navigationTitle("Glass Folders")
                    .toolbarTitleDisplayMode(.inline)
            case .analytics:
                AnalyticsView()
                    .navigationTitle("Analytics")
                    .toolbarTitleDisplayMode(.inline)
            case .clock:
                FeedbackView()
                    .navigationTitle("Clock")
                    .toolbarTitleDisplayMode(.inline)
            case .badges:
                FeedbackView()
                    .navigationTitle("Badges")
                    .toolbarTitleDisplayMode(.inline)
            }
        }
    }
}

// MARK: - Feedback View

struct FeedbackView: View {
    var body: some View {
        Text("Hello World")
    }
}

// MARK: - Search Overlay

struct SearchOverlay: View {
    @Binding var isPresented: Bool
    var onNavigate: (LibraryDestination) -> Void

    @FocusState private var isSearchFocused: Bool
    @State private var searchText = ""

    var filteredDesigns: [DesignItem] {
        guard !searchText.isEmpty else { return allDesigns }
        return allDesigns.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.tag.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture {
                    searchText = ""
                    isPresented = false
                }

            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                        TextField("Search designs...", text: $searchText)
                            .focused($isSearchFocused)
                            .font(.system(size: 16))
                            .submitLabel(.search)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .glassEffect(.regular, in: .capsule)

                    Button {
                        searchText = ""
                        isPresented = false
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

                // Results
                List(filteredDesigns) { item in
                    Button {
                        isPresented = false
                        onNavigate(item.destination)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary)
                                Text(item.tag)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .background(.regularMaterial)
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showSearch = false
    @State private var showFavorites = false
    @State private var libraryPath = NavigationPath()

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("Library", systemImage: "books.vertical.fill", value: 0) {
                    NavigationStack(path: $libraryPath) {
                        LibraryView()
                            .toolbarTitleDisplayMode(.inline)
                            .toolbar {
                                SharedToolbar(
                                    title: "Library",
                                    onSearchTap: {
                                        withAnimation(.easeInOut(duration: 0.2)) { showSearch = true }
                                    },
                                    onFavoritesTap: { showFavorites = true }
                                )
                            }
                    }
                }

                Tab("Foundry", systemImage: "hammer.fill", value: 1) {
                    NavigationStack {
                        FeedbackView()
                            .toolbarTitleDisplayMode(.inline)
                            .toolbar {
                                SharedToolbar(
                                    title: "Foundry",
                                    onSearchTap: {
                                        withAnimation(.easeInOut(duration: 0.2)) { showSearch = true }
                                    },
                                    onFavoritesTap: { showFavorites = true }
                                )
                            }
                    }
                }

                Tab("Feedback", systemImage: "bubble.left.and.bubble.right.fill", value: 2) {
                    NavigationStack {
                        FeedbackView()
                            .toolbarTitleDisplayMode(.inline)
                            .toolbar {
                                SharedToolbar(
                                    title: "Feedback",
                                    onSearchTap: {
                                        withAnimation(.easeInOut(duration: 0.2)) { showSearch = true }
                                    },
                                    onFavoritesTap: { showFavorites = true }
                                )
                            }
                    }
                }

                Tab("GitHub", systemImage: "chevron.left.forwardslash.chevron.right", value: 3) {
                    EmptyView()
                }
            }
            .onChange(of: selectedTab) { _, new in
                if new == 3 {
                    if let url = URL(string: "https://github.com/sahil639/Glasskit") {
                        UIApplication.shared.open(url)
                    }
                    selectedTab = 0
                }
            }

            if showSearch {
                SearchOverlay(isPresented: $showSearch) { destination in
                    selectedTab = 0
                    libraryPath.append(destination)
                }
                .zIndex(1)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSearch)
        .sheet(isPresented: $showFavorites) {
            NavigationStack {
                FolderExample(favoritesOnly: true)
                    .navigationTitle("Favourites")
                    .toolbarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showFavorites = false }
                        }
                    }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(FavoritesManager())
}
