//
//  BubbleChartExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Bubble Data Point

struct BubbleDataPoint: Identifiable {
    let id = UUID()
    var label: String
    var x: Double
    var y: Double
    var size: Double
    var color: Color
}

// MARK: - Bubble Chart Card

struct BubbleChartCard: View {

    let title: String
    let categories: [String]
    @State private var points: [BubbleDataPoint]
    @State private var isExpanded = false
    @State private var editingID: UUID? = nil
    @State private var editingField: EditField = .y
    @State private var editingText = ""
    @State private var appeared = false
    @State private var highlightedID: UUID? = nil

    // Zoom & Pan
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragTranslation: CGSize = .zero

    // Chart Geometry
    @State private var minBubbleSize: Double = 8
    @State private var maxBubbleSize: Double = 44
    @State private var bubbleOpacity: Double = 0.82
    @State private var chartPadding: Double = 16

    // Axis Controls
    @State private var showXAxis: Bool = true
    @State private var showYAxis: Bool = true
    @State private var axisLabels: Bool = true
    @State private var axisGrid: Bool = true
    @State private var gridOpacity: Double = 0.18

    // Value Scaling
    @State private var autoScale: Bool = true
    @State private var xMin: Double = 0
    @State private var xMax: Double = 100
    @State private var yMin: Double = 0
    @State private var yMax: Double = 100
    @State private var xMinText = "0"
    @State private var xMaxText = "100"
    @State private var yMinText = "0"
    @State private var yMaxText = "100"

    // Axis Format
    @State private var valueFormat: BubbleFormat = .number
    @State private var axisScale: BubbleAxisScale = .linear

    // Bubble Styling
    @State private var bubbleShape: BubbleShapeType = .circle
    @State private var strokeEnabled: Bool = true
    @State private var fillEnabled: Bool = true
    @State private var gradientFill: Bool = true
    @State private var shadowEnabled: Bool = true

    // Color Controls
    @State private var colorMode: BubbleColorMode = .category
    @State private var primaryColor: Color = AnalyticsCard.colorPalette[0]
    @State private var colorScaleEnabled: Bool = false
    @State private var opacityGradient: Bool = false

    // Size Mapping
    @State private var sizeScale: BubbleSizeScale = .sqrtScale
    @State private var normalizeSizes: Bool = true

    // Labels
    @State private var showLabels: Bool = true
    @State private var labelContent: BubbleLabelContent = .label
    @State private var labelPos: BubbleLabelPos = .center

    // Interaction
    @State private var hoverHighlight: Bool = true
    @State private var hoverTooltip: Bool = true
    @State private var zoomPanEnabled: Bool = false
    @State private var animateOnLoad: Bool = true
    @State private var animationDuration: Double = 0.8

    // Clustering
    @State private var clusterMode: Bool = false
    @State private var clusterStrength: Double = 40

    // Rendering
    @State private var overlapMode: BubbleOverlapMode = .allow
    @State private var renderOrder: BubbleRenderOrder = .bySize

    #if os(iOS)
    @State private var pickerCoordinator: ColorPickerCoordinator? = nil
    #endif

    // MARK: - Enums

    enum EditField { case x, y, size, label }
    enum BubbleFormat: String, CaseIterable { case number = "Number", percent = "Percent", currency = "Currency", time = "Time" }
    enum BubbleAxisScale: String, CaseIterable { case linear = "Linear", log = "Log" }
    enum BubbleShapeType: String, CaseIterable { case circle = "Circle", soft = "Soft" }
    enum BubbleColorMode: String, CaseIterable { case single = "Single", category = "Category", value = "Value" }
    enum BubbleSizeScale: String, CaseIterable { case linear = "Linear", log = "Log", sqrtScale = "√Root" }
    enum BubbleLabelContent: String, CaseIterable { case label = "Label", value = "Value", both = "Both" }
    enum BubbleLabelPos: String, CaseIterable { case center = "Center", outside = "Outside", hidden = "Hidden" }
    enum BubbleOverlapMode: String, CaseIterable { case allow = "Allow", reduce = "Reduce", force = "Separate" }
    enum BubbleRenderOrder: String, CaseIterable { case `default` = "Default", bySize = "By Size", byValue = "By Value" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Init

    init(title: String, categories: [String], points: [BubbleDataPoint]) {
        self.title = title
        self.categories = categories
        self._points = State(initialValue: points)
    }

    // MARK: - Computed: Ordering

    var orderedPoints: [BubbleDataPoint] {
        switch renderOrder {
        case .default:  return points
        case .bySize:   return points.sorted { $0.size > $1.size }  // large first → small on top
        case .byValue:  return points.sorted { $0.y < $1.y }
        }
    }

    // MARK: - Axis Range

    var effectiveXMin: Double {
        guard autoScale else { return xMin }
        let xs = points.map { $0.x }
        let mn = xs.min() ?? 0; let mx = xs.max() ?? 100
        return mn - (mx - mn) * 0.15
    }
    var effectiveXMax: Double {
        guard autoScale else { return xMax }
        let xs = points.map { $0.x }
        let mn = xs.min() ?? 0; let mx = xs.max() ?? 100
        return mx + (mx - mn) * 0.15
    }
    var effectiveYMin: Double {
        guard autoScale else { return yMin }
        let ys = points.map { $0.y }
        let mn = ys.min() ?? 0; let mx = ys.max() ?? 100
        return mn - (mx - mn) * 0.15
    }
    var effectiveYMax: Double {
        guard autoScale else { return yMax }
        let ys = points.map { $0.y }
        let mn = ys.min() ?? 0; let mx = ys.max() ?? 100
        return mx + (mx - mn) * 0.15
    }

    func xRatio(for v: Double) -> CGFloat {
        let mn = effectiveXMin; let mx = effectiveXMax
        guard mx > mn else { return 0.5 }
        if axisScale == .log {
            let lMn = log10(max(mn, 1e-10)); let lMx = log10(max(mx, 1e-10))
            guard lMx > lMn else { return 0.5 }
            return CGFloat(max(0, min(1, (log10(max(v, 1e-10)) - lMn) / (lMx - lMn))))
        }
        return CGFloat(max(0, min(1, (v - mn) / (mx - mn))))
    }

    func yRatio(for v: Double) -> CGFloat {
        let mn = effectiveYMin; let mx = effectiveYMax
        guard mx > mn else { return 0.5 }
        if axisScale == .log {
            let lMn = log10(max(mn, 1e-10)); let lMx = log10(max(mx, 1e-10))
            guard lMx > lMn else { return 0.5 }
            return CGFloat(max(0, min(1, (log10(max(v, 1e-10)) - lMn) / (lMx - lMn))))
        }
        return CGFloat(max(0, min(1, (v - mn) / (mx - mn))))
    }

    func formattedValue(_ v: Double) -> String {
        switch valueFormat {
        case .number:   return v == Double(Int(v)) ? "\(Int(v))" : String(format: "%.1f", v)
        case .percent:  return "\(Int(v))%"
        case .currency: return "$\(Int(v))"
        case .time:
            let h = Int(v) / 60; let m = Int(v) % 60
            return h > 0 ? "\(h)h\(m)m" : "\(m)m"
        }
    }

    // MARK: - Size & Color

    func mappedRadius(for pt: BubbleDataPoint) -> CGFloat {
        let allSizes = points.map { $0.size }
        let maxS = allSizes.max() ?? 1
        let minS = allSizes.min() ?? 0
        var normalized: Double
        if normalizeSizes && maxS > minS {
            normalized = (pt.size - minS) / (maxS - minS)
        } else {
            normalized = maxS > 0 ? pt.size / maxS : 1.0
        }
        normalized = max(0, min(1, normalized))
        let scaled: Double
        switch sizeScale {
        case .linear:    scaled = normalized
        case .log:       scaled = normalized > 0 ? log10(1 + normalized * 9) : 0
        case .sqrtScale: scaled = sqrt(normalized)
        }
        return CGFloat(minBubbleSize + scaled * (maxBubbleSize - minBubbleSize))
    }

    func resolvedColor(for pt: BubbleDataPoint) -> Color {
        switch colorMode {
        case .single:   return primaryColor
        case .category: return pt.color
        case .value:
            let t = Double(yRatio(for: pt.y))
            return colorScaleEnabled
                ? Color(hue: 0.67 * (1.0 - t), saturation: 0.75, brightness: 0.88)
                : primaryColor
        }
    }

    func resolvedOpacity(for pt: BubbleDataPoint) -> Double {
        let t = Double(yRatio(for: pt.y))
        if opacityGradient { return bubbleOpacity * (0.4 + t * 0.6) }
        if colorMode == .value && !colorScaleEnabled { return bubbleOpacity * (0.3 + t * 0.7) }
        return bubbleOpacity
    }

    func bubbleAnyShape(r: CGFloat) -> AnyShape {
        switch bubbleShape {
        case .circle: return AnyShape(Circle())
        case .soft:   return AnyShape(RoundedRectangle(cornerRadius: r * 0.28, style: .continuous))
        }
    }

    // MARK: - Overlap Resolution

    struct BubblePos { var x: CGFloat; var y: CGFloat; var r: CGFloat }

    func resolveOverlaps(positions: [BubblePos]) -> [CGPoint] {
        let iterations = overlapMode == .force ? 14 : 6
        let strength: CGFloat = overlapMode == .force ? 0.9 : 0.45
        var pos = positions.map { CGPoint(x: $0.x, y: $0.y) }
        for _ in 0..<iterations {
            for i in 0..<pos.count {
                for j in (i + 1)..<pos.count {
                    let ri = positions[i].r, rj = positions[j].r
                    let minDist = ri + rj + 2
                    let dx = pos[j].x - pos[i].x
                    let dy = pos[j].y - pos[i].y
                    let dist = sqrt(dx * dx + dy * dy)
                    guard dist < minDist, dist > 0.01 else { continue }
                    let push = (minDist - dist) * 0.5 * strength
                    let nx = dx / dist, ny = dy / dist
                    pos[i].x -= nx * push
                    pos[i].y -= ny * push
                    pos[j].x += nx * push
                    pos[j].y += ny * push
                }
            }
        }
        return pos
    }

    // MARK: - Cluster Groups

    func clusterGroups(ptsR: [(CGPoint, CGFloat)], threshold: CGFloat) -> [[Int]] {
        var groups: [[Int]] = []
        var assigned = [Bool](repeating: false, count: ptsR.count)
        for i in 0..<ptsR.count {
            guard !assigned[i] else { continue }
            var group = [i]; assigned[i] = true
            for j in (i + 1)..<ptsR.count {
                guard !assigned[j] else { continue }
                let dx = ptsR[i].0.x - ptsR[j].0.x
                let dy = ptsR[i].0.y - ptsR[j].0.y
                let edge = sqrt(dx * dx + dy * dy) - ptsR[i].1 - ptsR[j].1
                if edge < threshold { group.append(j); assigned[j] = true }
            }
            if group.count > 1 { groups.append(group) }
        }
        return groups
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            chartView
                .frame(height: 300)
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
                    geometrySettingsView
                    axisSettingsView
                    scalingSettingsView
                    axisFormatSettingsView
                    bubbleStyleSettingsView
                    colorSettingsView
                    sizeMappingSettingsView
                    labelSettingsView
                    interactionSettingsView
                    clusteringSettingsView
                    renderingSettingsView
                    itemListView
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
                    zoomScale = 1.0; panOffset = .zero
                }
            }
        }
        .onTapGesture { editingID = nil; highlightedID = nil }
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            let leftM:  CGFloat = (showYAxis && axisLabels) ? 44 : 8
            let rightM: CGFloat = CGFloat(chartPadding)
            let topM:   CGFloat = 10
            let botM:   CGFloat = (showXAxis && axisLabels) ? 26 : (showXAxis ? 12 : 8)
            let chartW = geo.size.width  - leftM - rightM
            let chartH = geo.size.height - topM  - botM

            let ordPts = orderedPoints
            let basePosArr: [BubblePos] = ordPts.map { pt in
                BubblePos(
                    x: leftM + xRatio(for: pt.x) * chartW,
                    y: topM + chartH * (1 - yRatio(for: pt.y)),
                    r: mappedRadius(for: pt)
                )
            }
            let finalPos: [CGPoint] = overlapMode == .allow
                ? basePosArr.map { CGPoint(x: $0.x, y: $0.y) }
                : resolveOverlaps(positions: basePosArr)

            ZStack(alignment: .topLeading) {

                // Vertical grid
                if axisGrid {
                    ForEach(0...4, id: \.self) { i in
                        let xPos = leftM + chartW * CGFloat(i) / 4
                        Path { p in
                            p.move(to: CGPoint(x: xPos, y: topM))
                            p.addLine(to: CGPoint(x: xPos, y: topM + chartH))
                        }
                        .stroke(Color.primary.opacity(gridOpacity), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    }
                }

                // Horizontal grid
                if axisGrid {
                    ForEach(0...4, id: \.self) { i in
                        let yPos = topM + chartH * CGFloat(i) / 4
                        Path { p in
                            p.move(to: CGPoint(x: leftM, y: yPos))
                            p.addLine(to: CGPoint(x: leftM + chartW, y: yPos))
                        }
                        .stroke(Color.primary.opacity(gridOpacity), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    }
                }

                // Y axis labels
                if showYAxis && axisLabels {
                    ForEach(0...4, id: \.self) { i in
                        let frac = CGFloat(i) / 4
                        let val = effectiveYMin + (effectiveYMax - effectiveYMin) * Double(1 - frac)
                        Text(formattedValue(val))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 38, alignment: .trailing)
                            .position(x: leftM - 6, y: topM + chartH * frac)
                    }
                }

                // X axis labels
                if showXAxis && axisLabels {
                    ForEach(0...4, id: \.self) { i in
                        let frac = CGFloat(i) / 4
                        let val = effectiveXMin + (effectiveXMax - effectiveXMin) * Double(frac)
                        Text(formattedValue(val))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 44, alignment: .center)
                            .position(x: leftM + chartW * frac, y: topM + chartH + botM / 2)
                    }
                }

                // Y axis line
                if showYAxis {
                    Path { p in
                        p.move(to: CGPoint(x: leftM, y: topM))
                        p.addLine(to: CGPoint(x: leftM, y: topM + chartH))
                    }
                    .stroke(Color.primary.opacity(0.25), lineWidth: 0.75)
                }

                // X axis line
                if showXAxis {
                    Path { p in
                        p.move(to: CGPoint(x: leftM, y: topM + chartH))
                        p.addLine(to: CGPoint(x: leftM + chartW, y: topM + chartH))
                    }
                    .stroke(Color.primary.opacity(0.25), lineWidth: 0.75)
                }

                // Cluster halos
                if clusterMode {
                    let threshold = CGFloat(clusterStrength / 100.0) * min(chartW, chartH) * 0.22
                    let ptsR: [(CGPoint, CGFloat)] = finalPos.indices.map { (finalPos[$0], basePosArr[$0].r) }
                    let groups = clusterGroups(ptsR: ptsR, threshold: threshold)
                    ForEach(groups.indices, id: \.self) { gi in
                        let gPts = groups[gi]
                        let cx = gPts.map { finalPos[$0].x }.reduce(0, +) / CGFloat(gPts.count)
                        let cy = gPts.map { finalPos[$0].y }.reduce(0, +) / CGFloat(gPts.count)
                        let maxR = gPts.map { idx -> CGFloat in
                            let dx = finalPos[idx].x - cx
                            let dy = finalPos[idx].y - cy
                            return sqrt(dx * dx + dy * dy) + basePosArr[idx].r
                        }.max() ?? 20
                        let r = maxR + 16
                        Ellipse()
                            .fill(primaryColor.opacity(0.055))
                            .overlay(Ellipse().stroke(primaryColor.opacity(0.12), lineWidth: 1))
                            .frame(width: r * 2, height: r * 2)
                            .position(x: cx, y: cy)
                            .blur(radius: 6)
                    }
                }

                // Bubbles
                ForEach(Array(ordPts.enumerated()), id: \.element.id) { i, pt in
                    let spt = finalPos[i]
                    let pR = basePosArr[i].r
                    let col = resolvedColor(for: pt)
                    let opc = resolvedOpacity(for: pt)
                    let isHL = highlightedID == pt.id
                    let displayR = pR * (isHL ? 1.12 : 1.0)
                    let shapeAny = bubbleAnyShape(r: displayR)

                    ZStack {
                        if fillEnabled {
                            shapeAny
                                .fill(col.opacity(opc))
                                .glassEffect(.clear, in: shapeAny)
                        }
                        if gradientFill {
                            shapeAny.fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.42),
                                        Color.white.opacity(0)
                                    ]),
                                    center: UnitPoint(x: 0.32, y: 0.26),
                                    startRadius: 0,
                                    endRadius: displayR
                                )
                            )
                        }
                        if strokeEnabled {
                            shapeAny.stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                            shapeAny.stroke(Color.white, lineWidth: 5)
                                .blur(radius: 3).opacity(0.28).clipShape(shapeAny)
                        }
                    }
                    .frame(width: displayR * 2, height: displayR * 2)
                    .shadow(
                        color: .black.opacity(shadowEnabled ? 0.18 : 0),
                        radius: shadowEnabled ? displayR * 0.32 : 0,
                        x: 0,
                        y: shadowEnabled ? displayR * 0.14 : 0
                    )
                    .position(x: spt.x, y: spt.y)
                    .scaleEffect(appeared ? 1.0 : 0.01)
                    .opacity(appeared ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.65)
                            .delay(animateOnLoad ? Double(i) * 0.05 : 0),
                        value: appeared
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHL)
                    .onTapGesture {
                        guard hoverHighlight else { return }
                        withAnimation(.spring(response: 0.3)) {
                            highlightedID = (highlightedID == pt.id) ? nil : pt.id
                        }
                    }

                    // Bubble label
                    if showLabels && labelPos != .hidden && pR > 9 {
                        let labelText: String = {
                            switch labelContent {
                            case .label: return pt.label
                            case .value: return String(format: "%.0f", pt.size)
                            case .both:  return pt.label.isEmpty
                                ? String(format: "%.0f", pt.size)
                                : "\(pt.label) · \(Int(pt.size))"
                            }
                        }()
                        let lY: CGFloat = labelPos == .outside
                            ? spt.y - displayR - 9
                            : spt.y
                        let fontSize: CGFloat = max(7, min(11, displayR * 0.42))
                        Text(labelText)
                            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                            .foregroundStyle(
                                labelPos == .center
                                    ? Color.white.opacity(0.9)
                                    : Color.primary.opacity(0.7)
                            )
                            .shadow(color: .black.opacity(labelPos == .center ? 0.3 : 0), radius: 1)
                            .multilineTextAlignment(.center)
                            .frame(width: displayR * 2 - 4)
                            .position(x: spt.x, y: lY)
                    }

                    // Highlight ring
                    if isHL {
                        shapeAny
                            .stroke(col.opacity(0.5), lineWidth: 2)
                            .frame(width: displayR * 2 + 8, height: displayR * 2 + 8)
                            .position(x: spt.x, y: spt.y)
                    }
                }

                // Tooltip
                if hoverTooltip, let hlID = highlightedID,
                   let hlPt = points.first(where: { $0.id == hlID }),
                   let hlIdx = ordPts.firstIndex(where: { $0.id == hlID }) {
                    bubbleTooltip(
                        point: hlPt,
                        at: finalPos[hlIdx],
                        radius: basePosArr[hlIdx].r,
                        chartW: chartW,
                        leftM: leftM
                    )
                }
            }
            .scaleEffect(zoomPanEnabled ? zoomScale * magnifyBy : 1.0, anchor: .center)
            .offset(
                x: zoomPanEnabled ? panOffset.width  + dragTranslation.width  : 0,
                y: zoomPanEnabled ? panOffset.height + dragTranslation.height : 0
            )
            .gesture(
                MagnificationGesture()
                    .updating($magnifyBy) { v, s, _ in s = zoomPanEnabled ? v : 1.0 }
                    .onEnded { v in if zoomPanEnabled { zoomScale = min(5, max(0.5, zoomScale * v)) } }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 14)
                    .updating($dragTranslation) { v, s, _ in s = zoomPanEnabled ? v.translation : .zero }
                    .onEnded { v in
                        if zoomPanEnabled {
                            panOffset.width  += v.translation.width
                            panOffset.height += v.translation.height
                        }
                    }
            )
        }
    }

    // MARK: - Tooltip

    @ViewBuilder
    func bubbleTooltip(point: BubbleDataPoint, at pt: CGPoint, radius: CGFloat, chartW: CGFloat, leftM: CGFloat) -> some View {
        let w: CGFloat = 98
        let clampedX = max(leftM + w / 2, min(pt.x, leftM + chartW - w / 2))
        VStack(alignment: .leading, spacing: 3) {
            if !point.label.isEmpty {
                Text(point.label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            HStack(spacing: 4) {
                Text("X:")
                    .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Text(formattedValue(point.x))
                    .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            }
            HStack(spacing: 4) {
                Text("Y:")
                    .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Text(formattedValue(point.y))
                    .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            }
            HStack(spacing: 4) {
                Text("Size:")
                    .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Text(String(format: "%.0f", point.size))
                    .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(Color(uiColor: .systemBackground).opacity(0.92), in: .rect(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        .position(x: clampedX, y: max(36, pt.y - radius - 44))
    }

    // MARK: - Settings: Geometry

    var geometrySettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Min Size")
                Slider(value: $minBubbleSize, in: 2...20, step: 1)
                Text("\(Int(minBubbleSize))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Max Size")
                Slider(value: $maxBubbleSize, in: 10...70, step: 2)
                Text("\(Int(maxBubbleSize))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Opacity")
                Slider(value: $bubbleOpacity, in: 0...1, step: 0.05)
                Text("\(Int(bubbleOpacity * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Padding")
                Slider(value: $chartPadding, in: 0...60, step: 2)
                Text("\(Int(chartPadding))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Axis

    var axisSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("X Axis")
                Toggle("", isOn: $showXAxis).labelsHidden().scaleEffect(0.8)
                Text("Show X axis").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Y Axis")
                Toggle("", isOn: $showYAxis).labelsHidden().scaleEffect(0.8)
                Text("Show Y axis").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Labels")
                Toggle("", isOn: $axisLabels).labelsHidden().scaleEffect(0.8)
                Text("Axis tick labels").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Grid")
                Toggle("", isOn: $axisGrid).labelsHidden().scaleEffect(0.8)
                Text("Show grid lines").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if axisGrid {
                HStack(spacing: 10) {
                    settingsLabel("Grid Opc")
                    Slider(value: $gridOpacity, in: 0...1, step: 0.05)
                    Text("\(Int(gridOpacity * 100))%")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Settings: Scaling

    var scalingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Auto")
                Toggle("", isOn: $autoScale).labelsHidden().scaleEffect(0.8)
                Text("Auto scale to data").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if !autoScale {
                HStack(spacing: 10) {
                    settingsLabel("X Min")
                    TextField("0", text: $xMinText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing).frame(maxWidth: .infinity)
                        .onChange(of: xMinText) { _, v in if let d = Double(v) { xMin = d } }
                }
                HStack(spacing: 10) {
                    settingsLabel("X Max")
                    TextField("100", text: $xMaxText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing).frame(maxWidth: .infinity)
                        .onChange(of: xMaxText) { _, v in if let d = Double(v) { xMax = d } }
                }
                HStack(spacing: 10) {
                    settingsLabel("Y Min")
                    TextField("0", text: $yMinText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing).frame(maxWidth: .infinity)
                        .onChange(of: yMinText) { _, v in if let d = Double(v) { yMin = d } }
                }
                HStack(spacing: 10) {
                    settingsLabel("Y Max")
                    TextField("100", text: $yMaxText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing).frame(maxWidth: .infinity)
                        .onChange(of: yMaxText) { _, v in if let d = Double(v) { yMax = d } }
                }
            }
        }
    }

    // MARK: - Settings: Axis Format

    var axisFormatSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Format")
                HStack(spacing: 4) {
                    ForEach(BubbleFormat.allCases, id: \.self) { f in
                        pillButton(f.rawValue, isSelected: valueFormat == f) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { valueFormat = f }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Scale")
                HStack(spacing: 4) {
                    ForEach(BubbleAxisScale.allCases, id: \.self) { s in
                        pillButton(s.rawValue, isSelected: axisScale == s) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { axisScale = s }
                        }
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Settings: Bubble Styling

    var bubbleStyleSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Shape")
                HStack(spacing: 4) {
                    ForEach(BubbleShapeType.allCases, id: \.self) { s in
                        pillButton(s.rawValue, isSelected: bubbleShape == s) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { bubbleShape = s }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Stroke")
                Toggle("", isOn: $strokeEnabled).labelsHidden().scaleEffect(0.8)
                Text("Glass stroke ring").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Fill")
                Toggle("", isOn: $fillEnabled).labelsHidden().scaleEffect(0.8)
                Text("Fill bubbles").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Gradient")
                Toggle("", isOn: $gradientFill).labelsHidden().scaleEffect(0.8)
                Text("3D highlight overlay").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Shadow")
                Toggle("", isOn: $shadowEnabled).labelsHidden().scaleEffect(0.8)
                Text("Soft drop shadow").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Color

    var colorSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Color By")
                HStack(spacing: 4) {
                    ForEach(BubbleColorMode.allCases, id: \.self) { m in
                        pillButton(m.rawValue, isSelected: colorMode == m) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { colorMode = m }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Color")
                Button {
                    #if os(iOS)
                    let coord = ColorPickerCoordinator { color in primaryColor = color }
                    pickerCoordinator = coord
                    let vc = UIColorPickerViewController()
                    vc.selectedColor = UIColor(primaryColor)
                    vc.supportsAlpha = false
                    vc.delegate = coord
                    topViewController()?.present(vc, animated: true)
                    #endif
                } label: {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(primaryColor)
                        .frame(width: 28, height: 28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                }
                Text("Primary color").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Color Sc")
                Toggle("", isOn: $colorScaleEnabled).labelsHidden().scaleEffect(0.8)
                Text("Heatmap color scale").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Opc Grad")
                Toggle("", isOn: $opacityGradient).labelsHidden().scaleEffect(0.8)
                Text("Opacity by Y value").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Size Mapping

    var sizeMappingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Scale")
                HStack(spacing: 4) {
                    ForEach(BubbleSizeScale.allCases, id: \.self) { s in
                        pillButton(s.rawValue, isSelected: sizeScale == s) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { sizeScale = s }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Normalize")
                Toggle("", isOn: $normalizeSizes).labelsHidden().scaleEffect(0.8)
                Text("Normalize to data range").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Labels

    var labelSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Labels")
                Toggle("", isOn: $showLabels).labelsHidden().scaleEffect(0.8)
                Text("Show bubble labels").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if showLabels {
                HStack(spacing: 10) {
                    settingsLabel("Content")
                    HStack(spacing: 4) {
                        ForEach(BubbleLabelContent.allCases, id: \.self) { c in
                            pillButton(c.rawValue, isSelected: labelContent == c) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { labelContent = c }
                            }
                        }
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    settingsLabel("Position")
                    HStack(spacing: 4) {
                        ForEach(BubbleLabelPos.allCases, id: \.self) { p in
                            pillButton(p.rawValue, isSelected: labelPos == p) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { labelPos = p }
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Settings: Interaction

    var interactionSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Highlight")
                Toggle("", isOn: $hoverHighlight).labelsHidden().scaleEffect(0.8)
                Text("Tap to highlight").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Tooltip")
                Toggle("", isOn: $hoverTooltip).labelsHidden().scaleEffect(0.8)
                Text("Show X / Y / Size").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Zoom/Pan")
                Toggle("", isOn: $zoomPanEnabled).labelsHidden().scaleEffect(0.8)
                Text("Pinch zoom & drag pan").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Animate")
                Toggle("", isOn: $animateOnLoad).labelsHidden().scaleEffect(0.8)
                Text("Animate on load").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if animateOnLoad {
                HStack(spacing: 10) {
                    settingsLabel("Duration")
                    Slider(value: $animationDuration, in: 0.2...2.0, step: 0.1)
                    Text(String(format: "%.1fs", animationDuration))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Settings: Clustering

    var clusteringSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Cluster")
                Toggle("", isOn: $clusterMode).labelsHidden().scaleEffect(0.8)
                Text("Show cluster groups").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if clusterMode {
                HStack(spacing: 10) {
                    settingsLabel("Strength")
                    Slider(value: $clusterStrength, in: 0...100, step: 5)
                    Text("\(Int(clusterStrength))%")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Settings: Rendering

    var renderingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Overlap")
                HStack(spacing: 4) {
                    ForEach(BubbleOverlapMode.allCases, id: \.self) { o in
                        pillButton(o.rawValue, isSelected: overlapMode == o) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { overlapMode = o }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Render")
                HStack(spacing: 4) {
                    ForEach(BubbleRenderOrder.allCases, id: \.self) { o in
                        pillButton(o.rawValue, isSelected: renderOrder == o) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { renderOrder = o }
                        }
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Item List

    var itemListView: some View {
        VStack(spacing: 0) {
            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                itemRow(index: index, point: point)
            }
            Divider().padding(.horizontal, 20)
            Button { addItem() } label: {
                Text("+ Add New Item")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
    }

    @ViewBuilder
    func itemRow(index: Int, point: BubbleDataPoint) -> some View {
        HStack(spacing: 8) {

            // Color swatch
            Button {
                #if os(iOS)
                let coord = ColorPickerCoordinator { color in points[index].color = color }
                pickerCoordinator = coord
                let vc = UIColorPickerViewController()
                vc.selectedColor = UIColor(points[index].color)
                vc.supportsAlpha = false
                vc.delegate = coord
                topViewController()?.present(vc, animated: true)
                #endif
            } label: {
                Circle()
                    .fill(points[index].color)
                    .frame(width: 26, height: 26)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                    .opacity(colorMode == .category ? 1.0 : 0.3)
            }

            // Label
            if editingID == point.id && editingField == .label {
                TextField("Label", text: $editingText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .onChange(of: editingText) { _, val in points[index].label = val }
            } else {
                Button {
                    editingID = point.id; editingField = .label; editingText = point.label
                } label: {
                    Text(point.label.isEmpty ? "Point \(index + 1)" : point.label)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(point.label.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .underline(color: .primary.opacity(point.label.isEmpty ? 0 : 0.2))
                }
                .foregroundStyle(.primary)
            }

            // X value
            valuePill(label: "X", value: String(format: "%.0f", point.x),
                      isEditing: editingID == point.id && editingField == .x,
                      onTap: { editingID = point.id; editingField = .x; editingText = String(format: "%.0f", point.x) },
                      onChange: { if let v = Double($0) { points[index].x = v } })

            // Y value
            valuePill(label: "Y", value: String(format: "%.0f", point.y),
                      isEditing: editingID == point.id && editingField == .y,
                      onTap: { editingID = point.id; editingField = .y; editingText = String(format: "%.0f", point.y) },
                      onChange: { if let v = Double($0) { points[index].y = v } })

            // Size value
            valuePill(label: "Sz", value: String(format: "%.0f", point.size),
                      isEditing: editingID == point.id && editingField == .size,
                      onTap: { editingID = point.id; editingField = .size; editingText = String(format: "%.0f", point.size) },
                      onChange: { if let v = Double($0) { points[index].size = max(1, v) } })
        }
        .padding(.horizontal, 20).padding(.vertical, 11)
        if index < points.count - 1 { Divider().padding(.horizontal, 20) }
    }

    @ViewBuilder
    func valuePill(label: String, value: String, isEditing: Bool, onTap: @escaping () -> Void, onChange: @escaping (String) -> Void) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            if isEditing {
                TextField("0", text: $editingText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    #if os(iOS)
                    .keyboardType(.numbersAndPunctuation)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .frame(width: 38)
                    .onChange(of: editingText) { _, val in onChange(val) }
            } else {
                Button(action: onTap) {
                    Text(value)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .underline(color: .primary.opacity(0.25))
                }
                .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - UI Helpers

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

    // MARK: - Logic

    func addItem() {
        let colIdx = points.count % Self.colorPalette.count
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            points.append(BubbleDataPoint(
                label: "B\(points.count + 1)",
                x: Double.random(in: 10...90),
                y: Double.random(in: 10...90),
                size: Double.random(in: 15...80),
                color: Self.colorPalette[colIdx]
            ))
        }
    }
}

#Preview {
    ScrollView {
        BubbleChartCard(
            title: "Bubble Chart",
            categories: ["Bubble", "Plot"],
            points: [
                BubbleDataPoint(label: "A", x: 20, y: 30, size: 25, color: AnalyticsCard.colorPalette[0]),
                BubbleDataPoint(label: "B", x: 40, y: 55, size: 65, color: AnalyticsCard.colorPalette[1]),
                BubbleDataPoint(label: "C", x: 60, y: 25, size: 40, color: AnalyticsCard.colorPalette[2]),
                BubbleDataPoint(label: "D", x: 30, y: 70, size: 80, color: AnalyticsCard.colorPalette[3]),
                BubbleDataPoint(label: "E", x: 75, y: 60, size: 30, color: AnalyticsCard.colorPalette[4]),
                BubbleDataPoint(label: "F", x: 55, y: 80, size: 55, color: AnalyticsCard.colorPalette[5]),
                BubbleDataPoint(label: "G", x: 85, y: 40, size: 20, color: AnalyticsCard.colorPalette[0]),
            ]
        )
        .padding(.top, 20)
    }
}
