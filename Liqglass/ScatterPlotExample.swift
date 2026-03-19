//
//  ScatterPlotExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Scatter Data Point

struct ScatterDataPoint: Identifiable {
    let id = UUID()
    var label: String
    var x: Double
    var y: Double
    var color: Color
}

// MARK: - Scatter Plot Card

struct ScatterPlotCard: View {

    let title: String
    let categories: [String]
    @State private var points: [ScatterDataPoint]
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
    @State private var pointSize: Double = 11
    @State private var pointOpacity: Double = 0.85
    @State private var chartPadding: Double = 16

    // Axis Controls
    @State private var showXAxis: Bool = true
    @State private var showYAxis: Bool = true
    @State private var axisLabels: Bool = true
    @State private var axisGrid: Bool = true
    @State private var gridOpacity: Double = 0.20

    // Value Scaling
    @State private var autoScale: Bool = true
    @State private var xMin: Double = 0
    @State private var xMax: Double = 100
    @State private var yMin: Double = 0
    @State private var yMax: Double = 100
    @State private var xMinText: String = "0"
    @State private var xMaxText: String = "100"
    @State private var yMinText: String = "0"
    @State private var yMaxText: String = "100"

    // Axis Format
    @State private var valueFormat: ScatterFormat = .number
    @State private var axisScale: ScatterAxisScale = .linear

    // Point Styling
    @State private var pointShape: ScatterShape = .circle
    @State private var pointStroke: Bool = true
    @State private var pointFill: Bool = true
    @State private var colorMode: ScatterColorMode = .category

    // Color Controls
    @State private var primaryColor: Color = AnalyticsCard.colorPalette[0]
    @State private var colorScaleEnabled: Bool = false
    @State private var opacityGradient: Bool = false

    // Trend & Analysis
    @State private var showTrendLine: Bool = false
    @State private var trendDashed: Bool = false
    @State private var regressionType: RegressionKind = .linear
    @State private var showConfidenceBand: Bool = false

    // Clustering
    @State private var clusterMode: Bool = false
    @State private var clusterStrength: Double = 40

    // Labels
    @State private var showPointLabels: Bool = true
    @State private var labelPos: ScatterLabelPos = .top

    // Interaction
    @State private var hoverHighlight: Bool = true
    @State private var hoverTooltip: Bool = true
    @State private var zoomPanEnabled: Bool = false
    @State private var animateOnLoad: Bool = true
    @State private var animationDuration: Double = 0.8

    // Render Order
    @State private var renderOrder: ScatterRenderOrder = .default

    #if os(iOS)
    @State private var pickerCoordinator: ColorPickerCoordinator? = nil
    #endif

    // MARK: - Enums

    enum EditField { case x, y, label }
    enum ScatterFormat: String, CaseIterable { case number = "Number", percent = "Percent", currency = "Currency", time = "Time" }
    enum ScatterAxisScale: String, CaseIterable { case linear = "Linear", log = "Log" }
    enum ScatterShape: String, CaseIterable { case circle = "Circle", square = "Square" }
    enum ScatterColorMode: String, CaseIterable { case single = "Single", category = "Category", value = "Value" }
    enum RegressionKind: String, CaseIterable { case linear = "Linear", polynomial = "Poly" }
    enum ScatterRenderOrder: String, CaseIterable { case `default` = "Default", byValue = "Value", bySize = "Size" }
    enum ScatterLabelPos: String, CaseIterable { case top = "Top", right = "Right", hidden = "Hidden" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Init

    init(title: String, categories: [String], points: [ScatterDataPoint]) {
        self.title = title
        self.categories = categories
        self._points = State(initialValue: points)
    }

    // MARK: - Computed

    var orderedPoints: [ScatterDataPoint] {
        switch renderOrder {
        case .default: return points
        case .byValue:  return points.sorted { $0.y < $1.y }
        case .bySize:   return points.sorted { $0.y > $1.y }
        }
    }

    var effectiveXMin: Double {
        guard autoScale else { return xMin }
        let xs = points.map { $0.x }
        let mn = xs.min() ?? 0; let mx = xs.max() ?? 100
        return mn - (mx - mn) * 0.12
    }
    var effectiveXMax: Double {
        guard autoScale else { return xMax }
        let xs = points.map { $0.x }
        let mn = xs.min() ?? 0; let mx = xs.max() ?? 100
        return mx + (mx - mn) * 0.12
    }
    var effectiveYMin: Double {
        guard autoScale else { return yMin }
        let ys = points.map { $0.y }
        let mn = ys.min() ?? 0; let mx = ys.max() ?? 100
        return mn - (mx - mn) * 0.12
    }
    var effectiveYMax: Double {
        guard autoScale else { return yMax }
        let ys = points.map { $0.y }
        let mn = ys.min() ?? 0; let mx = ys.max() ?? 100
        return mx + (mx - mn) * 0.12
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

    func screenPoint(for pt: ScatterDataPoint, chartW: CGFloat, chartH: CGFloat, leftM: CGFloat, topM: CGFloat) -> CGPoint {
        CGPoint(x: leftM + xRatio(for: pt.x) * chartW, y: topM + chartH * (1 - yRatio(for: pt.y)))
    }

    func resolvedColor(for pt: ScatterDataPoint) -> Color {
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

    func resolvedOpacity(for pt: ScatterDataPoint) -> Double {
        let t = Double(yRatio(for: pt.y))
        if opacityGradient { return pointOpacity * (0.35 + t * 0.65) }
        if colorMode == .value && !colorScaleEnabled { return pointOpacity * (0.25 + t * 0.75) }
        return pointOpacity
    }

    // MARK: - Linear Regression

    struct LinFit { var slope: Double; var intercept: Double; var se: Double }

    func linearFit() -> LinFit? {
        let n = Double(points.count)
        guard n >= 2 else { return nil }
        let xs = points.map { $0.x }, ys = points.map { $0.y }
        let xMean = xs.reduce(0, +) / n, yMean = ys.reduce(0, +) / n
        let num = zip(xs, ys).reduce(0.0) { $0 + ($1.0 - xMean) * ($1.1 - yMean) }
        let den = xs.reduce(0.0) { $0 + ($1 - xMean) * ($1 - xMean) }
        guard den > 0 else { return nil }
        let slope = num / den
        let intercept = yMean - slope * xMean
        let sse = zip(xs, ys).reduce(0.0) { let r = $1.1 - (slope * $1.0 + intercept); return $0 + r * r }
        let se = n > 2 ? sqrt(sse / (n - 2)) : 0
        return LinFit(slope: slope, intercept: intercept, se: se)
    }

    func polynomialFit() -> ((Double) -> Double)? {
        let n = points.count
        guard n >= 3 else { return linearFit().map { f in { x in f.slope * x + f.intercept } } }
        let xs = points.map { $0.x }, ys = points.map { $0.y }
        let s0 = Double(n)
        let s1 = xs.reduce(0, +)
        let s2 = xs.reduce(0.0) { $0 + $1 * $1 }
        let s3 = xs.reduce(0.0) { $0 + $1 * $1 * $1 }
        let s4 = xs.reduce(0.0) { $0 + $1 * $1 * $1 * $1 }
        let t0 = ys.reduce(0.0, +)
        let t1 = zip(xs, ys).reduce(0.0) { $0 + $1.0 * $1.1 }
        let t2 = zip(xs, ys).reduce(0.0) { $0 + $1.0 * $1.0 * $1.1 }
        var m: [[Double]] = [[s4, s3, s2, t2], [s3, s2, s1, t1], [s2, s1, s0, t0]]
        for col in 0..<3 {
            guard let pivot = (col..<3).max(by: { abs(m[$0][col]) < abs(m[$1][col]) }) else { continue }
            m.swapAt(col, pivot)
            guard abs(m[col][col]) > 1e-12 else { continue }
            for row in (col + 1)..<3 {
                let f = m[row][col] / m[col][col]
                for c in col...3 { m[row][c] -= f * m[col][c] }
            }
        }
        var abc = [Double](repeating: 0, count: 3)
        for i in stride(from: 2, through: 0, by: -1) {
            var sum = m[i][3]
            for j in (i + 1)..<3 { sum -= m[i][j] * abc[j] }
            abc[i] = abs(m[i][i]) > 1e-12 ? sum / m[i][i] : 0
        }
        let a = abc[0], b = abc[1], c = abc[2]
        return { x in a * x * x + b * x + c }
    }

    func polyPath(fn: (Double) -> Double, chartW: CGFloat, chartH: CGFloat, leftM: CGFloat, topM: CGFloat) -> Path {
        var path = Path()
        let steps = 80
        let xRange = effectiveXMax - effectiveXMin
        let first = CGPoint(
            x: leftM + xRatio(for: effectiveXMin) * chartW,
            y: topM + chartH * (1 - yRatio(for: fn(effectiveXMin)))
        )
        path.move(to: first)
        for i in 1...steps {
            let xV = effectiveXMin + xRange * Double(i) / Double(steps)
            path.addLine(to: CGPoint(
                x: leftM + xRatio(for: xV) * chartW,
                y: topM + chartH * (1 - yRatio(for: fn(xV)))
            ))
        }
        return path
    }

    // MARK: - Cluster Groups

    func clusterGroups(screenPts: [CGPoint], threshold: CGFloat) -> [[Int]] {
        var groups: [[Int]] = []
        var assigned = [Bool](repeating: false, count: screenPts.count)
        for i in 0..<screenPts.count {
            guard !assigned[i] else { continue }
            var group = [i]; assigned[i] = true
            for j in (i + 1)..<screenPts.count {
                guard !assigned[j] else { continue }
                let dx = screenPts[i].x - screenPts[j].x, dy = screenPts[i].y - screenPts[j].y
                if sqrt(dx * dx + dy * dy) < threshold { group.append(j); assigned[j] = true }
            }
            if group.count > 1 { groups.append(group) }
        }
        return groups
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            chartView
                .frame(height: 280)
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
                    pointStyleSettingsView
                    colorSettingsView
                    trendSettingsView
                    clusteringSettingsView
                    labelSettingsView
                    interactionSettingsView
                    renderOrderSettingsView
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

            let allScreenPts: [CGPoint] = points.indices.map {
                screenPoint(for: points[$0], chartW: chartW, chartH: chartH, leftM: leftM, topM: topM)
            }

            ZStack(alignment: .topLeading) {

                // Vertical grid lines
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

                // Horizontal grid lines
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

                // Y axis tick labels
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

                // X axis tick labels
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
                    let threshold = CGFloat(clusterStrength / 100.0) * min(chartW, chartH) * 0.28
                    let groups = clusterGroups(screenPts: allScreenPts, threshold: threshold)
                    ForEach(groups.indices, id: \.self) { gi in
                        let gPts = groups[gi].map { allScreenPts[$0] }
                        let cx = gPts.map { $0.x }.reduce(0, +) / CGFloat(gPts.count)
                        let cy = gPts.map { $0.y }.reduce(0, +) / CGFloat(gPts.count)
                        let maxR = gPts.map { pt in
                            sqrt(pow(pt.x - cx, 2) + pow(pt.y - cy, 2))
                        }.max() ?? 20
                        let r = maxR + CGFloat(pointSize) + 14
                        Ellipse()
                            .fill(primaryColor.opacity(0.055))
                            .overlay(Ellipse().stroke(primaryColor.opacity(0.13), lineWidth: 1))
                            .frame(width: r * 2, height: r * 2)
                            .position(x: cx, y: cy)
                            .blur(radius: 5)
                    }
                }

                // Confidence band
                if showConfidenceBand, let fit = linearFit() {
                    let yRange = max(effectiveYMax - effectiveYMin, 1)
                    let seH = chartH * CGFloat(fit.se / yRange)
                    let x0 = leftM, x1 = leftM + chartW
                    let y0mid = topM + chartH * (1 - yRatio(for: fit.slope * effectiveXMin + fit.intercept))
                    let y1mid = topM + chartH * (1 - yRatio(for: fit.slope * effectiveXMax + fit.intercept))
                    Path { p in
                        p.move(to: CGPoint(x: x0, y: y0mid - seH))
                        p.addLine(to: CGPoint(x: x1, y: y1mid - seH))
                        p.addLine(to: CGPoint(x: x1, y: y1mid + seH))
                        p.addLine(to: CGPoint(x: x0, y: y0mid + seH))
                        p.closeSubpath()
                    }
                    .fill(primaryColor.opacity(0.09))
                }

                // Trend line
                if showTrendLine {
                    trendLineView(chartW: chartW, chartH: chartH, leftM: leftM, topM: topM)
                }

                // Data points (rendered in order)
                ForEach(Array(orderedPoints.enumerated()), id: \.element.id) { i, pt in
                    let spt = screenPoint(for: pt, chartW: chartW, chartH: chartH, leftM: leftM, topM: topM)
                    let col = resolvedColor(for: pt)
                    let opc = resolvedOpacity(for: pt)
                    let isHL = highlightedID == pt.id
                    let pS = CGFloat(pointSize) * (isHL ? 1.45 : 1.0)
                    let shapeAny: AnyShape = pointShape == .circle
                        ? AnyShape(Circle())
                        : AnyShape(RoundedRectangle(cornerRadius: 3, style: .continuous))

                    ZStack {
                        if pointFill {
                            shapeAny
                                .fill(col.opacity(opc))
                                .glassEffect(.clear, in: shapeAny)
                        }
                        if pointStroke {
                            shapeAny.stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                            shapeAny.stroke(Color.white, lineWidth: 5)
                                .blur(radius: 3).opacity(0.28).clipShape(shapeAny)
                        }
                    }
                    .frame(width: pS, height: pS)
                    .position(x: spt.x, y: spt.y)
                    .scaleEffect(appeared ? 1.0 : 0.01)
                    .opacity(appeared ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.65)
                            .delay(animateOnLoad ? Double(i) * 0.04 : 0),
                        value: appeared
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHL)
                    .onTapGesture {
                        guard hoverHighlight else { return }
                        withAnimation(.spring(response: 0.3)) {
                            highlightedID = (highlightedID == pt.id) ? nil : pt.id
                        }
                    }

                    // Point label
                    if showPointLabels && labelPos != .hidden && !pt.label.isEmpty {
                        let offX: CGFloat = labelPos == .right ? CGFloat(pointSize) / 2 + 7 : 0
                        let offY: CGFloat = labelPos == .top   ? -(CGFloat(pointSize) / 2 + 8) : 0
                        Text(pt.label)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary.opacity(0.7))
                            .position(x: spt.x + offX, y: spt.y + offY)
                    }

                    // Highlight ring
                    if isHL {
                        shapeAny
                            .stroke(col.opacity(0.55), lineWidth: 2)
                            .frame(width: pS + 7, height: pS + 7)
                            .position(x: spt.x, y: spt.y)
                    }
                }

                // Hover tooltip
                if hoverTooltip, let hlID = highlightedID,
                   let hlPt = points.first(where: { $0.id == hlID }) {
                    scatterTooltip(
                        point: hlPt,
                        at: screenPoint(for: hlPt, chartW: chartW, chartH: chartH, leftM: leftM, topM: topM),
                        chartW: chartW, leftM: leftM
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
                    .onEnded { v in
                        if zoomPanEnabled { zoomScale = min(5, max(0.5, zoomScale * v)) }
                    }
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

    // MARK: - Trend Line View

    @ViewBuilder
    func trendLineView(chartW: CGFloat, chartH: CGFloat, leftM: CGFloat, topM: CGFloat) -> some View {
        let style = StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: trendDashed ? [6, 4] : [])
        if regressionType == .linear, let fit = linearFit() {
            let x0 = leftM, x1 = leftM + chartW
            let y0 = topM + chartH * (1 - yRatio(for: fit.slope * effectiveXMin + fit.intercept))
            let y1 = topM + chartH * (1 - yRatio(for: fit.slope * effectiveXMax + fit.intercept))
            Path { p in p.move(to: CGPoint(x: x0, y: y0)); p.addLine(to: CGPoint(x: x1, y: y1)) }
                .trim(from: 0, to: appeared ? 1 : 0)
                .stroke(primaryColor.opacity(0.6), style: style)
        } else if regressionType == .polynomial, let fn = polynomialFit() {
            polyPath(fn: fn, chartW: chartW, chartH: chartH, leftM: leftM, topM: topM)
                .trim(from: 0, to: appeared ? 1 : 0)
                .stroke(primaryColor.opacity(0.6), style: style)
        }
    }

    // MARK: - Scatter Tooltip

    @ViewBuilder
    func scatterTooltip(point: ScatterDataPoint, at pt: CGPoint, chartW: CGFloat, leftM: CGFloat) -> some View {
        let w: CGFloat = 90
        let clampedX = max(leftM + w / 2, min(pt.x, leftM + chartW - w / 2))
        VStack(alignment: .leading, spacing: 3) {
            if !point.label.isEmpty {
                Text(point.label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            HStack(spacing: 4) {
                Text("X:")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(formattedValue(point.x))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            HStack(spacing: 4) {
                Text("Y:")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(formattedValue(point.y))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(
            Color(uiColor: .systemBackground).opacity(0.92),
            in: .rect(cornerRadius: 8, style: .continuous)
        )
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        .position(x: clampedX, y: max(32, pt.y - 40))
    }

    // MARK: - Settings: Geometry

    var geometrySettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Pt Size")
                Slider(value: $pointSize, in: 2...20, step: 0.5)
                Text(String(format: "%.1fpt", pointSize))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Opacity")
                Slider(value: $pointOpacity, in: 0...1, step: 0.05)
                Text("\(Int(pointOpacity * 100))%")
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
                    ForEach(ScatterFormat.allCases, id: \.self) { f in
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
                    ForEach(ScatterAxisScale.allCases, id: \.self) { s in
                        pillButton(s.rawValue, isSelected: axisScale == s) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { axisScale = s }
                        }
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Settings: Point Styling

    var pointStyleSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Shape")
                HStack(spacing: 4) {
                    ForEach(ScatterShape.allCases, id: \.self) { s in
                        pillButton(s.rawValue, isSelected: pointShape == s) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { pointShape = s }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Stroke")
                Toggle("", isOn: $pointStroke).labelsHidden().scaleEffect(0.8)
                Text("Glass stroke").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Fill")
                Toggle("", isOn: $pointFill).labelsHidden().scaleEffect(0.8)
                Text("Fill points").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Color By")
                HStack(spacing: 4) {
                    ForEach(ScatterColorMode.allCases, id: \.self) { m in
                        pillButton(m.rawValue, isSelected: colorMode == m) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { colorMode = m }
                        }
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Settings: Color

    var colorSettingsView: some View {
        settingsSection {
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
                Text("Opacity by value").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Trend & Analysis

    var trendSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Trend Ln")
                Toggle("", isOn: $showTrendLine).labelsHidden().scaleEffect(0.8)
                Text("Show regression line").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if showTrendLine {
                HStack(spacing: 10) {
                    settingsLabel("Ln Style")
                    HStack(spacing: 4) {
                        pillButton("Solid", isSelected: !trendDashed) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { trendDashed = false }
                        }
                        pillButton("Dashed", isSelected: trendDashed) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { trendDashed = true }
                        }
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    settingsLabel("Type")
                    HStack(spacing: 4) {
                        ForEach(RegressionKind.allCases, id: \.self) { r in
                            pillButton(r.rawValue, isSelected: regressionType == r) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { regressionType = r }
                            }
                        }
                    }
                    Spacer()
                }
            }
            HStack(spacing: 10) {
                settingsLabel("Conf Band")
                Toggle("", isOn: $showConfidenceBand).labelsHidden().scaleEffect(0.8)
                Text("Confidence band (±1σ)").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
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

    // MARK: - Settings: Labels

    var labelSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Labels")
                Toggle("", isOn: $showPointLabels).labelsHidden().scaleEffect(0.8)
                Text("Show point labels").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if showPointLabels {
                HStack(spacing: 10) {
                    settingsLabel("Position")
                    HStack(spacing: 4) {
                        ForEach(ScatterLabelPos.allCases, id: \.self) { p in
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
                Text("Show X/Y tooltip").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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

    // MARK: - Settings: Render Order

    var renderOrderSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Render")
                HStack(spacing: 4) {
                    ForEach(ScatterRenderOrder.allCases, id: \.self) { o in
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
    func itemRow(index: Int, point: ScatterDataPoint) -> some View {
        HStack(spacing: 10) {

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
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                    .opacity(colorMode == .category ? 1.0 : 0.3)
            }

            // Label field
            if editingID == point.id && editingField == .label {
                TextField("Label", text: $editingText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .onChange(of: editingText) { _, val in points[index].label = val }
            } else {
                Button {
                    editingID = point.id
                    editingField = .label
                    editingText = point.label
                } label: {
                    Text(point.label.isEmpty ? "Point \(index + 1)" : point.label)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(point.label.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .underline(color: .primary.opacity(point.label.isEmpty ? 0 : 0.2))
                }
                .foregroundStyle(.primary)
            }

            // X value
            VStack(alignment: .trailing, spacing: 1) {
                Text("X")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                if editingID == point.id && editingField == .x {
                    TextField("0", text: $editingText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(width: 44)
                        .onChange(of: editingText) { _, val in if let v = Double(val) { points[index].x = v } }
                } else {
                    Button {
                        editingID = point.id
                        editingField = .x
                        editingText = String(format: "%.0f", point.x)
                    } label: {
                        Text(String(format: "%.0f", point.x))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .underline(color: .primary.opacity(0.25))
                    }
                    .foregroundStyle(.primary)
                }
            }

            // Y value
            VStack(alignment: .trailing, spacing: 1) {
                Text("Y")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                if editingID == point.id && editingField == .y {
                    TextField("0", text: $editingText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(width: 44)
                        .onChange(of: editingText) { _, val in if let v = Double(val) { points[index].y = v } }
                } else {
                    Button {
                        editingID = point.id
                        editingField = .y
                        editingText = String(format: "%.0f", point.y)
                    } label: {
                        Text(String(format: "%.0f", point.y))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .underline(color: .primary.opacity(0.25))
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        if index < points.count - 1 { Divider().padding(.horizontal, 20) }
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
            points.append(ScatterDataPoint(
                label: "P\(points.count + 1)",
                x: Double.random(in: 10...90),
                y: Double.random(in: 10...90),
                color: Self.colorPalette[colIdx]
            ))
        }
    }
}

#Preview {
    ScrollView {
        ScatterPlotCard(
            title: "Scatter Plot",
            categories: ["Scatter", "Plot"],
            points: [
                ScatterDataPoint(label: "A", x: 12, y: 18, color: AnalyticsCard.colorPalette[0]),
                ScatterDataPoint(label: "B", x: 25, y: 32, color: AnalyticsCard.colorPalette[1]),
                ScatterDataPoint(label: "C", x: 34, y: 28, color: AnalyticsCard.colorPalette[2]),
                ScatterDataPoint(label: "D", x: 45, y: 55, color: AnalyticsCard.colorPalette[3]),
                ScatterDataPoint(label: "E", x: 52, y: 48, color: AnalyticsCard.colorPalette[4]),
                ScatterDataPoint(label: "F", x: 63, y: 70, color: AnalyticsCard.colorPalette[5]),
                ScatterDataPoint(label: "G", x: 71, y: 65, color: AnalyticsCard.colorPalette[0]),
                ScatterDataPoint(label: "H", x: 82, y: 88, color: AnalyticsCard.colorPalette[1]),
            ]
        )
        .padding(.top, 20)
    }
}
