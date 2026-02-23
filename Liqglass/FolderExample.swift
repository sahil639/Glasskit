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
    @Binding var animate: Bool

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
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white, lineWidth: 2.5))
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
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.8), location: 0.0),
                            .init(color: Color.white.opacity(0.08), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
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
            }
            .scaleEffect(0.84)
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)

            Text("Created on: \(Date.now, format: .dateTime.day().month(.wide).year())")
                .font(.system(.caption2, design: .rounded))
                .tracking(-0.3)
                .foregroundStyle(.secondary)
        }
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

    var body: some View {
        VStack(spacing: 32) {
            Text("Glass Containers")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 12) {
                FolderCard(
                    title: "Japan 2027",
                    images: ["card1", "card2", "card3"],
                    backgroundGradient: [
                        Color(red: 0x48/255, green: 0x43/255, blue: 0x4E/255),
                        Color(red: 0x35/255, green: 0x30/255, blue: 0x39/255)
                    ],
                    animate: $animate
                )

                FolderCard(
                    title: "Japan 2027",
                    images: ["card1", "card2", "card3"],
                    backgroundGradient: [
                        Color(red: 0x48/255, green: 0x43/255, blue: 0x4E/255),
                        Color(red: 0x35/255, green: 0x30/255, blue: 0x39/255)
                    ],
                    animate: $animate
                )
            }

            ContainerShape()
                .fill(LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0.8), location: 0.0),
                        .init(color: Color.white.opacity(0.08), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: 340, height: 250)
                .glassEffect(.clear, in: ContainerShape())
                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3)
                .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }
}

#Preview {
    FolderExample()
}
