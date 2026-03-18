//
//  SparklineChartExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Sparkline Chart Card

struct SparklineChartCard: View {

    let title: String
    let categories: [String]
    @State private var items: [AnalyticsDataItem]
    @State private var isExpanded = false
    @State private var editingID: UUID? = nil
    @State private var editingText = ""
    @State private var appeared = false
    @State private var highlightedIdx: Int? = nil

    // Chart Geometry
    @State private var lineThickness: Double = 2.0
    @State private var chartHeight: Double = 72
    @State private var chartPadding: Double = 8

    // Display Mode
    @State private var displayStyle: DisplayStyle = .area
    @State private var compactMode: Bool = false

    // Axis Controls
    @State private var showBaseline: Bool = true
    @State private var showMinMaxMarkers: Bool = false
    @State private var showStartEndMarkers: Bool = false

    // Value Scaling
    @State private var autoScale: Bool = true
    @State private var fixedRange: Bool = false
    @State private var fixedMin: Double = 0
    @State private var fixedMax: Double = 100
    @State private var fixedMinText: String = "0"
    @State private var fixedMaxText: String = "100"

    // Line / Area Styling
    @State private var curveType: SpkCurveType = .smooth
    @State private var gradientFill: Bool = true
    @State private var areaOpacity: Double = 0.30
    @State private var lineDashed: Bool = false
    @State private var lineOpacity: Double = 1.0

    // Point Styling
    @State private var showPoints: Bool = false
    @State private var pointSize: Double = 5
    @State private var highlightLatest: Bool = true

    // Color Controls
    @State private var primaryColor: Color
    @State private var positiveNegativeColor: Bool = false

    // Labels
    @State private var showCurrentValue: Bool = true
    @State private var showDelta: Bool = true
    @State private var labelPosition: SpkLabelPos = .top

    // Interaction
    @State private var hoverTooltip: Bool = true
    @State private var hoverHighlight: Bool = true
    @State private var animateOnLoad: Bool = true
    @State private var animationDuration: Double = 0.8

    // Trend
    @State private var showTrendLine: Bool = false
    @State private var showTrendIndicator: Bool = true

    #if os(iOS)
    @State private var pickerCoordinator: ColorPickerCoordinator? = nil
    #endif

    // MARK: - Enums

    enum DisplayStyle: String, CaseIterable { case line = "Line", area = "Area", bar = "Bar" }
    enum SpkCurveType: String, CaseIterable { case straight = "Straight", smooth = "Smooth" }
    enum SpkLabelPos: String, CaseIterable { case top = "Top", bottom = "Bottom", hidden = "Hidden" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Init

    init(title: String, categories: [String], items: [AnalyticsDataItem]) {
        self.title = title
        self.categories = categories
        self._items = State(initialValue: items)
        self._primaryColor = State(initialValue: items.first?.color ?? AnalyticsCard.colorPalette[0])
    }

    // MARK: - Computed

    var values: [Double] { items.map { $0.percentage } }

    var chartColor: Color {
        guard positiveNegativeColor else { return primaryColor }
        let trend = (values.last ?? 0) - (values.first ?? 0)
        return trend >= 0
            ? Color(red: 0.18, green: 0.72, blue: 0.44)
            : Color(red: 0.90, green: 0.25, blue: 0.25)
    }

    var effectiveYMin: Double {
        if fixedRange { return fixedMin }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 100
        if autoScale { return minV - (maxV - minV) * 0.12 }
        return 0
    }

    var effectiveYMax: Double {
        if fixedRange { return fixedMax }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 100
        if autoScale { return maxV + (maxV - minV) * 0.12 }
        return 100
    }

    func yRatio(for value: Double) -> CGFloat {
        let range = effectiveYMax - effectiveYMin
        guard range > 0 else { return 0 }
        return CGFloat(max(0, min(1, (value - effectiveYMin) / range)))
    }

    var deltaValue: Double { (values.last ?? 0) - (values.first ?? 0) }
    var currentValue: Double { values.last ?? 0 }
    var isPositiveTrend: Bool { deltaValue >= 0 }

    // MARK: - Path Helpers

    func dataPoints(chartW: CGFloat, chartH: CGFloat, leftM: CGFloat, topM: CGFloat) -> [CGPoint] {
        let n = values.count
        guard n > 0 else { return [] }
        let xStep = n > 1 ? chartW / CGFloat(n - 1) : chartW / 2
        return values.enumerated().map { i, val in
            CGPoint(
                x: leftM + (n > 1 ? CGFloat(i) * xStep : chartW / 2),
                y: topM + chartH * (1 - yRatio(for: val))
            )
        }
    }

    func linePath(points: [CGPoint]) -> Path {
        guard points.count >= 2 else { return Path() }
        var path = Path()
        path.move(to: points[0])
        if curveType == .straight {
            for i in 1..<points.count { path.addLine(to: points[i]) }
        } else {
            let t: CGFloat = 0.4
            for i in 1..<points.count {
                let prev  = i > 1 ? points[i - 2] : points[i - 1]
                let curr  = points[i - 1]
                let next  = points[i]
                let next2 = i < points.count - 1 ? points[i + 1] : points[i]
                let cp1 = CGPoint(x: curr.x + (next.x - prev.x) * t / 3,
                                  y: curr.y + (next.y - prev.y) * t / 3)
                let cp2 = CGPoint(x: next.x - (next2.x - curr.x) * t / 3,
                                  y: next.y - (next2.y - curr.y) * t / 3)
                path.addCurve(to: next, control1: cp1, control2: cp2)
            }
        }
        return path
    }

    func makeAreaPath(points: [CGPoint], baselineY: CGFloat) -> Path {
        var path = linePath(points: points)
        path.addLine(to: CGPoint(x: points.last!.x, y: baselineY))
        path.addLine(to: CGPoint(x: points.first!.x, y: baselineY))
        path.closeSubpath()
        return path
    }

    func trendEndpoints(chartW: CGFloat, chartH: CGFloat, leftM: CGFloat, topM: CGFloat) -> (CGPoint, CGPoint) {
        let n = Double(values.count)
        guard n >= 2 else { return (.zero, .zero) }
        let xs = (0..<values.count).map { Double($0) }
        let xMean = xs.reduce(0, +) / n
        let yMean = values.reduce(0, +) / n
        let num = zip(xs, values).reduce(0.0) { $0 + ($1.0 - xMean) * ($1.1 - yMean) }
        let den = xs.reduce(0.0) { $0 + ($1 - xMean) * ($1 - xMean) }
        let slope = den > 0 ? num / den : 0
        let intercept = yMean - slope * xMean
        let y0 = slope * 0 + intercept
        let yn = slope * Double(values.count - 1) + intercept
        return (
            CGPoint(x: leftM, y: topM + chartH * (1 - yRatio(for: y0))),
            CGPoint(x: leftM + chartW, y: topM + chartH * (1 - yRatio(for: yn)))
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // Chart area — always visible
            sparklineView
                .padding(.horizontal, compactMode ? 12 : 16)
                .padding(.top, compactMode ? 14 : 16)
                .padding(.bottom, compactMode ? 14 : 8)

            if !compactMode {
                Divider().padding(.horizontal, 12)

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
                        displayModeSettingsView
                        axisSettingsView
                        scalingSettingsView
                        lineAreaSettingsView
                        pointSettingsView
                        colorSettingsView
                        labelSettingsView
                        interactionSettingsView
                        trendSettingsView
                        itemListView
                    }
                    .frame(maxHeight: isExpanded ? .infinity : 0)
                    .clipped()
                    .opacity(isExpanded ? 1 : 0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isExpanded)
                }
                .padding(.bottom, 8)
            }
        }
        .background(Color(uiColor: .systemGray6), in: .rect(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 12)
        .onAppear {
            if animateOnLoad {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: animationDuration)) { appeared = true }
                }
            } else {
                appeared = true
            }
        }
        .onTapGesture { editingID = nil; highlightedIdx = nil }
    }

    // MARK: - Sparkline View

    var sparklineView: some View {
        GeometryReader { geo in
            let topLabel = !compactMode && labelPosition == .top && (showCurrentValue || showDelta)
            let botLabel = !compactMode && labelPosition == .bottom && (showCurrentValue || showDelta)
            let leftM:  CGFloat = CGFloat(chartPadding)
            let rightM: CGFloat = CGFloat(chartPadding)
            let topM:   CGFloat = topLabel ? 22 : CGFloat(chartPadding)
            let botM:   CGFloat = botLabel ? 20 : CGFloat(chartPadding)
            let chartW  = geo.size.width  - leftM - rightM
            let chartH  = geo.size.height - topM  - botM
            let pts     = dataPoints(chartW: chartW, chartH: chartH, leftM: leftM, topM: topM)
            let baselineY = topM + chartH * (1 - yRatio(for: max(effectiveYMin, 0)))

            ZStack(alignment: .topLeading) {

                // Baseline
                if showBaseline {
                    Path { p in
                        p.move(to: CGPoint(x: leftM, y: baselineY))
                        p.addLine(to: CGPoint(x: leftM + chartW, y: baselineY))
                    }
                    .stroke(Color.primary.opacity(0.18), style: StrokeStyle(lineWidth: 0.75))
                }

                if !pts.isEmpty {
                    switch displayStyle {
                    case .bar:
                        barsView(pts: pts, baselineY: baselineY)
                    case .area:
                        areaLayerView(pts: pts, topM: topM, chartH: chartH, baselineY: baselineY)
                        lineLayerView(pts: pts)
                    case .line:
                        lineLayerView(pts: pts)
                    }

                    // Trend line (overlay, for line/area modes)
                    if showTrendLine && displayStyle != .bar {
                        let (t0, t1) = trendEndpoints(chartW: chartW, chartH: chartH, leftM: leftM, topM: topM)
                        Path { p in p.move(to: t0); p.addLine(to: t1) }
                            .trim(from: 0, to: appeared ? 1 : 0)
                            .stroke(
                                chartColor.opacity(0.45),
                                style: StrokeStyle(lineWidth: 1.0, dash: [4, 3])
                            )
                    }

                    // Data points
                    if showPoints && displayStyle != .bar {
                        pointsView(pts: pts)
                    }

                    // Latest point highlight
                    if highlightLatest && displayStyle != .bar {
                        latestPointView(pts: pts)
                    }

                    // Min/Max markers
                    if showMinMaxMarkers {
                        minMaxMarkersView(pts: pts)
                    }

                    // Start/End markers
                    if showStartEndMarkers {
                        startEndMarkersView(pts: pts)
                    }

                    // Hover tooltip
                    if hoverTooltip, let idx = highlightedIdx, idx < pts.count {
                        tooltipView(
                            pt: pts[idx],
                            value: values[idx],
                            chartW: chartW, leftM: leftM
                        )
                    }
                }

                // Labels (top / bottom)
                if !compactMode && labelPosition != .hidden && (showCurrentValue || showDelta) {
                    labelsRow(
                        yPos: topLabel ? topM / 2 : topM + chartH + botM / 2,
                        leftM: leftM, chartW: chartW
                    )
                }

                // Trend direction indicator (top-right)
                if showTrendIndicator && !compactMode && !pts.isEmpty {
                    trendIndicatorView(topM: topM, geo: geo)
                }
            }
            // Tap: find nearest point
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        guard (hoverTooltip || hoverHighlight) && !pts.isEmpty else { return }
                        let loc = value.location
                        let nearest = pts.enumerated().min(by: {
                            abs($0.element.x - loc.x) < abs($1.element.x - loc.x)
                        })
                        if let (i, _) = nearest {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                highlightedIdx = (highlightedIdx == i) ? nil : i
                            }
                        }
                    }
            )
        }
        .frame(height: CGFloat(chartHeight))
    }

    // MARK: - Bar View

    @ViewBuilder
    func barsView(pts: [CGPoint], baselineY: CGFloat) -> some View {
        let n = pts.count
        let barW: CGFloat = n > 1 ? (pts[1].x - pts[0].x) * 0.62 : 20
        ForEach(Array(pts.enumerated()), id: \.offset) { i, pt in
            let isHL = highlightedIdx == i
            let barH = max(1, baselineY - pt.y)
            let barShape = RoundedRectangle(cornerRadius: 3, style: .continuous)
            ZStack {
                barShape
                    .fill(chartColor.opacity(isHL ? 1.0 : 0.75))
                    .glassEffect(.clear, in: barShape)
                barShape.stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                barShape.stroke(Color.white, lineWidth: 5)
                    .blur(radius: 3).opacity(0.22).clipShape(barShape)
            }
            .frame(width: barW, height: barH)
            .position(x: pt.x, y: pt.y + barH / 2)
            .scaleEffect(x: 1, y: appeared ? 1 : 0.01, anchor: .bottom)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.04),
                value: appeared
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    highlightedIdx = (highlightedIdx == i) ? nil : i
                }
            }
        }
    }

    // MARK: - Area Layer

    @ViewBuilder
    func areaLayerView(pts: [CGPoint], topM: CGFloat, chartH: CGFloat, baselineY: CGFloat) -> some View {
        let area = makeAreaPath(points: pts, baselineY: baselineY)
        if gradientFill {
            area.fill(
                LinearGradient(
                    colors: [chartColor.opacity(areaOpacity), chartColor.opacity(areaOpacity * 0.05)],
                    startPoint: .top, endPoint: .bottom
                )
            )
        } else {
            area.fill(chartColor.opacity(areaOpacity))
        }
    }

    // MARK: - Line Layer

    @ViewBuilder
    func lineLayerView(pts: [CGPoint]) -> some View {
        let stroke = StrokeStyle(
            lineWidth: CGFloat(lineThickness),
            lineCap: .round,
            lineJoin: .round,
            dash: lineDashed ? [6, 4] : []
        )
        if gradientFill && displayStyle == .area {
            linePath(points: pts)
                .trim(from: 0, to: appeared ? 1 : 0)
                .stroke(
                    LinearGradient(
                        colors: [chartColor.opacity(lineOpacity), chartColor.opacity(lineOpacity * 0.6)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    style: stroke
                )
        } else {
            linePath(points: pts)
                .trim(from: 0, to: appeared ? 1 : 0)
                .stroke(chartColor.opacity(lineOpacity), style: stroke)
        }
    }

    // MARK: - Points View

    @ViewBuilder
    func pointsView(pts: [CGPoint]) -> some View {
        ForEach(Array(pts.enumerated()), id: \.offset) { i, pt in
            let isHL = highlightedIdx == i
            let pS = CGFloat(pointSize)
            ZStack {
                Circle().fill(chartColor).glassEffect(.clear, in: Circle())
                Circle().stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                Circle().stroke(Color.white, lineWidth: 5)
                    .blur(radius: 3).opacity(0.3).clipShape(Circle())
            }
            .frame(width: pS, height: pS)
            .position(x: pt.x, y: pt.y)
            .scaleEffect(isHL ? 1.4 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHL)
        }
    }

    // MARK: - Latest Point

    @ViewBuilder
    func latestPointView(pts: [CGPoint]) -> some View {
        let lastPt = pts.last!
        let pS = CGFloat(max(pointSize, 7))
        ZStack {
            Circle().fill(chartColor).glassEffect(.clear, in: Circle())
            Circle().stroke(Color.white.opacity(0.35), lineWidth: 0.5)
            Circle().stroke(Color.white, lineWidth: 5)
                .blur(radius: 3).opacity(0.3).clipShape(Circle())
        }
        .frame(width: pS, height: pS)
        .position(x: lastPt.x, y: lastPt.y)
        .scaleEffect(appeared ? 1.0 : 0.2)
        .opacity(appeared ? 1 : 0)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.65)
                .delay(animateOnLoad ? animationDuration * 0.85 : 0),
            value: appeared
        )
    }

    // MARK: - Min/Max Markers

    @ViewBuilder
    func minMaxMarkersView(pts: [CGPoint]) -> some View {
        if let minIdx = values.indices.min(by: { values[$0] < values[$1] }),
           let maxIdx = values.indices.min(by: { values[$0] > values[$1] }) {
            markerDot(
                at: pts[minIdx],
                label: "\(Int(values[minIdx]))",
                color: Color(red: 0.90, green: 0.28, blue: 0.28),
                above: false
            )
            markerDot(
                at: pts[maxIdx],
                label: "\(Int(values[maxIdx]))",
                color: Color(red: 0.18, green: 0.72, blue: 0.44),
                above: true
            )
        }
    }

    // MARK: - Start/End Markers

    @ViewBuilder
    func startEndMarkersView(pts: [CGPoint]) -> some View {
        markerDot(
            at: pts.first!,
            label: "\(Int(values.first ?? 0))",
            color: chartColor.opacity(0.65),
            above: true
        )
        markerDot(
            at: pts.last!,
            label: "\(Int(values.last ?? 0))",
            color: chartColor,
            above: true
        )
    }

    @ViewBuilder
    func markerDot(at pt: CGPoint, label: String, color: Color, above: Bool) -> some View {
        Circle()
            .fill(color)
            .frame(width: 5, height: 5)
            .position(x: pt.x, y: pt.y)
        Text(label)
            .font(.system(size: 8, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .position(x: pt.x, y: pt.y + (above ? -12 : 12))
    }

    // MARK: - Tooltip

    @ViewBuilder
    func tooltipView(pt: CGPoint, value: Double, chartW: CGFloat, leftM: CGFloat) -> some View {
        let tooltipW: CGFloat = 48
        let rawX = pt.x - tooltipW / 2
        let clampedX = max(leftM, min(rawX, leftM + chartW - tooltipW))
        Text("\(Int(value))")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(
                Color(uiColor: .systemBackground).opacity(0.90),
                in: .rect(cornerRadius: 7, style: .continuous)
            )
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
            .position(x: clampedX + tooltipW / 2, y: max(12, pt.y - 20))
    }

    // MARK: - Labels Row

    @ViewBuilder
    func labelsRow(yPos: CGFloat, leftM: CGFloat, chartW: CGFloat) -> some View {
        HStack(spacing: 6) {
            if showCurrentValue {
                Text("\(Int(currentValue))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(chartColor)
            }
            if showDelta {
                HStack(spacing: 2) {
                    Image(systemName: isPositiveTrend ? "arrow.up" : "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                    Text("\(Int(abs(deltaValue)))")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(
                    isPositiveTrend
                        ? Color(red: 0.18, green: 0.72, blue: 0.44)
                        : Color(red: 0.90, green: 0.25, blue: 0.25)
                )
            }
            Spacer()
        }
        .frame(width: chartW)
        .position(x: leftM + chartW / 2, y: yPos)
    }

    // MARK: - Trend Indicator

    @ViewBuilder
    func trendIndicatorView(topM: CGFloat, geo: GeometryProxy) -> some View {
        let color = isPositiveTrend
            ? Color(red: 0.18, green: 0.72, blue: 0.44)
            : Color(red: 0.90, green: 0.25, blue: 0.25)
        Image(systemName: isPositiveTrend ? "arrow.up.right" : "arrow.down.right")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(4)
            .background(color.opacity(0.12), in: .rect(cornerRadius: 5, style: .continuous))
            .position(x: geo.size.width - 20, y: topM + 10)
    }

    // MARK: - Settings: Geometry

    var geometrySettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Line W")
                Slider(value: $lineThickness, in: 1...6, step: 0.5)
                Text(String(format: "%.1fpt", lineThickness))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Height")
                Slider(value: $chartHeight, in: 20...120, step: 4)
                Text("\(Int(chartHeight))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Padding")
                Slider(value: $chartPadding, in: 0...40, step: 2)
                Text("\(Int(chartPadding))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Display Mode

    var displayModeSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Style")
                HStack(spacing: 4) {
                    ForEach(DisplayStyle.allCases, id: \.self) { s in
                        pillButton(s.rawValue, isSelected: displayStyle == s) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { displayStyle = s }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Compact")
                Toggle("", isOn: $compactMode).labelsHidden().scaleEffect(0.8)
                Text("Hide labels & title").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Axis

    var axisSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Baseline")
                Toggle("", isOn: $showBaseline).labelsHidden().scaleEffect(0.8)
                Text("Show baseline").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Min/Max")
                Toggle("", isOn: $showMinMaxMarkers).labelsHidden().scaleEffect(0.8)
                Text("Min/Max markers").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Markers")
                Toggle("", isOn: $showStartEndMarkers).labelsHidden().scaleEffect(0.8)
                Text("Start/End markers").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
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
            HStack(spacing: 10) {
                settingsLabel("Fixed Rng")
                Toggle("", isOn: $fixedRange).labelsHidden().scaleEffect(0.8)
                Text("Use fixed Y range").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if fixedRange {
                HStack(spacing: 10) {
                    settingsLabel("Min Value")
                    TextField("0", text: $fixedMinText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing).frame(maxWidth: .infinity)
                        .onChange(of: fixedMinText) { _, v in if let d = Double(v) { fixedMin = d } }
                }
                HStack(spacing: 10) {
                    settingsLabel("Max Value")
                    TextField("100", text: $fixedMaxText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing).frame(maxWidth: .infinity)
                        .onChange(of: fixedMaxText) { _, v in if let d = Double(v) { fixedMax = d } }
                }
            }
        }
    }

    // MARK: - Settings: Line/Area Styling

    var lineAreaSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Curve")
                HStack(spacing: 4) {
                    ForEach(SpkCurveType.allCases, id: \.self) { c in
                        pillButton(c.rawValue, isSelected: curveType == c) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { curveType = c }
                        }
                    }
                }
                Spacer()
            }
            if displayStyle == .area {
                HStack(spacing: 10) {
                    settingsLabel("Gradient")
                    Toggle("", isOn: $gradientFill).labelsHidden().scaleEffect(0.8)
                    Text("Gradient area fill").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    Spacer()
                }
                HStack(spacing: 10) {
                    settingsLabel("Area Opc")
                    Slider(value: $areaOpacity, in: 0...1, step: 0.05)
                    Text("\(Int(areaOpacity * 100))%")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
            HStack(spacing: 10) {
                settingsLabel("Line Sty")
                HStack(spacing: 4) {
                    pillButton("Solid", isSelected: !lineDashed) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { lineDashed = false }
                    }
                    pillButton("Dashed", isSelected: lineDashed) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { lineDashed = true }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Line Opc")
                Slider(value: $lineOpacity, in: 0...1, step: 0.05)
                Text("\(Int(lineOpacity * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Point Styling

    var pointSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Points")
                Toggle("", isOn: $showPoints).labelsHidden().scaleEffect(0.8)
                Text("Show data points").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if showPoints {
                HStack(spacing: 10) {
                    settingsLabel("Point Sz")
                    Slider(value: $pointSize, in: 2...10, step: 0.5)
                    Text(String(format: "%.1fpt", pointSize))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
            HStack(spacing: 10) {
                settingsLabel("Latest")
                Toggle("", isOn: $highlightLatest).labelsHidden().scaleEffect(0.8)
                Text("Highlight latest point").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Color Controls

    var colorSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Color")
                Button {
                    #if os(iOS)
                    let coord = ColorPickerCoordinator { color in
                        primaryColor = color
                        if !items.isEmpty { items[0].color = color }
                    }
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
                settingsLabel("Pos/Neg")
                Toggle("", isOn: $positiveNegativeColor).labelsHidden().scaleEffect(0.8)
                Text("Color by trend direction").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Labels

    var labelSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Value")
                Toggle("", isOn: $showCurrentValue).labelsHidden().scaleEffect(0.8)
                Text("Show current value").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Delta")
                Toggle("", isOn: $showDelta).labelsHidden().scaleEffect(0.8)
                Text("Show delta change").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Position")
                HStack(spacing: 4) {
                    ForEach(SpkLabelPos.allCases, id: \.self) { p in
                        pillButton(p.rawValue, isSelected: labelPosition == p) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { labelPosition = p }
                        }
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Settings: Interaction

    var interactionSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Tooltip")
                Toggle("", isOn: $hoverTooltip).labelsHidden().scaleEffect(0.8)
                Text("Tap to show tooltip").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Highlight")
                Toggle("", isOn: $hoverHighlight).labelsHidden().scaleEffect(0.8)
                Text("Highlight on tap").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
                    Slider(value: $animationDuration, in: 0.2...1.5, step: 0.1)
                    Text(String(format: "%.1fs", animationDuration))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Settings: Trend Indicators

    var trendSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Trend Ln")
                Toggle("", isOn: $showTrendLine).labelsHidden().scaleEffect(0.8)
                Text("Show regression line").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Arrow")
                Toggle("", isOn: $showTrendIndicator).labelsHidden().scaleEffect(0.8)
                Text("Trend direction arrow").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Item List

    var itemListView: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                itemRow(index: index, item: item)
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
    func itemRow(index: Int, item: AnalyticsDataItem) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)
                .background(Color.black.opacity(0.06), in: Circle())
            Text(item.label.isEmpty ? "Point \(index + 1)" : item.label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            if editingID == item.id {
                TextField("0", text: $editingText)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    #if os(iOS)
                    .keyboardType(.numbersAndPunctuation)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56)
                    .onChange(of: editingText) { _, val in
                        if let v = Double(val) { items[index].percentage = v }
                    }
            } else {
                Button {
                    editingID = item.id
                    editingText = String(format: "%.0f", item.percentage)
                } label: {
                    Text(String(format: "%.0f", item.percentage))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .underline(color: .primary.opacity(0.25))
                }
                .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        if index < items.count - 1 { Divider().padding(.horizontal, 20) }
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
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            items.append(AnalyticsDataItem(
                label: "",
                percentage: Double.random(in: 30...90),
                color: primaryColor
            ))
        }
    }
}

#Preview {
    ScrollView {
        SparklineChartCard(
            title: "Sparkline Chart",
            categories: ["Sparkline", "Line Chart"],
            items: [
                AnalyticsDataItem(label: "1", percentage: 42, color: AnalyticsCard.colorPalette[0]),
                AnalyticsDataItem(label: "2", percentage: 68, color: AnalyticsCard.colorPalette[0]),
                AnalyticsDataItem(label: "3", percentage: 55, color: AnalyticsCard.colorPalette[0]),
                AnalyticsDataItem(label: "4", percentage: 82, color: AnalyticsCard.colorPalette[0]),
                AnalyticsDataItem(label: "5", percentage: 38, color: AnalyticsCard.colorPalette[0]),
                AnalyticsDataItem(label: "6", percentage: 93, color: AnalyticsCard.colorPalette[0]),
                AnalyticsDataItem(label: "7", percentage: 77, color: AnalyticsCard.colorPalette[0]),
            ]
        )
        .padding(.top, 20)
    }
}
