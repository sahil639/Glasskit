//
//  FolderExample.swift
//  GlassKit
//
//  Created by quminsoda on 16/02/26.
//

import SwiftUI

// MARK: - Folder Shape

struct FolderShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let scaleX = w / 362
        let scaleY = h / 223

        var path = Path()
        path.move(to: CGPoint(x: 170.664 * scaleX, y: 0))
        path.addLine(to: CGPoint(x: 30.002 * scaleX, y: 0))
        path.addCurve(
            to: CGPoint(x: 0.105 * scaleX, y: 32.48 * scaleY),
            control1: CGPoint(x: 12.455 * scaleX, y: 0),
            control2: CGPoint(x: -1.346 * scaleX, y: 14.994 * scaleY)
        )
        path.addLine(to: CGPoint(x: 13.627 * scaleX, y: 195.48 * scaleY))
        path.addCurve(
            to: CGPoint(x: 43.525 * scaleX, y: 223 * scaleY),
            control1: CGPoint(x: 14.918 * scaleX, y: 211.034 * scaleY),
            control2: CGPoint(x: 27.918 * scaleX, y: 223 * scaleY)
        )
        path.addLine(to: CGPoint(x: 318.369 * scaleX, y: 223 * scaleY))
        path.addCurve(
            to: CGPoint(x: 348.145 * scaleX, y: 196.657 * scaleY),
            control1: CGPoint(x: 333.523 * scaleX, y: 223 * scaleY),
            control2: CGPoint(x: 346.298 * scaleX, y: 211.698 * scaleY)
        )
        path.addLine(to: CGPoint(x: 361.777 * scaleX, y: 85.657 * scaleY))
        path.addCurve(
            to: CGPoint(x: 332.001 * scaleX, y: 52 * scaleY),
            control1: CGPoint(x: 363.973 * scaleX, y: 67.772 * scaleY),
            control2: CGPoint(x: 350.02 * scaleX, y: 52 * scaleY)
        )
        path.addLine(to: CGPoint(x: 235.656 * scaleX, y: 52 * scaleY))
        path.addCurve(
            to: CGPoint(x: 218.015 * scaleX, y: 43.758 * scaleY),
            control1: CGPoint(x: 228.846 * scaleX, y: 52 * scaleY),
            control2: CGPoint(x: 222.385 * scaleX, y: 48.982 * scaleY)
        )
        path.addLine(to: CGPoint(x: 188.305 * scaleX, y: 8.242 * scaleY))
        path.addCurve(
            to: CGPoint(x: 170.664 * scaleX, y: 0),
            control1: CGPoint(x: 183.935 * scaleX, y: 3.019 * scaleY),
            control2: CGPoint(x: 177.475 * scaleX, y: 0)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Folder Card

struct FolderCard: View {
    let title: String
    let images: [String]
    let backgroundGradient: [Color]
    var stickerImage: String? = nil
    var showDate: Bool = true
    @Binding var animate: Bool
                // ============================
                // FOLDER 1 - simeple folder
                // ============================
    var body: some View {
        VStack(spacing: 2) {
            ZStack(alignment: .bottom) {
                // Background card (behind folder)
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            colors: backgroundGradient,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 159, height: 140)

                // Rectangle 3
                Image(images[2])
                    .resizable()
                    .scaledToFill()
                    .frame(width: 128, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(.white, lineWidth: 2.5))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                    .rotationEffect(.degrees(105))
                    .offset(
                        x: 21 + (animate ? 1 : -1),
                        y: -35 + (animate ? -0.5 : 0.5)
                    )

                // Rectangle 2
                Image(images[1])
                    .resizable()
                    .scaledToFill()
                    .frame(width: 128, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white, lineWidth: 2.5))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                    .rotationEffect(.degrees(95))
                    .offset(
                        x: -3 + (animate ? -0.5 : 0.5),
                        y: -38 + (animate ? 1 : -1)
                    )

                // Rectangle 1
                Image(images[0])
                    .resizable()
                    .scaledToFill()
                    .frame(width: 128, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white, lineWidth: 2.5))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                    .rotationEffect(.degrees(85))
                    .offset(
                        x: -24 + (animate ? 0.5 : -0.5),
                        y: -40 + (animate ? -1 : 1)
                    )

                // Folder (in front)
                FolderShape()
                     .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.6))
                            .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            // Adjust these opacity values to tweak the fill gradient:
                            // - top: white at 45% opacity
                            // - bottom: white at 100% opacity
                            .init(color: Color.white.opacity(0.05), location: 0.65),
                            .init(color: Color.white.opacity(0.95), location: 0.95)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .stroke(
    LinearGradient(
        stops: [
            .init(color: .white.opacity(0.6), location: 0),
            .init(color: .white.opacity(0.1), location: 1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    ), lineWidth: 2)
                    .frame(width: 181, height: 111.5)
                    .overlay(alignment: .bottomLeading) {
                        Text(title)
                            .font(.system(.caption, design: .rounded))
                            .bold()
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.white, in: .capsule)
                            .padding(.leading, 16)
                            .padding(.bottom, 8)
                            .offset(x: 2, y: -2)
                    }
                    .glassEffect(.clear, in: FolderShape())
                    .overlay {
                        if let stickerImage {
                            Image(stickerImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 55)
                                .rotationEffect(.degrees(-8))
                                .offset(x: 10, y: 5)
                                .shadow(color: .black.opacity(0.2), radius: 2)
                                .shadow(color: .black.opacity(0.2), radius: 6)
                        }
                    }
            }
            .scaleEffect(1.2312)
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)

            if showDate {
                Text("Created on: \(Date.now, format: .dateTime.day().month(.wide).year())")
                    .font(.system(.caption2, design: .rounded))
                    .tracking(-0.3)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Folder Shape 2

struct FolderShape2: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let sx = w / 199
        let sy = h / 152
        let r: CGFloat = 12

        // Inner notch corner: direction from (73, 23.5) toward (48, 0)
        let ndx: CGFloat = 48 - 73  // -25
        let ndy: CGFloat = 0 - 23.5 // -23.5
        let nlen = sqrt(ndx * ndx + ndy * ndy)
        let nux = ndx / nlen
        let nuy = ndy / nlen
        // Point on angled edge, r units from notch corner
        let naX = 73 + r * nux  // ~64.26
        let naY = 23.5 + r * nuy // ~15.28

        var path = Path()
        // Start at rounded notch corner (angled edge side)
        path.move(to: CGPoint(x: naX * sx, y: naY * sy))
        // Angled line up to tab top
        path.addLine(to: CGPoint(x: 48 * sx, y: 0))
        // Across tab top, stop r before top-left corner
        path.addLine(to: CGPoint(x: r * sx, y: 0))
        // Round the top-left corner (90°)
        path.addQuadCurve(
            to: CGPoint(x: 0, y: r * sy),
            control: CGPoint(x: 0, y: 0)
        )
        // Down left side
        path.addLine(to: CGPoint(x: 0, y: 127.5 * sy))
        path.addCurve(
            to: CGPoint(x: 24 * sx, y: 151.5 * sy),
            control1: CGPoint(x: 0, y: 140.755 * sy),
            control2: CGPoint(x: 10.7452 * sx, y: 151.5 * sy)
        )
        path.addLine(to: CGPoint(x: 174.5 * sx, y: 151.5 * sy))
        path.addCurve(
            to: CGPoint(x: 198.5 * sx, y: 127.5 * sy),
            control1: CGPoint(x: 187.755 * sx, y: 151.5 * sy),
            control2: CGPoint(x: 198.5 * sx, y: 140.755 * sy)
        )
        path.addLine(to: CGPoint(x: 198.5 * sx, y: 23.5 * sy))
        // Horizontal to r before notch corner
        path.addLine(to: CGPoint(x: (73 + r) * sx, y: 23.5 * sy))
        // Round the inner notch corner
        path.addQuadCurve(
            to: CGPoint(x: naX * sx, y: naY * sy),
            control: CGPoint(x: 73 * sx, y: 23.5 * sy)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Folder Shape 3

struct FolderShape3: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 130
        let sy = rect.height / 121

        var path = Path()
        path.move(to: CGPoint(x: 45.0692 * sx, y: 0))
        path.addLine(to: CGPoint(x: 24 * sx, y: 0))
        path.addCurve(
            to: CGPoint(x: 0, y: 24 * sy),
            control1: CGPoint(x: 10.7452 * sx, y: 0),
            control2: CGPoint(x: 0, y: 10.7452 * sy)
        )
        path.addLine(to: CGPoint(x: 0, y: 96.5 * sy))
        path.addCurve(
            to: CGPoint(x: 24 * sx, y: 120.5 * sy),
            control1: CGPoint(x: 0, y: 109.755 * sy),
            control2: CGPoint(x: 10.7452 * sx, y: 120.5 * sy)
        )
        path.addLine(to: CGPoint(x: 105.5 * sx, y: 120.5 * sy))
        path.addCurve(
            to: CGPoint(x: 129.5 * sx, y: 96.5 * sy),
            control1: CGPoint(x: 118.755 * sx, y: 120.5 * sy),
            control2: CGPoint(x: 129.5 * sx, y: 109.755 * sy)
        )
        path.addLine(to: CGPoint(x: 129.5 * sx, y: 36.5 * sy))
        path.addCurve(
            to: CGPoint(x: 105.5 * sx, y: 12.5 * sy),
            control1: CGPoint(x: 129.5 * sx, y: 23.2452 * sy),
            control2: CGPoint(x: 118.755 * sx, y: 12.5 * sy)
        )
        path.addLine(to: CGPoint(x: 79.5814 * sx, y: 12.5 * sy))
        path.addCurve(
            to: CGPoint(x: 67.5814 * sx, y: 9.28461 * sy),
            control1: CGPoint(x: 75.3685 * sx, y: 12.5 * sy),
            control2: CGPoint(x: 71.2299 * sx, y: 11.391 * sy)
        )
        path.addLine(to: CGPoint(x: 57.0692 * sx, y: 3.21539 * sy))
        path.addCurve(
            to: CGPoint(x: 45.0692 * sx, y: 0),
            control1: CGPoint(x: 53.4208 * sx, y: 1.10895 * sy),
            control2: CGPoint(x: 49.2821 * sx, y: 0)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Folder Shape 4

struct FolderShape4: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 191
        let sy = rect.height / 104

        var path = Path()
        path.move(to: CGPoint(x: 39 * sx, y: 104 * sy))
        path.addLine(to: CGPoint(x: 152 * sx, y: 104 * sy))
        path.addCurve(
            to: CGPoint(x: 191 * sx, y: 65 * sy),
            control1: CGPoint(x: 173.539 * sx, y: 104 * sy),
            control2: CGPoint(x: 191 * sx, y: 86.5391 * sy)
        )
        path.addLine(to: CGPoint(x: 191 * sx, y: 39.5 * sy))
        path.addCurve(
            to: CGPoint(x: 174 * sx, y: 22.5 * sy),
            control1: CGPoint(x: 191 * sx, y: 30.1112 * sy),
            control2: CGPoint(x: 183.389 * sx, y: 22.5 * sy)
        )
        path.addLine(to: CGPoint(x: 68.7384 * sx, y: 22.5 * sy))
        path.addCurve(
            to: CGPoint(x: 59.5 * sx, y: 13.2616 * sy),
            control1: CGPoint(x: 63.6362 * sx, y: 22.5 * sy),
            control2: CGPoint(x: 59.5 * sx, y: 18.3638 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 46.2384 * sx, y: 0),
            control1: CGPoint(x: 59.5 * sx, y: 5.93742 * sy),
            control2: CGPoint(x: 53.5626 * sx, y: 0)
        )
        path.addLine(to: CGPoint(x: 9.54245 * sx, y: 0))
        path.addCurve(
            to: CGPoint(x: 0, y: 9.54245 * sy),
            control1: CGPoint(x: 4.2723 * sx, y: 0),
            control2: CGPoint(x: 0, y: 4.2723 * sy)
        )
        path.addLine(to: CGPoint(x: 0, y: 65 * sy))
        path.addCurve(
            to: CGPoint(x: 39 * sx, y: 104 * sy),
            control1: CGPoint(x: 0, y: 86.5391 * sy),
            control2: CGPoint(x: 17.4609 * sx, y: 104 * sy)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Container Shape

struct ContainerShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 421
        let scaleY = rect.height / 309

        var path = Path()
        path.move(to: CGPoint(x: 157.818 * scaleX, y: 0))
        path.addLine(to: CGPoint(x: 30.0018 * scaleX, y: 0))
        path.addCurve(
            to: CGPoint(x: 0.0919 * scaleX, y: 32.3231 * scaleY),
            control1: CGPoint(x: 12.5177 * scaleX, y: 0),
            control2: CGPoint(x: -1.262 * scaleX, y: 14.8915 * scaleY)
        )
        path.addLine(to: CGPoint(x: 19.4317 * scaleX, y: 281.323 * scaleY))
        path.addCurve(
            to: CGPoint(x: 49.3416 * scaleX, y: 309 * scaleY),
            control1: CGPoint(x: 20.6449 * scaleX, y: 296.944 * scaleY),
            control2: CGPoint(x: 33.6741 * scaleX, y: 309 * scaleY)
        )
        path.addLine(to: CGPoint(x: 370.371 * scaleX, y: 309 * scaleY))
        path.addCurve(
            to: CGPoint(x: 400.228 * scaleX, y: 281.919 * scaleY),
            control1: CGPoint(x: 385.809 * scaleX, y: 309 * scaleY),
            control2: CGPoint(x: 398.727 * scaleX, y: 297.284 * scaleY)
        )
        path.addLine(to: CGPoint(x: 420.364 * scaleX, y: 75.9186 * scaleY))
        path.addCurve(
            to: CGPoint(x: 390.506 * scaleX, y: 43.0002 * scaleY),
            control1: CGPoint(x: 422.088 * scaleX, y: 58.2807 * scaleY),
            control2: CGPoint(x: 408.228 * scaleX, y: 43.0002 * scaleY)
        )
        path.addLine(to: CGPoint(x: 222.345 * scaleX, y: 43.0002 * scaleY))
        path.addCurve(
            to: CGPoint(x: 199.604 * scaleX, y: 32.5674 * scaleY),
            control1: CGPoint(x: 213.607 * scaleX, y: 43.0002 * scaleY),
            control2: CGPoint(x: 205.303 * scaleX, y: 39.1907 * scaleY)
        )
        path.addLine(to: CGPoint(x: 180.558 * scaleX, y: 10.4329 * scaleY))
        path.addCurve(
            to: CGPoint(x: 157.818 * scaleX, y: 0),
            control1: CGPoint(x: 174.859 * scaleX, y: 3.80964 * scaleY),
            control2: CGPoint(x: 166.556 * scaleX, y: 0)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Folder Example Page

struct FolderExample: View {
    @State private var animate = false
    @State private var animationEnabled = true

    var body: some View {
        ScrollView {
                // Folder 1 - Simple glass folder
                VStack(spacing: 32) {
                    FolderCard(
                        title: "Japan 2027",
                        images: ["card1", "card2", "card3"],
                        backgroundGradient: [
                            Color(red: 0x48/255, green: 0x43/255, blue: 0x4E/255),
                            Color(red: 0x35/255, green: 0x30/255, blue: 0x39/255)
                        ],
                        showDate: false,
                        animate: $animate
                    )
                    Text("Glass Folder 1.0")
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color(.black).opacity(0.06), in: .capsule)
                }
                .padding(.top, 56)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6), in: .rect(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 12)

                // ============================
                // FOLDER 2 - Gach folder
                // ============================
                VStack(spacing: 32) {
                    ZStack {
                // Background rectangle behind the container shape
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15)) // light grey fill
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1) // grey stroke
                    .frame(width: 155, height: 105) // slightly less than front layer
                    .offset(y: -18) // offset down on y axis

                // Card 3 (left)
                Image("card3")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 72)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 12, bottomLeading: 12, bottomTrailing: 12, topTrailing: 12), style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 12, bottomLeading: 12, bottomTrailing: 12, topTrailing: 12), style: .continuous).stroke(Color.black.opacity(0.2), lineWidth: 1).padding(-1))
                    .padding(8) // Stroke 3: white border thickness (change this value)
                    .background(Color.white, in: .rect(cornerRadius: 14, style: .continuous))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 14, bottomLeading: 14, bottomTrailing: 14, topTrailing: 14), style: .continuous).stroke(Color.black.opacity(0.2), lineWidth: 1))
                    .rotationEffect(.degrees(-15))
                    .offset(x: -64 + (animate ? 1 : -1), y: -12 + (animate ? -0.5 : 0.5))

                // Card 1 (center)
                Image("card1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 72)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 12, bottomLeading: 12, bottomTrailing: 12, topTrailing: 12), style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 12, bottomLeading: 12, bottomTrailing: 12, topTrailing: 12), style: .continuous).stroke(Color.black.opacity(0.2), lineWidth: 1).padding(-1))
                    .padding(8) // Stroke 3: white border thickness (change this value)
                    .background(Color.white, in: .rect(cornerRadius: 14, style: .continuous))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 14, bottomLeading: 14, bottomTrailing: 14, topTrailing: 14), style: .continuous).stroke(Color.black.opacity(0.2), lineWidth: 1))
                    .rotationEffect(.degrees(3))
                    .offset(x: 0 + (animate ? -0.5 : 0.5), y: -49 + (animate ? 1 : -1))

                // Card 2 (right)
                Image("card2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 72)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 12, bottomLeading: 12, bottomTrailing: 12, topTrailing: 12), style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 12, bottomLeading: 12, bottomTrailing: 12, topTrailing: 12), style: .continuous).stroke(Color.black.opacity(0.2), lineWidth: 1).padding(-1))
                    .padding(8) // Stroke 3: white border thickness (change this value)
                    .background(Color.white, in: .rect(cornerRadius: 14, style: .continuous))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 14, bottomLeading: 14, bottomTrailing: 14, topTrailing: 14), style: .continuous).stroke(Color.black.opacity(0.2), lineWidth: 1))
                    .rotationEffect(.degrees(12))
                    .offset(x: 58 + (animate ? 0.5 : -0.5), y: -16 + (animate ? -1 : 1))

                // Front container shape with glass effect
                ContainerShape()
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            // Adjust these opacity values to tweak the fill gradient:
                            // - top: white at 45% opacity
                            // - bottom: white at 100% opacity
                            .init(color: Color.white.opacity(0.65), location: 0.55),
                            .init(color: Color.white.opacity(0.75), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .overlay(
                        // Inner white stroke: gradient from 100% opacity top to 0% bottom
                        ContainerShape()
                            .stroke(LinearGradient(
                                gradient: Gradient(stops: [
                                    // Adjust these to tweak the inner white stroke gradient:
                                    .init(color: Color.white.opacity(1.0), location: 0.0),
                                    .init(color: Color.white.opacity(0.0), location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ), lineWidth: 2)
                    )
                    .overlay(
                        // Outer black stroke at 50% opacity
                        ContainerShape()
                            .stroke(Color.black.opacity(0.25), lineWidth: 1)
                    )
                    .overlay(alignment: .bottom) {
                        // Two decorative lines at the bottom
                        VStack(spacing: 6) {
                            Capsule()
                                .fill(Color.white.opacity(1)) // Line 1 color opacity
                                .frame(width: 130, height: 2.8) // Line 1 width & height
                                .shadow(color: .black.opacity(0.35), radius: 10, y: 0) // Line 1 shadow
                            Capsule()
                                .fill(Color.white.opacity(0.8)) // Line 2 color opacity
                                .frame(width: 130, height: 2.8) // Line 2 width & height
                                .shadow(color: .black.opacity(0.35), radius: 10, y: 0) // Line 2 shadow
                        }
                        .padding(.bottom, 16)
                    }
                    .overlay {
                        // --- Cat Sticker ---
                        Image("catSticker")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60) // Cat: change size here
                            .rotationEffect(.degrees(-12)) // Cat: change rotation here
                            .offset(x: -35, y: -5) // Cat: change position here (x: left/right, y: up/down)
                            .shadow(color: .black.opacity(0.25), radius: 1)
                            .shadow(color: .black.opacity(0.2), radius: 8)

                        // --- Japanese Sticker ---
                        Image("japaneseSticker")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 64) // Japanese: change size here
                            .rotationEffect(.degrees(24)) // Japanese: change rotation here
                            .offset(x: 30, y: 12) // Japanese: change position here (x: left/right, y: up/down)
                            .shadow(color: .black.opacity(0.25), radius: 1)
                            .shadow(color: .black.opacity(0.2), radius: 8)
                    }
                    .frame(width: 170, height: 125)
                    .glassEffect(.clear, in: ContainerShape())
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                }
                .scaleEffect(1.265)
                    Text("Sticker Folder")
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color(.black).opacity(0.06), in: .capsule)
                }
                .padding(.top, 90)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6), in: .rect(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 12)

                // ============================
                // FOLDER 3 - FolderShape2
                // ============================
                VStack(spacing: 32) {
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.black.opacity(0.2), lineWidth: 1.5)
                            )
                            .frame(width: 199, height: 180)
                            .shadow(color: .black.opacity(0.75), radius: 12, y: 4)

                        // Card 3 (back - most offset)
                        Image("card3")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 125)
                            .clipShape(.rect(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                            .rotationEffect(.degrees(0))
                            .offset(x: 30, y: -30)

                        // Card 1 (middle)
                        Image("card1")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 125)
                            .clipShape(.rect(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                            .rotationEffect(.degrees(3))
                            .offset(x: -2, y: -36)

                        // Card 21 (front - least offset)
                        Image("card2")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 125)
                            .clipShape(.rect(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                            .rotationEffect(.degrees(0))
                            .offset(x: -36, y: -42)

                        FolderShape2()
                         .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.8))
                            .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            // Adjust these opacity values to tweak the fill gradient:
                            // - top: white at 45% opacity
                            // - bottom: white at 100% opacity
                            .init(color: Color.white.opacity(0.25), location: 0.55),
                            .init(color: Color.white.opacity(0.95), location: 0.75)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                            .stroke(Color.white.opacity(0.75), lineWidth: 4)
                            .frame(width: 199, height: 152)
                            .glassEffect(.clear, in: FolderShape2())
                            .overlay(alignment: .bottomLeading) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Saigon")
                                        .font(.system(size: 20, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.black)
                                    Text("glasskit v0.0.1")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(.black.opacity(0.5))
                                }
                                .padding(.leading, 20)
                                .padding(.bottom, 20)
                            }
                    }
                    Text("Folder Design 3")
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color(.black).opacity(0.06), in: .capsule)
                    
                }
                .padding(.top, 36)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6), in: .rect(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 12)

                // ============================
                // FOLDER 4 - Signature folder
                // ============================
                VStack(spacing: 32) {
                    ZStack(alignment: .bottom) {
                        // Card 3 (back - most offset)
                        Image("card3")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 135, height: 210)
                            .clipShape(.rect(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 6))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                            .rotationEffect(.degrees(8))
                            .offset(x: 12, y: -15)

                        // Card 1 (middle)
                        // Image("card1")
                        //     .resizable()
                        //     .scaledToFill()
                        //     .frame(width: 90, height: 125)
                        //     .clipShape(.rect(cornerRadius: 12, style: .continuous))
                        //     .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                        //     .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                        //     .rotationEffect(.degrees(3))
                        //     .offset(x: -2, y: -88)

                        // Card 2 (front - least offset)
                        Image("card2")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 135, height: 210)
                            .clipShape(.rect(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 6))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                            .rotationEffect(.degrees(3))
                            .offset(x: -24, y: -15)

                        // Front layer - FolderShape3
                        FolderShape3()
                            .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.8))
                            .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            // Adjust these opacity values to tweak the fill gradient:
                            // - top: white at 45% opacity
                            // - bottom: white at 100% opacity
                            .init(color: Color.white.opacity(0.25), location: 0.55),
                            .init(color: Color.white.opacity(0.95), location: 0.75)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                            .overlay(
                                FolderShape3()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.8), Color.white.opacity(0.2)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .frame(width: 228, height: 200)
                            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                            .glassEffect(.clear, in: FolderShape3())

                        // Signature overlay on top of glass
                        Image("signature")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 55)
                            .frame(width: 228, height: 200, alignment: .bottomLeading)
                            .opacity(0.7)
                            .rotationEffect(.degrees(25))
                            .offset(x: 54, y: 12)

                        // Shiba sticker - bottom right
                        Image("shibaSticker")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150)
                            .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
                            .frame(width: 228, height: 200, alignment: .bottomTrailing)
                            .offset(x: 12, y: -7)
                    }
                    Text("Signature Folder")
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color(.black).opacity(0.06), in: .capsule)
                }
                .padding(.top, 36)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6), in: .rect(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 12)

                // ============================
                // FOLDER 5 - New folder design
                // ============================
                VStack(spacing: 32) {
                    ZStack(alignment: .bottom) {
                        // SVG 2 - Background rounded rectangle
                        RoundedRectangle(cornerRadius: 39)
                            .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(1))
                            .frame(width: 191, height: 193)

                        // Card 3 (back - most offset)
                        Image("card3")
                            .resizable()
                            .scaledToFill(1.1)
                            .frame(width: 100, height: 100)
                            .clipShape(.rect(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                            .rotationEffect(.degrees(0))
                            .offset(x: 30, y: -30)

                        // Card 1 (middle)
                        Image("card1")
                            .resizable()
                            .scaledToFill(1.1)
                            .frame(width: 100, height: 100)
                            .clipShape(.rect(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                            .rotationEffect(.degrees(3))
                            .offset(x: -2, y: -36)

                        // Card 2 (front - least offset)
                        Image("card2")
                            .resizable()
                            .scaledToFill(1.1)
                            .frame(width: 100, height: 100)
                            .clipShape(.rect(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                            .rotationEffect(.degrees(0))
                            .offset(x: -36, y: -42)

                        // SVG 1 - Front folder shape with glass effect
                        FolderShape4()
                             .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.8))
                            .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            // Adjust these opacity values to tweak the fill gradient:
                            // - top: white at 45% opacity
                            // - bottom: white at 100% opacity
                            .init(color: Color.white.opacity(0), location: 0),
                            .init(color: Color.white.opacity(1), location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                            .stroke(Color.white.opacity(0.45), lineWidth: 3)
                            .frame(width: 191, height: 104)
                            .glassEffect(.clear, in: FolderShape4())
                    }
                    .scaleEffect(1.25)
                    Text("Folder Design 5")
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color(.black).opacity(0.06), in: .capsule)
                }
                .padding(.top, 36)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6), in: .rect(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 12)
        }
        .safeAreaInset(edge: .bottom) {
            // Animation Toggle - pinned above tab bar
            HStack {
                Text("Animation")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                Spacer()
                Toggle("", isOn: $animationEnabled)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.clear, in: .capsule)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .onAppear {
            if animationEnabled {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
        }
        .onChange(of: animationEnabled) { _, enabled in
            if enabled {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    animate = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    animate = false
                }
            }
        }
    }
}

#Preview {
    FolderExample()
}
