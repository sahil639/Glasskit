//
//  CirclePackingChartExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Data Models

struct CirclePackGroup: Identifiable {
    let id = UUID()
    var name: String
    var color: Color
    var items: [CirclePackItem]
}

struct CirclePackItem: Identifiable {
    let id = UUID()
    var label: String
    var value: Double
    var parentGroupID: UUID?
    var color: Color
}

// MARK: - Enums

enum CPLayout: String, CaseIterable { case packed = "Packed", clustered = "Clustered" }
enum CPSizeMode: String, CaseIterable { case absolute_ = "Absolute", relative = "Relative" }
enum CPColorMode: String, CaseIterable { case single = "Single", byLevel = "By Level", byCategory = "Category", byValue = "By Value" }
enum CPLabelContent: String, CaseIterable { case label = "Label", value = "Value", both = "Both" }
enum CPLabelPos: String, CaseIterable { case center = "Center", inside_ = "Inside", hidden = "Hidden" }
enum CPOverflow: String, CaseIterable { case wrap = "Wrap", truncate = "Truncate" }
enum CPSort: String, CaseIterable { case default_ = "Default", asc = "Asc", desc = "Desc" }

// MARK: - Packed Circle

struct PackedCircle {
    var id: UUID
    var label: String
    var value: Double
    var radius: CGFloat
    var center: CGPoint
    var color: Color
    var depth: Int
    var isGroup: Bool
    var groupID: UUID?
}

// MARK: - Circle Packing Card

struct CirclePackingCard: View {

    let title: String
    let categories: [String]
    @State private var groups: [CirclePackGroup]
    @State private var isExpanded = false
    @State private var appeared = false
    @State private var highlightedID: UUID? = nil
    @State private var drillGroupID: UUID? = nil
    @State private var tooltipID: UUID? = nil
    @State private var chartSize: CGSize = .zero
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragTranslation: CGSize = .zero

    // Layout
    @State private var layoutMode: CPLayout = .packed
    @State private var circlePadding: Double = 4
    @State private var chartPadding: Double = 16
    @State private var autoLayout: Bool = true

    // Hierarchy
    @State private var maxDepth: Int = 2
    @State private var groupMode: Bool = true
    @State private var drillDown: Bool = true
    @State private var showBreadcrumb: Bool = true

    // Value Scaling
    @State private var sizeMode: CPSizeMode = .relative
    @State private var normalizeValues: Bool = false

    // Circle Styling
    @State private var minCircleSize: Double = 12
    @State private var maxCircleSize: Double = 80
    @State private var circleStroke: Bool = true
    @State private var strokeWidth: Double = 0.5
    @State private var shadowEnabled: Bool = true
    @State private var fillOpacity: Double = 0.85

    // Color
    @State private var colorMode: CPColorMode = .byCategory
    @State private var primaryColor: Color = CirclePackingCard.colorPalette[0]
    @State private var colorScale: Bool = true
    @State private var gradientMode: Bool = true

    // Labels
    @State private var showLabels: Bool = true
    @State private var labelContent: CPLabelContent = .both
    @State private var labelPos: CPLabelPos = .center
    @State private var textOverflow: CPOverflow = .truncate

    // Interaction
    @State private var hoverHighlight: Bool = true
    @State private var hoverTooltip: Bool = true
    @State private var zoomPanEnabled: Bool = false
    @State private var animateOnLoad: Bool = true
    @State private var animationDuration: Double = 0.7

    // Focus & Navigation
    @State private var focusMode: Bool = false
    @State private var autoCenter: Bool = false

    // Sorting
    @State private var sortMode: CPSort = .default_

    static let colorPalette = AnalyticsCard.colorPalette

    init(title: String, categories: [String], groups: [CirclePackGroup]) {
        self.title = title
        self.categories = categories
        self._groups = State(initialValue: groups)
    }

    // MARK: - Layout

    func computeLayout(size: CGSize) -> [PackedCircle] {
        let cx = size.width / 2
        let cy = size.height / 2
        let pad = CGFloat(circlePadding)
        let chartPad = CGFloat(chartPadding)
        let maxR = min(size.width, size.height) / 2 - chartPad

        let currentGroups: [CirclePackGroup]
        if let drillID = drillGroupID {
            currentGroups = groups.filter { $0.id == drillID }
        } else {
            currentGroups = groups
        }

        var allItems: [(label: String, value: Double, color: Color, depth: Int, id: UUID, isGroup: Bool, groupID: UUID?)] = []

        if groupMode && drillGroupID == nil {
            for g in currentGroups {
                let totalV = g.items.map { $0.value }.reduce(0, +)
                allItems.append((g.name, max(1, totalV), g.color, 0, g.id, true, nil))
            }
        } else {
            for g in currentGroups {
                var items = g.items
                switch sortMode {
                case .default_: break
                case .asc:  items.sort { $0.value < $1.value }
                case .desc: items.sort { $0.value > $1.value }
                }
                for item in items {
                    allItems.append((item.label, item.value, item.color, 1, item.id, false, g.id))
                }
            }
        }

        if allItems.isEmpty { return [] }

        let maxV = allItems.map { $0.value }.max() ?? 1
        let minV = allItems.map { $0.value }.min() ?? 0
        let minR = CGFloat(minCircleSize)
        let maxR2 = min(CGFloat(maxCircleSize), maxR * 0.7)

        func radius(for v: Double) -> CGFloat {
            if sizeMode == .absolute_ {
                return minR + CGFloat(v / max(1, maxV)) * (maxR2 - minR)
            } else {
                let norm = normalizeValues
                    ? (maxV > minV ? (v - minV) / max(1, maxV - minV) : 0.5)
                    : (v / max(1, maxV))
                return minR + CGFloat(norm) * (maxR2 - minR)
            }
        }

        var circles: [PackedCircle] = []

        for (i, item) in allItems.enumerated() {
            let r = radius(for: item.value)
            let angle = CGFloat(i) * 2.4
            let dist = i == 0 ? 0 : min(maxR - r - 10, sqrt(CGFloat(i)) * (r + 20))
            var center = CGPoint(x: cx + dist * cos(angle), y: cy + dist * sin(angle))

            for _ in 0..<30 {
                var pushed = false
                for placed in circles {
                    let dx = center.x - placed.center.x
                    let dy = center.y - placed.center.y
                    let dist2 = sqrt(dx*dx + dy*dy)
                    let minDist = r + placed.radius + pad
                    if dist2 < minDist && dist2 > 0.1 {
                        let push = (minDist - dist2) * 0.6
                        center.x += push * dx / dist2
                        center.y += push * dy / dist2
                        pushed = true
                    }
                }
                if !pushed { break }
            }

            let clampR = min(r, maxR)
            center.x = max(cx - maxR + clampR, min(cx + maxR - clampR, center.x))
            center.y = max(cy - maxR + clampR, min(cy + maxR - clampR, center.y))

            let col = circleColor(value: item.value, depth: item.depth, category: item.label, id: item.id, maxV: maxV)
            circles.append(PackedCircle(id: item.id, label: item.label, value: item.value,
                                         radius: r, center: center, color: col,
                                         depth: item.depth, isGroup: item.isGroup, groupID: item.groupID))
        }

        return circles
    }

    func circleColor(value: Double, depth: Int, category: String, id: UUID, maxV: Double) -> Color {
        switch colorMode {
        case .single:
            return primaryColor
        case .byLevel:
            return depth == 0 ? CirclePackingCard.colorPalette[0] : CirclePackingCard.colorPalette[2]
        case .byCategory:
            let allLabels = groups.map { $0.name } + groups.flatMap { $0.items.map { $0.label } }
            let uniqueLabels = Array(Set(allLabels)).sorted()
            let idx = uniqueLabels.firstIndex(of: category) ?? 0
            return CirclePackingCard.colorPalette[idx % CirclePackingCard.colorPalette.count]
        case .byValue:
            let t = maxV > 0 ? value / maxV : 0
            return Color(hue: 0.667 - t * 0.667, saturation: 0.75, brightness: 0.85)
        }
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            let size = geo.size
            let circles = computeLayout(size: size)

            ZStack {
                // Group background halos (clustered mode)
                if groupMode && drillGroupID == nil && layoutMode == .clustered {
                    ForEach(groups) { g in
                        let groupCircles = circles.filter { $0.groupID == g.id || ($0.isGroup && $0.id == g.id) }
                        if !groupCircles.isEmpty {
                            let minX = groupCircles.map { $0.center.x - $0.radius }.min() ?? 0
                            let maxX = groupCircles.map { $0.center.x + $0.radius }.max() ?? 0
                            let minY = groupCircles.map { $0.center.y - $0.radius }.min() ?? 0
                            let maxY = groupCircles.map { $0.center.y + $0.radius }.max() ?? 0
                            let haloCenter = CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
                            let haloR = max((maxX - minX), (maxY - minY)) / 2 + 16
                            Circle()
                                .fill(g.color.opacity(0.07))
                                .frame(width: haloR * 2, height: haloR * 2)
                                .position(haloCenter)
                        }
                    }
                }

                // Circles
                ForEach(circles, id: \.id) { c in
                    let isHL = highlightedID == c.id
                    let r = c.radius

                    ZStack {
                        if shadowEnabled {
                            Circle()
                                .fill(c.color.opacity(0.18))
                                .blur(radius: 5)
                                .offset(y: 2)
                                .frame(width: r*2+6, height: r*2+6)
                        }
                        if gradientMode {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [c.color.opacity(fillOpacity * 1.1), c.color.opacity(fillOpacity * 0.6)],
                                        center: UnitPoint(x: 0.3, y: 0.25),
                                        startRadius: 0,
                                        endRadius: r
                                    )
                                )
                                .glassEffect(.clear, in: Circle())
                                .frame(width: r*2, height: r*2)
                        } else {
                            Circle()
                                .fill(c.color.opacity(fillOpacity))
                                .glassEffect(.clear, in: Circle())
                                .frame(width: r*2, height: r*2)
                        }
                        if circleStroke {
                            Circle()
                                .stroke(Color.white.opacity(0.35), lineWidth: CGFloat(strokeWidth))
                                .frame(width: r*2, height: r*2)
                        }
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .blur(radius: 2.5)
                            .opacity(isHL ? 0.45 : 0.22)
                            .clipShape(Circle())
                            .frame(width: r*2, height: r*2)

                        if showLabels && labelPos != .hidden && r > 16 {
                            VStack(spacing: 1) {
                                if labelContent == .label || labelContent == .both {
                                    Text(c.label)
                                        .font(.system(size: min(12, max(8, r * 0.28)), weight: .semibold, design: .rounded))
                                        .foregroundStyle(Color.white.opacity(0.95))
                                        .lineLimit(textOverflow == .wrap ? 2 : 1)
                                        .truncationMode(.tail)
                                        .multilineTextAlignment(.center)
                                }
                                if labelContent == .value || labelContent == .both {
                                    Text(c.value == Double(Int(c.value)) ? "\(Int(c.value))" : String(format: "%.1f", c.value))
                                        .font(.system(size: min(10, max(7, r * 0.22)), weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.white.opacity(0.75))
                                }
                            }
                            .frame(width: r * 1.6)
                        }

                        if c.isGroup && drillDown && r > 20 {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: min(12, r * 0.28)))
                                .foregroundStyle(Color.white.opacity(0.6))
                                .offset(y: r * 0.55)
                        }
                    }
                    .frame(width: r*2, height: r*2)
                    .position(c.center)
                    .scaleEffect(appeared ? 1 : 0.01)
                    .opacity(appeared ? (hoverHighlight && highlightedID != nil && highlightedID != c.id ? 0.35 : 1) : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(animateOnLoad ? Double.random(in: 0...0.3) : 0), value: appeared)
                    .animation(.spring(response: 0.25), value: highlightedID)
                    .onTapGesture {
                        if drillDown && c.isGroup {
                            withAnimation(.spring(response: 0.5)) { drillGroupID = c.id }
                        }
                        withAnimation(.spring(response: 0.3)) {
                            highlightedID = highlightedID == c.id ? nil : c.id
                            tooltipID = hoverTooltip ? (tooltipID == c.id ? nil : c.id) : nil
                        }
                    }
                }

                // Breadcrumb
                if showBreadcrumb && drillGroupID != nil {
                    let groupName = groups.first(where: { $0.id == drillGroupID })?.name ?? ""
                    HStack(spacing: 4) {
                        Button {
                            withAnimation(.spring(response: 0.5)) {
                                drillGroupID = nil
                                highlightedID = nil
                                tooltipID = nil
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "chevron.left").font(.system(size: 10, weight: .semibold))
                                Text("All").font(.system(size: 11, weight: .medium, design: .rounded))
                            }
                            .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right").font(.system(size: 9)).foregroundStyle(.tertiary)
                        Text(groupName).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color(uiColor: .systemBackground).opacity(0.85), in: .capsule)
                    .position(x: size.width / 2, y: 14)
                    .zIndex(10)
                }

                // Tooltip
                if hoverTooltip, let tid = tooltipID, let c = circles.first(where: { $0.id == tid }) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(c.label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        Divider()
                        HStack(spacing: 4) {
                            Text("Value:").font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                            Text(c.value == Double(Int(c.value)) ? "\(Int(c.value))" : String(format: "%.1f", c.value))
                                .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
                        }
                        if c.isGroup {
                            HStack(spacing: 4) {
                                Text("Type:").font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                                Text("Group").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
                            }
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(Color(uiColor: .systemBackground).opacity(0.92), in: .rect(cornerRadius: 8, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    .frame(width: 110)
                    .position(
                        x: min(max(c.center.x, 65), size.width - 65),
                        y: max(c.center.y - c.radius - 30, 30)
                    )
                }
            }
            .background(
                GeometryReader { inner in
                    Color.clear
                        .onAppear { chartSize = inner.size }
                        .onChange(of: inner.size) { _, s in chartSize = s }
                }
            )
            .scaleEffect(zoomPanEnabled ? zoomScale * magnifyBy : 1.0, anchor: .center)
            .offset(
                x: zoomPanEnabled ? panOffset.width + dragTranslation.width : 0,
                y: zoomPanEnabled ? panOffset.height + dragTranslation.height : 0
            )
            .gesture(
                MagnificationGesture()
                    .updating($magnifyBy) { v, s, _ in s = zoomPanEnabled ? v : 1.0 }
                    .onEnded { v in if zoomPanEnabled { zoomScale = min(5, max(0.3, zoomScale * v)) } }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 14)
                    .updating($dragTranslation) { v, s, _ in s = zoomPanEnabled ? v.translation : .zero }
                    .onEnded { v in
                        if zoomPanEnabled {
                            panOffset.width += v.translation.width
                            panOffset.height += v.translation.height
                        }
                    }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    highlightedID = nil
                    tooltipID = nil
                }
            }
            .clipped()
        }
    }

    // MARK: - Settings Helpers

    func settingsSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 10) { content() }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.04), in: .rect(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 4)
    }

    func settingsLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .frame(width: 62, alignment: .leading)
    }

    func pillButton(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(isSelected ? Color.black.opacity(0.1) : Color.clear, in: .capsule)
        }
        .foregroundStyle(isSelected ? .primary : .secondary)
    }

    // MARK: - Settings Sections

    var layoutSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Layout")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(CPLayout.allCases, id: \.self) { mode in
                            pillButton(mode.rawValue, isSelected: layoutMode == mode) { layoutMode = mode }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Circle Pad")
                Slider(value: $circlePadding, in: 0...10)
                Text("\(Int(circlePadding))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Chart Pad")
                Slider(value: $chartPadding, in: 0...60)
                Text("\(Int(chartPadding))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Auto Layout")
                Toggle("", isOn: $autoLayout).labelsHidden().scaleEffect(0.8)
                Text("auto arrange").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    var hierarchySettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Max Depth")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { d in
                            pillButton("\(d)", isSelected: maxDepth == d) { maxDepth = d }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Group Mode")
                Toggle("", isOn: $groupMode).labelsHidden().scaleEffect(0.8)
                Text("show groups").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Drill Down")
                Toggle("", isOn: $drillDown).labelsHidden().scaleEffect(0.8)
                Text("tap to drill").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Breadcrumb")
                Toggle("", isOn: $showBreadcrumb).labelsHidden().scaleEffect(0.8)
                Text("nav trail").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    var valueSizingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Size Mode")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(CPSizeMode.allCases, id: \.self) { mode in
                            pillButton(mode.rawValue, isSelected: sizeMode == mode) { sizeMode = mode }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Normalize")
                Toggle("", isOn: $normalizeValues).labelsHidden().scaleEffect(0.8)
                Text("normalize values").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Min Size")
                Slider(value: $minCircleSize, in: 4...20)
                Text("\(Int(minCircleSize))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Max Size")
                Slider(value: $maxCircleSize, in: 20...120)
                Text("\(Int(maxCircleSize))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    var circleStylingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Stroke")
                Toggle("", isOn: $circleStroke).labelsHidden().scaleEffect(0.8)
                Text("circle border").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if circleStroke {
                HStack(spacing: 10) {
                    settingsLabel("Stroke W")
                    Slider(value: $strokeWidth, in: 0...6)
                    Text(String(format: "%.1f", strokeWidth)).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
            HStack(spacing: 10) {
                settingsLabel("Shadow")
                Toggle("", isOn: $shadowEnabled).labelsHidden().scaleEffect(0.8)
                Text("drop shadow").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Opacity")
                Slider(value: $fillOpacity, in: 0...1)
                Text("\(Int(fillOpacity * 100))%").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    var colorSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Color Mode")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(CPColorMode.allCases, id: \.self) { mode in
                            pillButton(mode.rawValue, isSelected: colorMode == mode) { colorMode = mode }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Color Scale")
                Toggle("", isOn: $colorScale).labelsHidden().scaleEffect(0.8)
                Text("scale colors").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Gradient")
                Toggle("", isOn: $gradientMode).labelsHidden().scaleEffect(0.8)
                Text("radial fill").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    var labelSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Show Labels")
                Toggle("", isOn: $showLabels).labelsHidden().scaleEffect(0.8)
                Text("circle labels").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if showLabels {
                HStack(spacing: 10) {
                    settingsLabel("Content")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(CPLabelContent.allCases, id: \.self) { mode in
                                pillButton(mode.rawValue, isSelected: labelContent == mode) { labelContent = mode }
                            }
                        }
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    settingsLabel("Position")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(CPLabelPos.allCases, id: \.self) { mode in
                                pillButton(mode.rawValue, isSelected: labelPos == mode) { labelPos = mode }
                            }
                        }
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    settingsLabel("Overflow")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(CPOverflow.allCases, id: \.self) { mode in
                                pillButton(mode.rawValue, isSelected: textOverflow == mode) { textOverflow = mode }
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    var interactionSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Highlight")
                Toggle("", isOn: $hoverHighlight).labelsHidden().scaleEffect(0.8)
                Text("hover highlight").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Tooltip")
                Toggle("", isOn: $hoverTooltip).labelsHidden().scaleEffect(0.8)
                Text("show tooltip").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Zoom & Pan")
                Toggle("", isOn: $zoomPanEnabled).labelsHidden().scaleEffect(0.8)
                Text("pinch/drag").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Animate")
                Toggle("", isOn: $animateOnLoad).labelsHidden().scaleEffect(0.8)
                Text("on load").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Duration")
                Slider(value: $animationDuration, in: 0.2...2.0)
                Text(String(format: "%.1fs", animationDuration)).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    var focusSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Focus Mode")
                Toggle("", isOn: $focusMode).labelsHidden().scaleEffect(0.8)
                Text("isolate circle").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Auto Center")
                Toggle("", isOn: $autoCenter).labelsHidden().scaleEffect(0.8)
                Text("center on select").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Zoom")
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        zoomScale = 1
                        panOffset = .zero
                    }
                } label: {
                    Text("Reset Zoom")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(Color.black.opacity(0.1), in: .capsule)
                }
                .foregroundStyle(.primary)
                Spacer()
            }
        }
    }

    var sortingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Sort")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(CPSort.allCases, id: \.self) { mode in
                            pillButton(mode.rawValue, isSelected: sortMode == mode) { sortMode = mode }
                        }
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Data List View

    var dataListView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Groups & Items")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    let idx = groups.count % CirclePackingCard.colorPalette.count
                    withAnimation(.spring(response: 0.4)) {
                        groups.append(CirclePackGroup(
                            name: "Group \(groups.count + 1)",
                            color: CirclePackingCard.colorPalette[idx],
                            items: [CirclePackItem(label: "Item 1", value: Double.random(in: 10...60), parentGroupID: nil, color: CirclePackingCard.colorPalette[idx])]
                        ))
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(CirclePackingCard.colorPalette[groups.count % CirclePackingCard.colorPalette.count])
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 10)

            ForEach(Array(groups.enumerated()), id: \.element.id) { gi, g in
                HStack(spacing: 10) {
                    Circle().fill(g.color).frame(width: 8, height: 8)
                    Text(g.name)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(g.items.count) items")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            let newItem = CirclePackItem(label: "Item \(g.items.count+1)", value: Double.random(in: 10...60), parentGroupID: g.id, color: g.color)
                            groups[gi].items.append(newItem)
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 15))
                            .foregroundStyle(g.color)
                    }
                    if groups.count > 1 {
                        Button {
                            withAnimation(.spring(response: 0.4)) { groups.removeSubrange(gi...gi) }
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 8)

                ForEach(Array(g.items.enumerated()), id: \.element.id) { ii, item in
                    HStack(spacing: 10) {
                        Color.clear.frame(width: 8)
                        Circle().fill(g.color.opacity(0.5)).frame(width: 6, height: 6)
                        Text(item.label)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer()
                        Slider(value: Binding(
                            get: { item.value },
                            set: { groups[gi].items[ii].value = $0 }
                        ), in: 1...200).frame(width: 80)
                        Text(String(format: "%.0f", item.value))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(g.color)
                            .frame(width: 28, alignment: .trailing)
                        if g.items.count > 1 {
                            Button {
                                withAnimation(.spring(response: 0.4)) { groups[gi].items.removeSubrange(ii...ii) }
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 6)
                    if ii < g.items.count - 1 {
                        Divider().padding(.leading, 48).padding(.trailing, 20)
                    }
                }

                if gi < groups.count - 1 {
                    Divider().padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            chartView
                .frame(height: 260)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            Divider().padding(.top, 16).padding(.horizontal, 12)
            VStack(spacing: 0) {
                Button { isExpanded.toggle() } label: {
                    ZStack {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                        HStack {
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .rotationEffect(.degrees(isExpanded ? 0 : -90))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 14)
                }
                VStack(spacing: 14) {
                    Divider().padding(.horizontal, 20)
                    layoutSettingsView
                    hierarchySettingsView
                    valueSizingSettingsView
                    circleStylingSettingsView
                    colorSettingsView
                    labelSettingsView
                    interactionSettingsView
                    focusSettingsView
                    sortingSettingsView
                    dataListView
                }
                .frame(maxHeight: isExpanded ? .infinity : 0)
                .clipped()
                .opacity(isExpanded ? 1 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isExpanded)
            }
            .padding(.bottom, 8)
        }
        .background(Color(uiColor: .systemGray6), in: .rect(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 12)
        .onAppear {
            if animateOnLoad {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: animationDuration)) { appeared = true }
                }
            } else {
                appeared = true
            }
        }
        .onChange(of: zoomPanEnabled) { _, enabled in
            if !enabled {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    zoomScale = 1
                    panOffset = .zero
                }
            }
        }
    }
}
