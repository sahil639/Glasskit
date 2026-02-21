//
//  ContentView.swift
//  GlassKit
//
//  Created by quminsoda on 16/02/26.
//

import SwiftUI

struct ContentView: View {
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            FolderExample()
                .tag(0)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

#Preview {
    ContentView()
}
