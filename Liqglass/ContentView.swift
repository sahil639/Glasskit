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
    var onFavoritesTap: (() -> Void)? = nil
    var onProfileTap: (() -> Void)? = nil

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { onFavoritesTap?() } label: {
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
            Button { onProfileTap?() } label: {
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
                // TODO: Dynamic content container (200px height)
                Color(uiColor: .systemGray4)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(.rect(cornerRadius: 16, style: .continuous))

                // TODO: Secondary action bar (135px height)
                Color.blue.opacity(0.18)
                    .frame(maxWidth: .infinity)
                    .frame(height: 135)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))

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

// MARK: - Feedback View

struct FeedbackView: View {
    var body: some View {
        Text("Hello World")
    }
}


// MARK: - GitHub Redirect View

struct GitHubRedirectView: View {
    var body: some View {
        EmptyView()
            .onAppear {
                if let url = URL(string: "https://github.com/sahil639/Glasskit") {
                    #if os(iOS)
                    UIApplication.shared.open(url)
                    #endif
                }
            }
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var showFavorites = false
    @State private var showProfile = false

    private func toolbar(title: String) -> some ToolbarContent {
        SharedToolbar(
            title: title,
            onFavoritesTap: { showFavorites = true },
            onProfileTap: { showProfile = true }
        )
    }

    var body: some View {
        TabView {
            Tab("Library", systemImage: "books.vertical.fill") {
                NavigationStack {
                    LibraryView()
                        .toolbarTitleDisplayMode(.inline)
                        .toolbar { toolbar(title: "Library") }
                }
            }

            Tab("Foundry", systemImage: "hammer.fill") {
                NavigationStack {
                    FeedbackView()
                        .toolbarTitleDisplayMode(.inline)
                        .toolbar { toolbar(title: "Foundry") }
                }
            }

            Tab("Feedback", systemImage: "bubble.left.and.bubble.right.fill") {
                NavigationStack {
                    FeedbackView()
                        .toolbarTitleDisplayMode(.inline)
                        .toolbar { toolbar(title: "Feedback") }
                }
            }

            Tab("GitHub", systemImage: "chevron.left.forwardslash.chevron.right") {
                GitHubRedirectView()
            }

            Tab(role: .search) {
                SearchView()
            }
        }
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
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                Text("Hello World")
                    .navigationTitle("Profile")
                    .toolbarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showProfile = false }
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
