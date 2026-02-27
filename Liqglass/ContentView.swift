//
//  ContentView.swift
//  GlassKit
//
//  Created by quminsoda on 16/02/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                NavigationStack {
                    ScrollView {
                        VStack {
                        }
                    }
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
