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

// MARK: - Folder Shape 11a (front - notched corners, 205x201)

struct FolderShape11a: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 205
        let sy = rect.height / 201

        var path = Path()
        path.move(to: CGPoint(x: 5.27207 * sx, y: 45.7279 * sy))
        path.addLine(to: CGPoint(x: 45.7279 * sx, y: 5.27208 * sy))
        path.addCurve(
            to: CGPoint(x: 58.4558 * sx, y: 0),
            control1: CGPoint(x: 49.1036 * sx, y: 1.89642 * sy),
            control2: CGPoint(x: 53.6819 * sx, y: 0)
        )
        path.addLine(to: CGPoint(x: 96.1737 * sx, y: 0))
        path.addCurve(
            to: CGPoint(x: 110.405 * sx, y: 6.97807 * sy),
            control1: CGPoint(x: 101.741 * sx, y: 0),
            control2: CGPoint(x: 106.995 * sx, y: 2.57637 * sy)
        )
        path.addLine(to: CGPoint(x: 139.095 * sx, y: 44.0219 * sy))
        path.addCurve(
            to: CGPoint(x: 153.326 * sx, y: 51 * sy),
            control1: CGPoint(x: 142.505 * sx, y: 48.4236 * sy),
            control2: CGPoint(x: 147.759 * sx, y: 51 * sy)
        )
        path.addLine(to: CGPoint(x: 186.5 * sx, y: 51 * sy))
        path.addCurve(
            to: CGPoint(x: 204.5 * sx, y: 69 * sy),
            control1: CGPoint(x: 196.441 * sx, y: 51 * sy),
            control2: CGPoint(x: 204.5 * sx, y: 59.0589 * sy)
        )
        path.addLine(to: CGPoint(x: 204.5 * sx, y: 158 * sy))
        path.addCurve(
            to: CGPoint(x: 186.5 * sx, y: 176 * sy),
            control1: CGPoint(x: 204.5 * sx, y: 167.941 * sy),
            control2: CGPoint(x: 196.441 * sx, y: 176 * sy)
        )
        path.addLine(to: CGPoint(x: 134.456 * sx, y: 176 * sy))
        path.addCurve(
            to: CGPoint(x: 121.728 * sx, y: 181.272 * sy),
            control1: CGPoint(x: 129.682 * sx, y: 176 * sy),
            control2: CGPoint(x: 125.104 * sx, y: 177.896 * sy)
        )
        path.addLine(to: CGPoint(x: 107.772 * sx, y: 195.228 * sy))
        path.addCurve(
            to: CGPoint(x: 95.0442 * sx, y: 200.5 * sy),
            control1: CGPoint(x: 104.396 * sx, y: 198.604 * sy),
            control2: CGPoint(x: 99.8181 * sx, y: 200.5 * sy)
        )
        path.addLine(to: CGPoint(x: 18 * sx, y: 200.5 * sy))
        path.addCurve(
            to: CGPoint(x: 0, y: 182.5 * sy),
            control1: CGPoint(x: 8.05887 * sx, y: 200.5 * sy),
            control2: CGPoint(x: 0, y: 192.441 * sy)
        )
        path.addLine(to: CGPoint(x: 0, y: 58.4558 * sy))
        path.addCurve(
            to: CGPoint(x: 5.27207 * sx, y: 45.7279 * sy),
            control1: CGPoint(x: 0, y: 53.6819 * sy),
            control2: CGPoint(x: 1.89641 * sx, y: 49.1036 * sy)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Folder Shape 11b (back - notched corners without tab, 205x201)

struct FolderShape11b: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 205
        let sy = rect.height / 201

        var path = Path()
        path.move(to: CGPoint(x: 5.27207 * sx, y: 45.7279 * sy))
        path.addLine(to: CGPoint(x: 45.7279 * sx, y: 5.27208 * sy))
        path.addCurve(
            to: CGPoint(x: 58.4558 * sx, y: 0),
            control1: CGPoint(x: 49.1036 * sx, y: 1.89642 * sy),
            control2: CGPoint(x: 53.6819 * sx, y: 0)
        )
        path.addLine(to: CGPoint(x: 186.5 * sx, y: 0))
        path.addCurve(
            to: CGPoint(x: 204.5 * sx, y: 18 * sy),
            control1: CGPoint(x: 196.441 * sx, y: 0),
            control2: CGPoint(x: 204.5 * sx, y: 8.05888 * sy)
        )
        path.addLine(to: CGPoint(x: 204.5 * sx, y: 158 * sy))
        path.addCurve(
            to: CGPoint(x: 186.5 * sx, y: 176 * sy),
            control1: CGPoint(x: 204.5 * sx, y: 167.941 * sy),
            control2: CGPoint(x: 196.441 * sx, y: 176 * sy)
        )
        path.addLine(to: CGPoint(x: 134.456 * sx, y: 176 * sy))
        path.addCurve(
            to: CGPoint(x: 121.728 * sx, y: 181.272 * sy),
            control1: CGPoint(x: 129.682 * sx, y: 176 * sy),
            control2: CGPoint(x: 125.104 * sx, y: 177.896 * sy)
        )
        path.addLine(to: CGPoint(x: 107.772 * sx, y: 195.228 * sy))
        path.addCurve(
            to: CGPoint(x: 95.0442 * sx, y: 200.5 * sy),
            control1: CGPoint(x: 104.396 * sx, y: 198.604 * sy),
            control2: CGPoint(x: 99.8181 * sx, y: 200.5 * sy)
        )
        path.addLine(to: CGPoint(x: 18 * sx, y: 200.5 * sy))
        path.addCurve(
            to: CGPoint(x: 0, y: 182.5 * sy),
            control1: CGPoint(x: 8.05887 * sx, y: 200.5 * sy),
            control2: CGPoint(x: 0, y: 192.441 * sy)
        )
        path.addLine(to: CGPoint(x: 0, y: 58.4558 * sy))
        path.addCurve(
            to: CGPoint(x: 5.27207 * sx, y: 45.7279 * sy),
            control1: CGPoint(x: 0, y: 53.6819 * sy),
            control2: CGPoint(x: 1.89641 * sx, y: 49.1036 * sy)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Folder Shape 10a (envelope front, 389x262)

struct FolderShape10a: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 389
        let sy = rect.height / 262

        var path = Path()
        path.move(to: CGPoint(x: 0, y: 24.0328 * sy))
        path.addCurve(
            to: CGPoint(x: 35.1464 * sx, y: 2.7782 * sy),
            control1: CGPoint(x: 0, y: 5.98821 * sy),
            control2: CGPoint(x: 19.1659 * sx, y: -5.60229 * sy)
        )
        path.addLine(to: CGPoint(x: 194.5 * sx, y: 86.3467 * sy))
        path.addLine(to: CGPoint(x: 353.854 * sx, y: 2.77819 * sy))
        path.addCurve(
            to: CGPoint(x: 389 * sx, y: 24.0328 * sy),
            control1: CGPoint(x: 369.834 * sx, y: -5.6023 * sy),
            control2: CGPoint(x: 389 * sx, y: 5.98821 * sy)
        )
        path.addLine(to: CGPoint(x: 389 * sx, y: 178.641 * sy))
        path.addLine(to: CGPoint(x: 389 * sx, y: 237.347 * sy))
        path.addCurve(
            to: CGPoint(x: 365 * sx, y: 261.347 * sy),
            control1: CGPoint(x: 389 * sx, y: 250.602 * sy),
            control2: CGPoint(x: 378.255 * sx, y: 261.347 * sy)
        )
        path.addLine(to: CGPoint(x: 24 * sx, y: 261.347 * sy))
        path.addCurve(
            to: CGPoint(x: 0, y: 237.347 * sy),
            control1: CGPoint(x: 10.7452 * sx, y: 261.347 * sy),
            control2: CGPoint(x: 0, y: 250.602 * sy)
        )
        path.addLine(to: CGPoint(x: 0, y: 24.0328 * sy))
        path.closeSubpath()
        return path
    }
}

// MARK: - Folder Shape 10b (envelope back, 389x289)

struct FolderShape10b: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 389
        let sy = rect.height / 289

        var path = Path()
        path.move(to: CGPoint(x: 0, y: 34 * sy))
        path.addCurve(
            to: CGPoint(x: 34 * sx, y: 0),
            control1: CGPoint(x: 0, y: 15.2223 * sy),
            control2: CGPoint(x: 15.2223 * sx, y: 0)
        )
        path.addLine(to: CGPoint(x: 355 * sx, y: 0))
        path.addCurve(
            to: CGPoint(x: 389 * sx, y: 34 * sy),
            control1: CGPoint(x: 373.778 * sx, y: 0),
            control2: CGPoint(x: 389 * sx, y: 15.2223 * sy)
        )
        path.addLine(to: CGPoint(x: 389 * sx, y: 265 * sy))
        path.addCurve(
            to: CGPoint(x: 365 * sx, y: 289 * sy),
            control1: CGPoint(x: 389 * sx, y: 278.255 * sy),
            control2: CGPoint(x: 378.255 * sx, y: 289 * sy)
        )
        path.addLine(to: CGPoint(x: 24 * sx, y: 289 * sy))
        path.addCurve(
            to: CGPoint(x: 0, y: 265 * sy),
            control1: CGPoint(x: 10.7452 * sx, y: 289 * sy),
            control2: CGPoint(x: 0, y: 278.255 * sy)
        )
        path.addLine(to: CGPoint(x: 0, y: 34 * sy))
        path.closeSubpath()
        return path
    }
}

// MARK: - Folder Shape 9a (front wave, 202x100)

struct FolderShape9a: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 202
        let sy = rect.height / 100

        var path = Path()
        path.move(to: CGPoint(x: 0, y: 69.9636 * sy))
        path.addLine(to: CGPoint(x: 0, y: 23.0144 * sy))
        path.addCurve(
            to: CGPoint(x: 29.4468 * sx, y: 0.936342 * sy),
            control1: CGPoint(x: 0, y: 7.67809 * sy),
            control2: CGPoint(x: 14.7253 * sx, y: -3.36233 * sy)
        )
        path.addLine(to: CGPoint(x: 60.2687 * sx, y: 9.93632 * sy))
        path.addCurve(
            to: CGPoint(x: 69.8598 * sx, y: 14.7337 * sy),
            control1: CGPoint(x: 63.7279 * sx, y: 10.9464 * sy),
            control2: CGPoint(x: 66.9769 * sx, y: 12.5715 * sy)
        )
        path.addLine(to: CGPoint(x: 74.0561 * sx, y: 17.881 * sy))
        path.addCurve(
            to: CGPoint(x: 86.1727 * sx, y: 23.2984 * sy),
            control1: CGPoint(x: 77.6399 * sx, y: 20.5688 * sy),
            control2: CGPoint(x: 81.78 * sx, y: 22.4199 * sy)
        )
        path.addLine(to: CGPoint(x: 178.367 * sx, y: 41.737 * sy))
        path.addCurve(
            to: CGPoint(x: 202 * sx, y: 70.5649 * sy),
            control1: CGPoint(x: 192.108 * sx, y: 44.4853 * sy),
            control2: CGPoint(x: 202 * sx, y: 56.551 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 172.601 * sx, y: 99.9636 * sy),
            control1: CGPoint(x: 202 * sx, y: 86.8014 * sy),
            control2: CGPoint(x: 188.838 * sx, y: 99.9636 * sy)
        )
        path.addLine(to: CGPoint(x: 30 * sx, y: 99.9636 * sy))
        path.addCurve(
            to: CGPoint(x: 0, y: 69.9636 * sy),
            control1: CGPoint(x: 13.4315 * sx, y: 99.9636 * sy),
            control2: CGPoint(x: 0, y: 86.5322 * sy)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Folder Shape 9b (middle wave mirrored, 202x160)

struct FolderShape9b: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 202
        let sy = rect.height / 160

        var path = Path()
        path.move(to: CGPoint(x: 202 * sx, y: 129.964 * sy))
        path.addLine(to: CGPoint(x: 202 * sx, y: 23.0144 * sy))
        path.addCurve(
            to: CGPoint(x: 172.553 * sx, y: 0.936342 * sy),
            control1: CGPoint(x: 202 * sx, y: 7.67809 * sy),
            control2: CGPoint(x: 187.275 * sx, y: -3.36233 * sy)
        )
        path.addLine(to: CGPoint(x: 141.731 * sx, y: 9.93632 * sy))
        path.addCurve(
            to: CGPoint(x: 132.14 * sx, y: 14.7337 * sy),
            control1: CGPoint(x: 138.272 * sx, y: 10.9464 * sy),
            control2: CGPoint(x: 135.023 * sx, y: 12.5715 * sy)
        )
        path.addLine(to: CGPoint(x: 127.944 * sx, y: 17.881 * sy))
        path.addCurve(
            to: CGPoint(x: 115.827 * sx, y: 23.2984 * sy),
            control1: CGPoint(x: 124.36 * sx, y: 20.5688 * sy),
            control2: CGPoint(x: 120.22 * sx, y: 22.4199 * sy)
        )
        path.addLine(to: CGPoint(x: 24.1166 * sx, y: 41.6404 * sy))
        path.addCurve(
            to: CGPoint(x: 0, y: 71.0578 * sy),
            control1: CGPoint(x: 10.0938 * sx, y: 44.4449 * sy),
            control2: CGPoint(x: 0, y: 56.7573 * sy)
        )
        path.addLine(to: CGPoint(x: 0, y: 129.964 * sy))
        path.addCurve(
            to: CGPoint(x: 30 * sx, y: 159.964 * sy),
            control1: CGPoint(x: 0, y: 146.532 * sy),
            control2: CGPoint(x: 13.4315 * sx, y: 159.964 * sy)
        )
        path.addLine(to: CGPoint(x: 172 * sx, y: 159.964 * sy))
        path.addCurve(
            to: CGPoint(x: 202 * sx, y: 129.964 * sy),
            control1: CGPoint(x: 188.569 * sx, y: 159.964 * sy),
            control2: CGPoint(x: 202 * sx, y: 146.532 * sy)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Folder Shape 9c (back rounded rect, 202x204)

struct FolderShape9c: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 202
        let sy = rect.height / 204

        var path = Path()
        path.move(to: CGPoint(x: 0, y: 173.626 * sy))
        path.addLine(to: CGPoint(x: 0, y: 23 * sy))
        path.addCurve(
            to: CGPoint(x: 23 * sx, y: 0),
            control1: CGPoint(x: 0, y: 10.2975 * sy),
            control2: CGPoint(x: 10.2975 * sx, y: 0)
        )
        path.addLine(to: CGPoint(x: 172 * sx, y: 0))
        path.addCurve(
            to: CGPoint(x: 202 * sx, y: 30 * sy),
            control1: CGPoint(x: 188.569 * sx, y: 0),
            control2: CGPoint(x: 202 * sx, y: 13.4314 * sy)
        )
        path.addLine(to: CGPoint(x: 202 * sx, y: 173.626 * sy))
        path.addCurve(
            to: CGPoint(x: 172 * sx, y: 203.626 * sy),
            control1: CGPoint(x: 202 * sx, y: 190.194 * sy),
            control2: CGPoint(x: 188.569 * sx, y: 203.626 * sy)
        )
        path.addLine(to: CGPoint(x: 30 * sx, y: 203.626 * sy))
        path.addCurve(
            to: CGPoint(x: 0, y: 173.626 * sy),
            control1: CGPoint(x: 13.4315 * sx, y: 203.626 * sy),
            control2: CGPoint(x: 0, y: 190.194 * sy)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Folder Tab Right Shape (tab notch top-right, width 203)

struct FolderTabRightShape: Shape {
    let viewBoxHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 203
        let sy = rect.height / viewBoxHeight
        let bottomY = viewBoxHeight - 11.5
        let edgeY = viewBoxHeight - 0.5

        var path = Path()
        path.move(to: CGPoint(x: 203 * sx, y: bottomY * sy))
        path.addLine(to: CGPoint(x: 203 * sx, y: 11 * sy))
        path.addCurve(
            to: CGPoint(x: 192 * sx, y: 0),
            control1: CGPoint(x: 203 * sx, y: 4.92487 * sy),
            control2: CGPoint(x: 198.075 * sx, y: 0)
        )
        path.addLine(to: CGPoint(x: 155.556 * sx, y: 0))
        path.addCurve(
            to: CGPoint(x: 147.778 * sx, y: 3.22183 * sy),
            control1: CGPoint(x: 152.639 * sx, y: 0),
            control2: CGPoint(x: 149.841 * sx, y: 1.15893 * sy)
        )
        path.addLine(to: CGPoint(x: 140.722 * sx, y: 10.2782 * sy))
        path.addCurve(
            to: CGPoint(x: 132.944 * sx, y: 13.5 * sy),
            control1: CGPoint(x: 138.659 * sx, y: 12.3411 * sy),
            control2: CGPoint(x: 135.861 * sx, y: 13.5 * sy)
        )
        path.addLine(to: CGPoint(x: 11 * sx, y: 13.5 * sy))
        path.addCurve(
            to: CGPoint(x: 0, y: 24.5 * sy),
            control1: CGPoint(x: 4.92487 * sx, y: 13.5 * sy),
            control2: CGPoint(x: 0, y: 18.4249 * sy)
        )
        path.addLine(to: CGPoint(x: 0, y: bottomY * sy))
        path.addCurve(
            to: CGPoint(x: 11 * sx, y: edgeY * sy),
            control1: CGPoint(x: 0, y: (bottomY + 6.075) * sy),
            control2: CGPoint(x: 4.92487 * sx, y: edgeY * sy)
        )
        path.addLine(to: CGPoint(x: 192 * sx, y: edgeY * sy))
        path.addCurve(
            to: CGPoint(x: 203 * sx, y: bottomY * sy),
            control1: CGPoint(x: 198.075 * sx, y: edgeY * sy),
            control2: CGPoint(x: 203 * sx, y: (bottomY + 6.075) * sy)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Folder Tab Left Shape (tab notch top-left, width 203)

struct FolderTabLeftShape: Shape {
    let viewBoxHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 203
        let sy = rect.height / viewBoxHeight
        let bottomY = viewBoxHeight - 11.5
        let edgeY = viewBoxHeight - 0.5

        var path = Path()
        path.move(to: CGPoint(x: 0, y: bottomY * sy))
        path.addLine(to: CGPoint(x: 0, y: 11 * sy))
        path.addCurve(
            to: CGPoint(x: 11 * sx, y: 0),
            control1: CGPoint(x: 0, y: 4.92487 * sy),
            control2: CGPoint(x: 4.92487 * sx, y: 0)
        )
        path.addLine(to: CGPoint(x: 47.4436 * sx, y: 0))
        path.addCurve(
            to: CGPoint(x: 55.2218 * sx, y: 3.22183 * sy),
            control1: CGPoint(x: 50.361 * sx, y: 0),
            control2: CGPoint(x: 53.1589 * sx, y: 1.15893 * sy)
        )
        path.addLine(to: CGPoint(x: 62.2782 * sx, y: 10.2782 * sy))
        path.addCurve(
            to: CGPoint(x: 70.0564 * sx, y: 13.5 * sy),
            control1: CGPoint(x: 64.3411 * sx, y: 12.3411 * sy),
            control2: CGPoint(x: 67.139 * sx, y: 13.5 * sy)
        )
        path.addLine(to: CGPoint(x: 192 * sx, y: 13.5 * sy))
        path.addCurve(
            to: CGPoint(x: 203 * sx, y: 24.5 * sy),
            control1: CGPoint(x: 198.075 * sx, y: 13.5 * sy),
            control2: CGPoint(x: 203 * sx, y: 18.4249 * sy)
        )
        path.addLine(to: CGPoint(x: 203 * sx, y: bottomY * sy))
        path.addCurve(
            to: CGPoint(x: 192 * sx, y: edgeY * sy),
            control1: CGPoint(x: 203 * sx, y: (bottomY + 6.075) * sy),
            control2: CGPoint(x: 198.075 * sx, y: edgeY * sy)
        )
        path.addLine(to: CGPoint(x: 11 * sx, y: edgeY * sy))
        path.addCurve(
            to: CGPoint(x: 0, y: bottomY * sy),
            control1: CGPoint(x: 4.92487 * sx, y: edgeY * sy),
            control2: CGPoint(x: 0, y: (bottomY + 6.075) * sy)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Folder Shape 6 (front - trapezoid, 197x151)

struct FolderShape6: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 197
        let sy = rect.height / 151

        var path = Path()
        path.move(to: CGPoint(x: 180.804 * sx, y: 0))
        path.addLine(to: CGPoint(x: 16.0007 * sx, y: 0))
        path.addCurve(
            to: CGPoint(x: 0.0359496 * sx, y: 17.0608 * sy),
            control1: CGPoint(x: 6.74672 * sx, y: 0),
            control2: CGPoint(x: -0.577583 * sx, y: 7.8271 * sy)
        )
        path.addLine(to: CGPoint(x: 7.90971 * sx, y: 135.561 * sy))
        path.addCurve(
            to: CGPoint(x: 23.8745 * sx, y: 150.5 * sy),
            control1: CGPoint(x: 8.46826 * sx, y: 143.967 * sy),
            control2: CGPoint(x: 15.4497 * sx, y: 150.5 * sy)
        )
        path.addLine(to: CGPoint(x: 172.93 * sx, y: 150.5 * sy))
        path.addCurve(
            to: CGPoint(x: 188.895 * sx, y: 135.561 * sy),
            control1: CGPoint(x: 181.355 * sx, y: 150.5 * sy),
            control2: CGPoint(x: 188.336 * sx, y: 143.967 * sy)
        )
        path.addLine(to: CGPoint(x: 196.769 * sx, y: 17.0608 * sy))
        path.addCurve(
            to: CGPoint(x: 180.804 * sx, y: 0),
            control1: CGPoint(x: 197.382 * sx, y: 7.82712 * sy),
            control2: CGPoint(x: 190.058 * sx, y: 0)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Folder Shape 7 (back - trapezoid with tab, 203x201)

struct FolderShape7: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 203
        let sy = rect.height / 201

        var path = Path()
        path.move(to: CGPoint(x: 192.41 * sx, y: 186.055 * sy))
        path.addLine(to: CGPoint(x: 202.294 * sx, y: 36.5555 * sy))
        path.addCurve(
            to: CGPoint(x: 186.329 * sx, y: 19.5 * sy),
            control1: CGPoint(x: 202.905 * sx, y: 27.3238 * sy),
            control2: CGPoint(x: 195.581 * sx, y: 19.5 * sy)
        )
        path.addLine(to: CGPoint(x: 104.931 * sx, y: 19.5 * sy))
        path.addCurve(
            to: CGPoint(x: 99.118 * sx, y: 18.4065 * sy),
            control1: CGPoint(x: 102.943 * sx, y: 19.5 * sy),
            control2: CGPoint(x: 100.971 * sx, y: 19.1292 * sy)
        )
        path.addLine(to: CGPoint(x: 54.7258 * sx, y: 1.09353 * sy))
        path.addCurve(
            to: CGPoint(x: 48.9123 * sx, y: 0),
            control1: CGPoint(x: 52.8728 * sx, y: 0.370846 * sy),
            control2: CGPoint(x: 50.9012 * sx, y: 0)
        )
        path.addLine(to: CGPoint(x: 11.0004 * sx, y: 0))
        path.addCurve(
            to: CGPoint(x: 0.0148677 * sx, y: 11.5634 * sy),
            control1: CGPoint(x: 4.70401 * sx, y: 0),
            control2: CGPoint(x: -0.307602 * sx, y: 5.2752 * sy)
        )
        path.addLine(to: CGPoint(x: 0.421875 * sx, y: 19.5 * sy))
        path.addLine(to: CGPoint(x: 11.4338 * sx, y: 186.056 * sy))
        path.addCurve(
            to: CGPoint(x: 27.399 * sx, y: 201 * sy),
            control1: CGPoint(x: 11.9897 * sx, y: 194.464 * sy),
            control2: CGPoint(x: 18.9722 * sx, y: 201 * sy)
        )
        path.addLine(to: CGPoint(x: 176.445 * sx, y: 201 * sy))
        path.addCurve(
            to: CGPoint(x: 192.41 * sx, y: 186.055 * sy),
            control1: CGPoint(x: 184.872 * sx, y: 201 * sy),
            control2: CGPoint(x: 191.854 * sx, y: 194.464 * sy)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Folder Shape 5

struct FolderShape5: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 202
        let sy = rect.height / 202

        var path = Path()
        path.move(to: CGPoint(x: 90.463 * sx, y: 0))
        path.addLine(to: CGPoint(x: 16 * sx, y: 0))
        path.addCurve(
            to: CGPoint(x: 0, y: 16 * sy),
            control1: CGPoint(x: 7.16344 * sx, y: 0),
            control2: CGPoint(x: 0, y: 7.16345 * sy)
        )
        path.addLine(to: CGPoint(x: 0, y: 185.5 * sy))
        path.addCurve(
            to: CGPoint(x: 16 * sx, y: 201.5 * sy),
            control1: CGPoint(x: 0, y: 194.337 * sy),
            control2: CGPoint(x: 7.16345 * sx, y: 201.5 * sy)
        )
        path.addLine(to: CGPoint(x: 185.5 * sx, y: 201.5 * sy))
        path.addCurve(
            to: CGPoint(x: 201.5 * sx, y: 185.5 * sy),
            control1: CGPoint(x: 194.337 * sx, y: 201.5 * sy),
            control2: CGPoint(x: 201.5 * sx, y: 194.337 * sy)
        )
        path.addLine(to: CGPoint(x: 201.5 * sx, y: 110.927 * sy))
        path.addCurve(
            to: CGPoint(x: 189.675 * sx, y: 95.4818 * sy),
            control1: CGPoint(x: 201.5 * sx, y: 103.699 * sy),
            control2: CGPoint(x: 196.653 * sx, y: 97.368 * sy)
        )
        path.addLine(to: CGPoint(x: 133.7 * sx, y: 80.3517 * sy))
        path.addCurve(
            to: CGPoint(x: 122.502 * sx, y: 69.3406 * sy),
            control1: CGPoint(x: 128.299 * sx, y: 78.8917 * sy),
            control2: CGPoint(x: 124.053 * sx, y: 74.7164 * sy)
        )
        path.addLine(to: CGPoint(x: 105.836 * sx, y: 11.5654 * sy))
        path.addCurve(
            to: CGPoint(x: 90.463 * sx, y: 0),
            control1: CGPoint(x: 103.86 * sx, y: 4.71607 * sy),
            control2: CGPoint(x: 97.5916 * sx, y: 0)
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
    @Environment(FavoritesManager.self) private var favoritesManager
    var favoritesOnly = false

    private func heartButton(for id: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                favoritesManager.toggle(id)
            }
        } label: {
            Image(systemName: favoritesManager.isFavorited(id) ? "heart.fill" : "heart")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(favoritesManager.isFavorited(id) ? .red : .black.opacity(0.3))
        }
    }

    private var folderEntries: [(id: String, section: AnyView)] {
        [
            ("folder1", AnyView(folder1Section)),
            ("folder2", AnyView(folder2Section)),
            ("folder3", AnyView(folder3Section)),
            ("folder4", AnyView(folder4Section)),
            ("folder5", AnyView(folder5Section)),
            ("folder6", AnyView(folder6Section)),
            ("folder7", AnyView(folder7Section)),
            ("folder8", AnyView(folder8Section)),
            ("folder9", AnyView(folder9Section)),
            ("folder10", AnyView(folder10Section)),
            ("folder11", AnyView(folder11Section))
        ]
    }

    var body: some View {
        ScrollView {
            if favoritesOnly {
                let favorited = folderEntries.filter { favoritesManager.isFavorited($0.id) }
                if favorited.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(.black.opacity(0.15))
                        Text("No favourites yet")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.black.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 120)
                } else {
                    ForEach(favorited, id: \.id) { entry in
                        entry.section
                    }
                }
            } else {
                folder1Section
                folder2Section
                folder3Section
                folder4Section
                folder5Section
                folder6Section
                folder7Section
                folder8Section
                folder9Section
                folder10Section
                folder11Section
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !favoritesOnly {
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

    // MARK: - Folder 1
    private var folder1Section: some View {
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
        .overlay(alignment: .topTrailing) { heartButton(for: "folder1").padding(14) }
        .padding(.horizontal, 12)
    }

    // MARK: - Folder 2
    private var folder2Section: some View {
        VStack(spacing: 32) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    .frame(width: 155, height: 105)
                    .offset(y: -18)

                Image("card3")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 72)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 12, bottomLeading: 12, bottomTrailing: 12, topTrailing: 12), style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 12, bottomLeading: 12, bottomTrailing: 12, topTrailing: 12), style: .continuous).stroke(Color.black.opacity(0.2), lineWidth: 1).padding(-1))
                    .padding(8)
                    .background(Color.white, in: .rect(cornerRadius: 14, style: .continuous))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 14, bottomLeading: 14, bottomTrailing: 14, topTrailing: 14), style: .continuous).stroke(Color.black.opacity(0.2), lineWidth: 1))
                    .rotationEffect(.degrees(-15))
                    .offset(x: -64 + (animate ? 1 : -1), y: -12 + (animate ? -0.5 : 0.5))

                Image("card1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 72)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 12, bottomLeading: 12, bottomTrailing: 12, topTrailing: 12), style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 12, bottomLeading: 12, bottomTrailing: 12, topTrailing: 12), style: .continuous).stroke(Color.black.opacity(0.2), lineWidth: 1).padding(-1))
                    .padding(8)
                    .background(Color.white, in: .rect(cornerRadius: 14, style: .continuous))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 14, bottomLeading: 14, bottomTrailing: 14, topTrailing: 14), style: .continuous).stroke(Color.black.opacity(0.2), lineWidth: 1))
                    .rotationEffect(.degrees(3))
                    .offset(x: 0 + (animate ? -0.5 : 0.5), y: -49 + (animate ? 1 : -1))

                Image("card2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 72)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 12, bottomLeading: 12, bottomTrailing: 12, topTrailing: 12), style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 12, bottomLeading: 12, bottomTrailing: 12, topTrailing: 12), style: .continuous).stroke(Color.black.opacity(0.2), lineWidth: 1).padding(-1))
                    .padding(8)
                    .background(Color.white, in: .rect(cornerRadius: 14, style: .continuous))
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 14, bottomLeading: 14, bottomTrailing: 14, topTrailing: 14), style: .continuous).stroke(Color.black.opacity(0.2), lineWidth: 1))
                    .rotationEffect(.degrees(12))
                    .offset(x: 58 + (animate ? 0.5 : -0.5), y: -16 + (animate ? -1 : 1))

                ContainerShape()
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.65), location: 0.55),
                            .init(color: Color.white.opacity(0.75), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .overlay(
                        ContainerShape()
                            .stroke(LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.white.opacity(1.0), location: 0.0),
                                    .init(color: Color.white.opacity(0.0), location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ), lineWidth: 2)
                    )
                    .overlay(
                        ContainerShape()
                            .stroke(Color.black.opacity(0.25), lineWidth: 1)
                    )
                    .overlay(alignment: .bottom) {
                        VStack(spacing: 6) {
                            Capsule()
                                .fill(Color.white.opacity(1))
                                .frame(width: 130, height: 2.8)
                                .shadow(color: .black.opacity(0.35), radius: 10, y: 0)
                            Capsule()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 130, height: 2.8)
                                .shadow(color: .black.opacity(0.35), radius: 10, y: 0)
                        }
                        .padding(.bottom, 16)
                    }
                    .overlay {
                        Image("catSticker")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                            .rotationEffect(.degrees(-12))
                            .offset(x: -35, y: -5)
                            .shadow(color: .black.opacity(0.25), radius: 1)
                            .shadow(color: .black.opacity(0.2), radius: 8)

                        Image("japaneseSticker")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 64)
                            .rotationEffect(.degrees(24))
                            .offset(x: 30, y: 12)
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
        .overlay(alignment: .topTrailing) { heartButton(for: "folder2").padding(14) }
        .padding(.horizontal, 12)
    }

    // MARK: - Folder 3
    private var folder3Section: some View {
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

                Image("card3")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 125)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(0))
                    .offset(x: 30, y: -30)

                Image("card1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 125)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(3))
                    .offset(x: -2, y: -36)

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
        .overlay(alignment: .topTrailing) { heartButton(for: "folder3").padding(14) }
        .padding(.horizontal, 12)
    }

    // MARK: - Folder 4
    private var folder4Section: some View {
        VStack(spacing: 32) {
            ZStack(alignment: .bottom) {
                Image("card3")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 135, height: 210)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 6))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(8))
                    .offset(x: 12, y: -15)

                Image("card2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 135, height: 210)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 6))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(3))
                    .offset(x: -24, y: -15)

                FolderShape3()
                    .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.8))
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
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

                Image("signature")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 55)
                    .frame(width: 228, height: 200, alignment: .bottomLeading)
                    .opacity(0.7)
                    .rotationEffect(.degrees(25))
                    .offset(x: 54, y: 12)

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
        .overlay(alignment: .topTrailing) { heartButton(for: "folder4").padding(14) }
        .padding(.horizontal, 12)
    }

    // MARK: - Folder 5
    private var folder5Section: some View {
        VStack(spacing: 32) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 39)
                    .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(1))
                    .frame(width: 191, height: 193)

                Image("card3")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(0))
                    .offset(x: 30, y: -30)

                Image("card1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(3))
                    .offset(x: -2, y: -36)

                Image("card2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(0))
                    .offset(x: -36, y: -42)

                FolderShape4()
                    .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.8))
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
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
            .scaleEffect(1.20)
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
        .overlay(alignment: .topTrailing) { heartButton(for: "folder5").padding(14) }
        .padding(.horizontal, 12)
    }

    // MARK: - Folder 6
    private var folder6Section: some View {
        VStack(spacing: 32) {
            ZStack(alignment: .bottom) {
                // Card 3 (back)
                Image("card3")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 125)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(0))
                    .offset(x: 30 + (animate ? 1 : -1), y: -30 + (animate ? -0.5 : 0.5))

                // Card 1 (middle)
                Image("card1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 125)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(3))
                    .offset(x: -2 + (animate ? -0.5 : 0.5), y: -36 + (animate ? 1 : -1))

                // Card 2 (front)
                Image("card2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 125)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(0))
                    .offset(x: -36 + (animate ? 0.5 : -0.5), y: -42 + (animate ? -1 : 1))

                // Front folder shape
                FolderShape5()
                    .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.8))
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0), location: 0),
                            .init(color: Color.white.opacity(1), location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .stroke(Color.white.opacity(0.45), lineWidth: 3)
                    .frame(width: 202, height: 202)
                    .glassEffect(.clear, in: FolderShape5())
                    .overlay(alignment: .topLeading) {
                        Text("Japan is generating\nelectricity with footsteps")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.leading, 12)
                            .padding(.top, 12)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text("2027")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.leading, 12)
                            .padding(.bottom, 12)
                    }
            }
            .shadow(color: .black.opacity(0.15), radius: 12, y: 8)
            Text("Folder Design 6")
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
        .overlay(alignment: .topTrailing) { heartButton(for: "folder6").padding(14) }
        .padding(.horizontal, 12)
    }

    // MARK: - Folder 7
    private var folder7Section: some View {
        VStack(spacing: 32) {
            ZStack(alignment: .bottom) {
                // SVG 2 - Back layer (trapezoid with tab) - grey gradient
                FolderShape7()
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.gray.opacity(0.4), location: 0),
                            .init(color: Color.gray.opacity(0.7), location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 203, height: 201)

                // Card 3 (back)
                Image("card3")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 125)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(0))
                    .offset(x: 30 + (animate ? 1 : -1), y: -30 + (animate ? -0.5 : 0.5))

                // Card 1 (middle)
                Image("card1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 125)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(3))
                    .offset(x: -2 + (animate ? -0.5 : 0.5), y: -36 + (animate ? 1 : -1))

                // Card 2 (front)
                Image("card2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 125)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(0))
                    .offset(x: -36 + (animate ? 0.5 : -0.5), y: -42 + (animate ? -1 : 1))

                // SVG 1 - Front layer (trapezoid)
                FolderShape6()
                    .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.8))
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0), location: 0),
                            .init(color: Color.white.opacity(1), location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .stroke(Color.white.opacity(0.45), lineWidth: 3)
                    .frame(width: 197, height: 151)
                    .glassEffect(.clear, in: FolderShape6())
            }
            .shadow(color: .black.opacity(0.15), radius: 12, y: 8)
            Text("Folder Design 7")
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
        .overlay(alignment: .topTrailing) { heartButton(for: "folder7").padding(14) }
        .padding(.horizontal, 12)
    }

    // MARK: - Folder 8
    private var folder8Section: some View {
        VStack(spacing: 32) {
            ZStack(alignment: .bottom) {
                // SVG 5 (back) - right tab, 203x202, #D7D7DC
                FolderTabRightShape(viewBoxHeight: 202)
                    .fill(Color(red: 0xD7/255, green: 0xD7/255, blue: 0xDC/255))
                    .frame(width: 203, height: 202)

                // SVG 4 - left tab, 203x195, #C3C3C8
                FolderTabLeftShape(viewBoxHeight: 195)
                    .fill(Color(red: 0xC3/255, green: 0xC3/255, blue: 0xC8/255))
                    .frame(width: 203, height: 195)

                // SVG 3 - right tab, 203x188, #AFAFB4
                FolderTabRightShape(viewBoxHeight: 188)
                    .fill(Color(red: 0xAF/255, green: 0xAF/255, blue: 0xB4/255))
                    .frame(width: 203, height: 188)

                // SVG 2 - left tab, 203x181, #9B9BA0
                FolderTabLeftShape(viewBoxHeight: 181)
                    .fill(Color(red: 0x9B/255, green: 0x9B/255, blue: 0xA0/255))
                    .frame(width: 203, height: 181)

                // SVG 1 (front) - right tab, 203x174
                FolderTabRightShape(viewBoxHeight: 174)
                    .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.8))
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0), location: 0),
                            .init(color: Color.white.opacity(1), location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .stroke(Color.white.opacity(0.45), lineWidth: 3)
                    .frame(width: 203, height: 174)
                    .glassEffect(.clear, in: FolderTabRightShape(viewBoxHeight: 174))
                    .overlay(alignment: .bottomLeading) {
                        Text("さっぽろ")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.leading, 8)
                            .padding(.bottom, 8)
                    }
            }
            .shadow(color: .black.opacity(0.15), radius: 12, y: 8)
            Text("Folder Design 8")
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
        .overlay(alignment: .topTrailing) { heartButton(for: "folder8").padding(14) }
        .padding(.horizontal, 12)
    }

    // MARK: - Folder 9
    private var folder9Section: some View {
        VStack(spacing: 32) {
            ZStack(alignment: .bottom) {
                // SVG 3 (back) - rounded rect, 202x204, light grey gradient
                FolderShape9c()
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.gray.opacity(0.2), location: 0),
                            .init(color: Color.gray.opacity(0.4), location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .stroke(Color.white.opacity(0.45), lineWidth: 3)
                    .frame(width: 202, height: 204)

                // Card 2 - behind SVG 2
                Image("card2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 125)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(3))
                    .offset(x: 20 + (animate ? 0.5 : -0.5), y: -30 + (animate ? -1 : 1))

                // SVG 2 (middle) - wave mirrored, 202x160
                FolderShape9b()
                    .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.8))
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0), location: 0),
                            .init(color: Color.white.opacity(1), location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .stroke(Color.white.opacity(0.45), lineWidth: 3)
                    .frame(width: 202, height: 160)

                // Card 1 - behind SVG 1
                Image("card1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 125)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(-3))
                    .offset(x: -20 + (animate ? -0.5 : 0.5), y: -20 + (animate ? 1 : -1))

                // SVG 1 (front) - wave, 202x100
                FolderShape9a()
                    .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.8))
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0), location: 0),
                            .init(color: Color.white.opacity(1), location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .stroke(Color.white.opacity(0.45), lineWidth: 3)
                    .frame(width: 202, height: 100)
                    .glassEffect(.clear, in: FolderShape9a())
                    .overlay(alignment: .bottomLeading) {
                        Text("鹿児島")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                            .padding(.leading, 8)
                            .padding(.bottom, 8)
                    }
            }
            .shadow(color: .black.opacity(0.15), radius: 12, y: 8)
            Text("Folder Design 9")
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
        .overlay(alignment: .topTrailing) { heartButton(for: "folder9").padding(14) }
        .padding(.horizontal, 12)
    }

    // MARK: - Folder 10
    private var folder10Section: some View {
        VStack(spacing: 32) {
            ZStack(alignment: .bottom) {
                // SVG 2 (back) - rounded rect, 389x289, light grey gradient
                FolderShape10b()
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.gray.opacity(0.2), location: 0),
                            .init(color: Color.gray.opacity(0.45), location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 200, height: 149)

                // Card 3 (back)
                Image("card3")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 125)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(0))
                    .offset(x: 30 + (animate ? 1 : -1), y: -10 + (animate ? -0.5 : 0.5))

                // Card 1 (middle)
                Image("card1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 125)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(3))
                    .offset(x: -2 + (animate ? -0.5 : 0.5), y: -16 + (animate ? 1 : -1))

                // Card 2 (front)
                Image("card2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 125)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(0))
                    .offset(x: -36 + (animate ? 0.5 : -0.5), y: -22 + (animate ? -1 : 1))

                // SVG 1 (front) - envelope, 200x135
                FolderShape10a()
                    .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.8))
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0), location: 0),
                            .init(color: Color.white.opacity(1), location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .stroke(Color.white.opacity(0.45), lineWidth: 3)
                    .frame(width: 200, height: 135)
                    .glassEffect(.clear, in: FolderShape10a())
            }
            .shadow(color: .black.opacity(0.15), radius: 12, y: 8)
            Text("Folder Design 10")
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
        .overlay(alignment: .topTrailing) { heartButton(for: "folder10").padding(14) }
        .padding(.horizontal, 12)
    }

    // MARK: - Folder 11
    private var folder11Section: some View {
        VStack(spacing: 32) {
            ZStack(alignment: .bottom) {
                // SVG 2 (back) - notched corners without tab, light grey horizontal gradient
                FolderShape11b()
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.gray.opacity(0.25), location: 0),
                            .init(color: Color.gray.opacity(0.45), location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: 205, height: 201)

                // Card 1 - near top right corner
                Image("card1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 125)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .rotationEffect(.degrees(5))
                    .offset(x: 30, y: -60)

                // SVG 1 (front) - notched corners with tab
                FolderShape11a()
                    .fill(Color(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255).opacity(0.8))
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0), location: 0),
                            .init(color: Color.white.opacity(1), location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .stroke(Color.white.opacity(0.45), lineWidth: 3)
                    .frame(width: 205, height: 201)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .glassEffect(.clear, in: FolderShape11a())
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("広島")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.black)
                            Text("ひろしま")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.black.opacity(0.45))
                        }
                        .padding(.leading, 12)
                        .padding(.bottom, 12)
                    }
            }
            .shadow(color: .black.opacity(0.15), radius: 12, y: 8)
            Text("Folder Design 11")
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
        .overlay(alignment: .topTrailing) { heartButton(for: "folder11").padding(14) }
        .padding(.horizontal, 12)
    }
}

#Preview {
    FolderExample()
        .environment(FavoritesManager())
}
