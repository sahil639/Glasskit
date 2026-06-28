//
//  FoundryView.swift
//  Glasskit — Foundry
//
//  The Foundry tab: a big frosted-glass card (an empty container for Metal
//  shader animations) over a radial "forecast" dial. Drag the dial left/right
//  to rotate it; the active item snaps to center, highlights blue, and the
//  card title updates to match. iOS 17+.
//

import SwiftUI

struct FoundryView: View {

    // The dial items. The dial is circular, so it wraps around.
    private let forecasts = ["Forecast 1", "Forecast 2", "Forecast 3", "Forecast 4"]

    // Continuous selection (fractional while dragging, integer after snap).
    @State private var selection: Double = 0
    @State private var dragAnchor: Double = 0
    @State private var isDragging = false

    // Index currently centered (wrapped into the forecasts array).
    private var centeredIndex: Int {
        let n = forecasts.count
        return ((Int(selection.rounded()) % n) + n) % n
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Text("Glass Popcorn's")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    .padding(.top, 6)
                    .padding(.bottom, 18)

                glassCard
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 26)

                dial
                    .frame(height: 232)
            }
            .padding(.bottom, 4)
        }
    }

    // MARK: Background — soft blue → lavender radial wash

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.42, green: 0.60, blue: 0.93),
                    Color(red: 0.74, green: 0.76, blue: 0.96),
                    Color(red: 0.93, green: 0.95, blue: 1.0)
                ],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                colors: [Color(red: 0.60, green: 0.52, blue: 0.90).opacity(0.45), .clear],
                center: .center, startRadius: 90, endRadius: 430
            )
        }
        .ignoresSafeArea()
    }

    // MARK: Glass card — frosted container for shader animations

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
            .fill(.ultraThinMaterial)
            // Brighter top-light wash for depth.
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.75), .white.opacity(0.10), .white.opacity(0.40)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .blendMode(.plusLighter)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.9), .white.opacity(0.25)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(alignment: .topLeading) {
                Text(forecasts[centeredIndex])
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(20)
            }
            // Soft white halo + blue grounding shadow.
            .shadow(color: .white.opacity(0.7), radius: 26)
            .shadow(color: Color(red: 0.40, green: 0.46, blue: 0.80).opacity(0.40),
                    radius: 28, y: 16)
    }

    // MARK: Radial dial

    private var dial: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let radius: Double = 196       // wide sweeping arc
            let topPad: Double = 14        // vertical offset of the arc's crest
            let step: Double = 0.42        // angular spacing between items (radians)
            let centerInt = Int(selection.rounded())
            let centerY = radius + topPad
            let tickR = radius + 22

            ZStack {
                ForEach(centerInt - 3 ... centerInt + 3, id: \.self) { i in
                    let diff = Double(i) - selection
                    let angle = diff * step
                    let isActive = (i == centerInt)
                    let fade = max(0.20, 1 - abs(diff) * 0.24)
                    let scale = max(0.55, 1 - abs(diff) * 0.15)

                    let x = cx + radius * sin(angle)
                    let yLabel = centerY - radius * cos(angle)
                    let yTick = centerY - tickR * cos(angle)
                    let label = forecasts[((i % forecasts.count) + forecasts.count) % forecasts.count]

                    // Tick mark
                    Capsule()
                        .fill(Color(red: 0.16, green: 0.44, blue: 0.96)
                            .opacity(isActive ? 1.0 : fade))
                        .frame(width: isActive ? 3 : 2.5, height: isActive ? 22 : 18)
                        .rotationEffect(.radians(angle))
                        .position(x: cx + tickR * sin(angle), y: yTick)

                    // Label
                    Text(label)
                        .font(.system(size: isActive ? 18 : 17,
                                      weight: isActive ? .bold : .medium,
                                      design: .rounded))
                        .foregroundStyle(
                            isActive
                            ? Color(red: 0.10, green: 0.38, blue: 0.96)
                            : Color(red: 0.38, green: 0.48, blue: 0.72).opacity(fade)
                        )
                        .scaleEffect(isActive ? 1.22 : scale)
                        .rotationEffect(.radians(angle))
                        .position(x: x, y: yLabel)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            dragAnchor = selection
                        }
                        selection = dragAnchor - Double(value.translation.width) / 90
                    }
                    .onEnded { _ in
                        isDragging = false
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                            selection = selection.rounded()
                        }
                    }
            )
        }
    }
}

#Preview {
    FoundryView()
}
