//
//  ContentView.swift
//  GlassKit
//
//  Created by quminsoda on 16/02/26.
//

import SwiftUI

// MARK: - Reminder Card

struct ReminderCard: View {
    let title: String
    let emoji: String
    let time: String
    let gradient: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(title) \(emoji)")
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.black.opacity(0.8))

            Spacer()

            HStack {
                Text(time)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.black.opacity(0.5))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.black.opacity(0.4))
                    .padding(6)
                    .background(.black.opacity(0.08), in: .circle)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 130)
        .background(
            LinearGradient(
                colors: gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: .rect(cornerRadius: 16, style: .continuous)
        )
    }
}

// MARK: - Home View

struct HomeView: View {
    let reminders: [(title: String, emoji: String, time: String, gradient: [Color])] = [
        ("Don't forget math homework", "\u{1F4D6}", "2:30 PM", [Color(red: 0.85, green: 0.75, blue: 0.55), Color(red: 0.80, green: 0.65, blue: 0.50)]),
        ("Buy Snacks before 6 PM", "\u{1F36A}", "5:45 PM", [Color(red: 0.78, green: 0.72, blue: 0.85), Color(red: 0.72, green: 0.65, blue: 0.80)]),
        ("Call mom Every Weekend", "\u{1F495}", "8:00 PM", [Color(red: 0.88, green: 0.72, blue: 0.65), Color(red: 0.82, green: 0.62, blue: 0.55)]),
        ("Water the plants", "\u{1F331}", "Morning", [Color(red: 0.65, green: 0.80, blue: 0.78), Color(red: 0.55, green: 0.75, blue: 0.72)])
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Let's be real...")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("you forget stuff.")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    HStack(spacing: 6) {
                        Text("We don't")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("\u{1F60E}")
                            .font(.system(size: 26))
                    }
                }
                .foregroundStyle(.black)

                // Reminder cards grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(0..<reminders.count, id: \.self) { i in
                        ReminderCard(
                            title: reminders[i].title,
                            emoji: reminders[i].emoji,
                            time: reminders[i].time,
                            gradient: reminders[i].gradient
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
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
                        .navigationTitle("Glasskit")
                }
            }

            Tab("Folders", systemImage: "folder.fill") {
                NavigationStack {
                    FolderExample()
                        .navigationTitle("Glass Folders")
                        .toolbarTitleDisplayMode(.inline)
                }
            }

            Tab("Favorites", systemImage: "heart.fill") {
                NavigationStack {
                    Text("Favorites")
                        .navigationTitle("Favorites")
                }
            }

            Tab("Settings", systemImage: "gearshape.fill") {
                NavigationStack {
                    Text("Settings")
                        .navigationTitle("Settings")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
