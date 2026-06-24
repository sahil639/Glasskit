//
//  LiquidBlobDetailView.swift
//  Glasskit — Foundry
//
//  Detail screen pushed from the "Liquid Metal Blob – Interactive" Foundry card.
//  A 260×260 animated liquid-glass lens (LiquidBlob.metal) over a custom top
//  bar with four live sliders. Requires iOS 17+ (layerEffect / visualEffect).
//

import SwiftUI

struct LiquidBlobDetailView: View {
    @Environment(\.dismiss) private var dismiss

    // Four shader parameters
    @State private var baseDistortion: Float = 0.30
    @State private var reflection:     Float = 0.50
    @State private var iridescence:    Float = 0.40
    @State private var waveAngle:      Float = 0.00

    private let startDate = Date()

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 12)
            blob
            Spacer(minLength: 24)
            controls
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // Custom top bar with back button on the LEFT
    private var topBar: some View {
        ZStack {
            Text("Liquid Metal Blob")
                .font(.headline)
                .foregroundStyle(.black)

            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Foundry")
                    }
                    .font(.body)
                    .foregroundStyle(.blue)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var blob: some View {
        TimelineView(.animation) { timeline in
            let time = Float(startDate.distance(to: timeline.date))
            Circle()
                .fill(.white)
                .frame(width: 260, height: 260)
                .visualEffect { content, proxy in
                    content.layerEffect(
                        ShaderLibrary.liquidBlob(
                            .float2(proxy.size),
                            .float(time),
                            .float(baseDistortion),
                            .float(reflection),
                            .float(iridescence),
                            .float(waveAngle)
                        ),
                        maxSampleOffset: CGSize(width: 80, height: 80)
                    )
                }
        }
        .frame(height: 300)
    }

    private var controls: some View {
        VStack(spacing: 18) {
            sliderRow("Base Distortion", $baseDistortion, 0...1)
            sliderRow("Reflection",      $reflection,     0...1)
            sliderRow("Iridescence",     $iridescence,    0...1)
            sliderRow("Wave Angle",      $waveAngle,      0...(2 * .pi))
        }
        .padding(.horizontal, 28)
    }

    private func sliderRow(_ title: String,
                           _ value: Binding<Float>,
                           _ range: ClosedRange<Float>) -> some View {
        HStack(spacing: 14) {
            Text(title)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.black)
                .frame(width: 130, alignment: .leading)
            Slider(value: value, in: range)
                .tint(.yellow)
        }
    }
}

#Preview {
    NavigationStack {
        LiquidBlobDetailView()
    }
}
