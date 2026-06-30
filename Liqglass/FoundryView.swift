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
    // Which forecast card is currently at the front of the stack.
    @State private var frontIndex = 0

    // Fixed heights make the layout deterministic, so it renders identically
    // whether FoundryView is standalone or embedded in the TabView (where the
    // tab bar would otherwise steal height from a flexible card).
    private let cardHeight: CGFloat = 430
    // The dial reserves only this much layout space; its arc draws beyond it,
    // spilling the lower labels down behind the floating tab bar.
    private let dialHeight: CGFloat = 130

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
                    .padding(.bottom, 54)
                    .zIndex(1)

                cardStack
                    .frame(maxWidth: .infinity)
                    .frame(height: cardHeight)
                    .padding(.horizontal, 26)
                    .padding(.bottom, 18)

                dial
                    .frame(height: dialHeight)

                // Pins the title + card + dial to the top of the safe area; the
                // dial's lower arc spills past its frame behind the tab bar.
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: Background — soft blue → lavender radial wash

    private var background: some View {
        RadialGradient(
            stops: [
                .init(color: Color(red: 0.922, green: 0.961, blue: 1.0), location: 0.4),   // EBF5FF
                .init(color: Color(red: 0.659, green: 0.678, blue: 1.0), location: 0.8),  // A8ADFF
                .init(color: Color(red: 0.314, green: 0.592, blue: 0.875), location: 1.0)  // 5097DF
            ],
            center: .bottom,
            startRadius: 0,
            endRadius: 580
        )
        .ignoresSafeArea()
    }

    // MARK: Glass card — frosted container for shader animations

    // Front glass card plus a deck of solid cards peeking out behind it.
    private var cardStack: some View {
        ZStack {
            ForEach(Array(stride(from: 3, through: 1, by: -1)), id: \.self) { i in
                let d = Double(i)
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(Color.white.opacity(0.16))
                    .padding(.horizontal, d * 14)      // each one narrower
                    .offset(y: -d * 13)                // peeks up behind the front
                    .shadow(color: .black.opacity(0.08), radius: 6, y: -3)
            }
            glassCard
                .id(frontIndex)
                // Stacked-card swap: the new card grows forward out of the deck,
                // the old one recedes back into it (no top slide).
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.90).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
        }
    }

    private var glassCard: some View {
        Color.clear
            .glassEffect(.clear, in: .rect(cornerRadius: 36, style: .continuous))
            // Fine grain texture on top of the active card.
            .overlay(
                Rectangle()
                    .fill(.white)
                    .colorEffect(ShaderLibrary.grain())
                    .blendMode(.overlay)
                    .opacity(0.08)
                    .clipShape(.rect(cornerRadius: 36, style: .continuous))
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .strokeBorder(Color.white.opacity(0), lineWidth: 0)
            )
            // Soft white halo + neutral grounding shadow (no blue).
            .shadow(color: .white.opacity(0.5), radius: 24)
            .shadow(color: .blue.opacity(0.12), radius: 22, y: 12)
    }

    // MARK: Radial dial

    private var dial: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let radius: Double = 245           // label arc radius
            let topPad: Double = 96            // arc sits lower for breathing room
            let step: Double = 0.36            // angular spacing between items (radians)
            let centerInt = Int(selection.rounded())
            let centerY = radius + topPad
            let tickInnerR = radius + 58       // ticks ride outside the labels (no overlap)

            ZStack {
                // Graduation ruler — dense ticks that scroll with the dial.
                let base = Int((selection * 4).rounded())
                ForEach(base - 22 ... base + 22, id: \.self) { k in
                    let p = Double(k) / 4.0
                    let diff = p - selection
                    let angle = diff * step
                    if abs(angle) <= 1.7 {
                        let isMajor = (k % 4 == 0)
                        let len: Double = isMajor ? 18 : 10
                        let op = max(0.25, 1 - abs(angle) * 0.42)
                        let r = tickInnerR + len / 2
                        Capsule()
                            .fill(Color(red: 0.16, green: 0.42, blue: 0.92)
                                .opacity(isMajor ? op : op * 0.6))
                            .frame(width: isMajor ? 2.6 : 1.6, height: len)
                            .rotationEffect(.radians(angle))
                            .position(x: cx + r * sin(angle),
                                      y: centerY - r * cos(angle))
                    }
                }

                // Labels
                ForEach(centerInt - 3 ... centerInt + 3, id: \.self) { i in
                    let diff = Double(i) - selection
                    let angle = diff * step
                    let isActive = (i == centerInt)
                    let fade = max(0.25, 1 - abs(diff) * 0.22)
                    let scale = max(0.6, 1 - abs(diff) * 0.12)

                    let x = cx + radius * sin(angle)
                    let yLabel = centerY - radius * cos(angle)
                    let label = forecasts[((i % forecasts.count) + forecasts.count) % forecasts.count]

                    Text(label)
                        .font(.system(size: 17,
                                      weight: isActive ? .bold : .medium,
                                      design: .rounded))
                        .foregroundStyle(
                            isActive
                            ? Color(red: 0.10, green: 0.38, blue: 0.96)
                            : Color(red: 0.38, green: 0.48, blue: 0.72).opacity(fade)
                        )
                        .scaleEffect(isActive ? 1.0 : scale)
                        // Text tilts with the dial; selected item sits at -90°.
                        .rotationEffect(.radians(angle - .pi / 2))
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
                        let target = selection.rounded()
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                            selection = target
                        }
                        let n = forecasts.count
                        let newFront = ((Int(target) % n) + n) % n
                        if newFront != frontIndex {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                frontIndex = newFront
                            }
                        }
                    }
            )
        }
    }
}

#Preview {
    FoundryView()
}
