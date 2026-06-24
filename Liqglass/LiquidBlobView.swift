//
//  LiquidBlobView.swift
//  Glasskit — Foundry
//
//  Drop-in SwiftUI view that drives LiquidBlob.metal with four live sliders.
//  Requires iOS 17+ (layerEffect / visualEffect).
//
//  Usage:
//      LiquidBlobView()
//
//  To refract a photo instead of a flat white disc, swap the `.fill(.white)`
//  on the blob for an Image (see BLOB CONTENT note below).
//

import SwiftUI

struct LiquidBlobView: View {

    // Four parameters, each matching one slider in the original video.
    @State private var baseDistortion: Float = 0.30
    @State private var reflection:     Float = 0.50
    @State private var iridescence:    Float = 0.40
    @State private var waveAngle:      Float = 0.00   // radians, 0...2π

    // Animation clock — drives the scrolling waves.
    private let startDate = Date()

    var body: some View {
        VStack(spacing: 48) {

            // ---- The blob ----------------------------------------------
            TimelineView(.animation) { timeline in
                let time = Float(startDate.distance(to: timeline.date))

                blobContent
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
                            // Must be >= the largest offset the shader samples.
                            // Refraction + waves can reach ~80px, so pad for it.
                            maxSampleOffset: CGSize(width: 80, height: 80)
                        )
                    }
            }
            .frame(height: 300)

            // ---- The controls ------------------------------------------
            VStack(spacing: 18) {
                sliderRow("Base Distortion", value: $baseDistortion, range: 0...1)
                sliderRow("Reflection",      value: $reflection,     range: 0...1)
                sliderRow("Iridescence",     value: $iridescence,    range: 0...1)
                sliderRow("Wave Angle",      value: $waveAngle,      range: 0...(2 * .pi))
            }
            .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)            // white bg = clearest lens read
    }

    // BLOB CONTENT
    // A flat white disc refracts as a clean glass sphere. For a richer look,
    // replace this with: Image("yourPhoto").resizable().scaledToFill().clipShape(Circle())
    private var blobContent: some View {
        Circle()
            .fill(.white)
    }

    // A labelled slider styled to echo the video's monospaced yellow look.
    private func sliderRow(_ title: String,
                           value: Binding<Float>,
                           range: ClosedRange<Float>) -> some View {
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
    LiquidBlobView()
}
