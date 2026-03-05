//
//  LiqglassApp.swift
//  GlassKit
//
//  Created by quminsoda on 16/02/26.
//

import SwiftUI

@main
struct GlassKitApp: App {
    @State private var favoritesManager = FavoritesManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(favoritesManager)
        }
    }
}
