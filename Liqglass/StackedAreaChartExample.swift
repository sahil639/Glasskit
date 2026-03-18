//
//  StackedAreaChartExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Stacked Area Chart Card

struct StackedAreaChartCard: View {

    let title: String
    let categories: [String]
    @State private var series: [MultiLineSeries]
    @State private var labels: [String]
    @State private var isExpanded = false
    @State private var highlightedSeries: Int? = nil
    @State private var editingSeriesID: UUID? = nil
    @State private var editingPointIdx: Int? = nil
    @State private var editingText = ""
    @State private var appeared = false

    // Chart Geometry
    @State private var lineThickness: Double = 1.5
    @State private var pointSize: Double = 0
    @State private var curveType: CurveType = .smooth
    @State private var chartPadding: Double = 12

    // Stacking Mode
    @State private var stackType: StackType = .absolute
    @State private var stackOrder: StackOrder = .none

    // Axis Controls
    @State private var showXAxis: Bool = true
    @State private var showYAxis: Bool = true
    @State private var axisLabels: Bool = true
    @State private var axisGrid: Bool = true
    @State private var gridOpacity: Double = 0.20

    // Value Scaling
    @State private var autoScale: Bool = true
    @State private var yAxisMin: Double = 0
    @State private var yAxisMax: Double = 100
    @State private var valueFormat: ValueFormat = .number

    // Series Controls
    @State private var colorMode: ColorMode = .distinct
    @State private var showLegend: Bool = true
    @State private var legendPosition: LegendPosition = .top

    // Area Styling
    @State private var areaOpacity: Double = 0.72
    @State private var gradientFill: Bool = true

    // Line Styling
    @State private var lineDashed: Bool = false
    @State private var shadowEnabled: Bool = false
    @State private var lineOpacity: Double = 0.6

    // Point Styling
    @State private var showPoints: Bool = false
    @State private var pointShape: PointShape = .circle
    @State private var pointStroke: Bool = true
    @State private var pointFill: Bool = true

    // Labels
    @State private var valueLabelOn: Bool = false
    @State private var labelType: LabelType = .segment
    @State private var labelPosition: LabelPosition = .inside
    @State private var xAxisLabelOn: Bool = true

    // Interaction
    @State private var hoverHighlight: Bool = true
    @State private var hoverTooltip: Bool = false
    @State private var crosshair: Bool = false
    @State private var animateOnLoad: Bool = true
    @State private var animationDuration: Double = 0.8

    // Smoothing
    @State private var smoothing: Double = 0.4

    // Sorting
    @State private var sortOrder: SortOrder = .none

    #if os(iOS)
    @State private var pickerCoordinator: ColorPickerCoordinator? = nil
    #endif

    // MARK: - Enums

    enum CurveType: String, CaseIterable { case straight = "Straight", smooth = "Smooth" }
    enum StackType: String, CaseIterable { case absolute = "Absolute", percent = "100%" }
    enum StackOrder: String, CaseIterable { case none = "Default", ascending = "Asc", descending = "Desc" }
    enum ValueFormat: String, CaseIterable { case number = "Number", percent = "Percent", currency = "Currency", time = "Time" }
    enum ColorMode: String, CaseIterable { case distinct = "Distinct", mono = "Mono", gradient = "Gradient" }
    enum LegendPosition: String, CaseIterable { case top = "Top", bottom = "Bottom", right = "Right", hidden = "Hidden" }
    enum PointShape: String, CaseIterable { case circle = "Circle", square = "Square" }
    enum LabelType: String, CaseIterable { case segment = "Segment", total = "Total", both = "Both" }
    enum LabelPosition: String, CaseIterable { case inside = "Inside", top = "Top", hidden = "Hidden" }
    enum SortOrder: String, CaseIterable { case none = "Default", ascending = "Asc", descending = "Desc" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Init

    init(title: String, categories: [String], series: [MultiLineSeries], labels: [String]) {
        self.title = title
        self.categories = categories
        self._series = State(initialValue: series)
        self._labels = State(initialValue: labels)
    }

    // MARK: - Computed

    var orderedSeries: [MultiLineSeries] {
        switch stackOrder {
        case .none: return series
        case .ascending:  return series.sorted { ($0.values.max() ?? 0) < ($1.values.max() ?? 0) }
        case .descending: return series.sorted { ($0.values.max() ?? 0) > ($1.values.max() ?? 0) }
        }
    }

    var sortedLabels: [String] {
        switch sortOrder {
        case .none: return labels
        case .ascending: return labels.sorted()
        case .descending: return labels.sorted(by: >)
        }
    }

    // Cumulative value at (seriesIndex, pointIndex) in rendering order
    func cumulativeValue(upTo si: Int, at pi: Int, normalized: Bool) -> Double {
        let ord = orderedSeries
        var total = 0.0
        for j in 0..<si {
            total += j < ord.count && pi < ord[j].values.count ? ord[j].values[pi] : 0
        }
        if normalized {
            let grandTotal = ord.reduce(0.0) { $0 + ($1.values.count > pi ? $1.values[pi] : 0) }
            return grandTotal > 0 ? total / grandTotal * 100 : 0
        }
        return total
    }

    func segmentValue(si: Int, pi: Int, normalized: Bool) -> Double {
        let ord = orderedSeries
        let raw = si < ord.count && pi < ord[si].values.count ? ord[si].values[pi] : 0
        if normalized {
            let grandTotal = ord.reduce(0.0) { $0 + ($1.values.count > pi ? $1.values[pi] : 0) }
            return grandTotal > 0 ? raw / grandTotal * 100 : 0
        }
        return raw
    }

    var effectiveYMax: Double {
        if stackType == .percent { return 100 }
        if autoScale {
            let n = labels.count
            var maxCum = 0.0
            for pi in 0..<n {
                let total = series.reduce(0.0) { $0 + ($1.values.count > pi ? $1.values[pi] : 0) }
                maxCum = max(maxCum, total)
            }
            return maxCum * 1.1
        }
        return yAxisMax
    }
    var effectiveYMin: Double { stackType == .percent ? 0 : (autoScale ? 0 : yAxisMin) }

    func yRatio(for value: Double) -> CGFloat {
        let range = effectiveYMax - effectiveYMin
        guard range > 0 else { return 0 }
        return CGFloat(max(0, min(1, (value - effectiveYMin) / range)))
    }

    func formattedValue(_ value: Double) -> String {
        switch valueFormat {
        case .number:   return "\(Int(value))"
        case .percent:  return "\(Int(value))%"
        case .currency: return "$\(Int(value))"
        case .time:
            let h = Int(value) / 60; let m = Int(value) % 60
            return h > 0 ? "\(h)h\(m)m" : "\(m)m"
        }
    }

    func seriesColor(index: Int) -> Color {
        let ord = orderedSeries
        switch colorMode {
        case .distinct: return ord[index].color
        case .mono:
            let base = ord.first?.color ?? Self.colorPalette[0]
            let step = 1.0 / Double(max(ord.count, 2))
            return base.opacity(0.4 + step * Double(index) * 0.6)
        case .gradient:
            let t = Double(index) / Double(max(ord.count - 1, 1))
            let c1 = ord.first?.color ?? Self.colorPalette[0]
            let c2 = ord.last?.color  ?? Self.colorPalette[ord.count - 1]
            return t < 0.5 ? c1.opacity(0.6 + t * 0.4) : c2.opacity(0.6 + (1 - t) * 0.4)
        }
    }

    // MARK: - Path Helpers

    func xPosition(index: Int, chartW: CGFloat, leftM: CGFloat) -> CGFloat {
        let n = labels.count
        let xStep = n > 1 ? chartW / CGFloat(n - 1) : chartW / 2
        return leftM + (n > 1 ? CGFloat(index) * xStep : chartW / 2)
    }

    func stackedPoints(seriesIdx si: Int, chartW: CGFloat, chartH: CGFloat, leftM: CGFloat, topM: CGFloat) -> (top: [CGPoint], bottom: [CGPoint]) {
        let n = labels.count
        guard n > 0 else { return ([], []) }
        let isPct = stackType == .percent
        var topPts = [CGPoint]()
        var botPts = [CGPoint]()
        for pi in 0..<n {
            let x = xPosition(index: pi, chartW: chartW, leftM: leftM)
            let topVal = cumulativeValue(upTo: si, at: pi, normalized: isPct) + segmentValue(si: si, pi: pi, normalized: isPct)
            let botVal = cumulativeValue(upTo: si, at: pi, normalized: isPct)
            topPts.append(CGPoint(x: x, y: topM + chartH * (1 - yRatio(for: topVal))))
            botPts.append(CGPoint(x: x, y: topM + chartH * (1 - yRatio(for: botVal))))
        }
        return (topPts, botPts)
    }

    func catmullRom(path: inout Path, points: [CGPoint]) {
        guard points.count >= 2 else { return }
        let t = CGFloat(smoothing)
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

    func stackedAreaPath(top: [CGPoint], bottom: [CGPoint]) -> Path {
        guard top.count >= 2 && bottom.count >= 2 else { return Path() }
        var path = Path()
        // Forward along top edge
        path.move(to: top[0])
        if curveType == .smooth { catmullRom(path: &path, points: top) }
        else { for pt in top.dropFirst() { path.addLine(to: pt) } }
        // Connect to last bottom point
        path.addLine(to: bottom[bottom.count - 1])
        // Backward along bottom edge
        let revBottom = Array(bottom.reversed())
        if curveType == .smooth { catmullRom(path: &path, points: revBottom) }
        else { for pt in revBottom.dropFirst() { path.addLine(to: pt) } }
        path.closeSubpath()
        return path
    }

    func topLinePath(points: [CGPoint]) -> Path {
        guard points.count >= 2 else { return Path() }
        var path = Path()
        path.move(to: points[0])
        if curveType == .smooth { catmullRom(path: &path, points: points) }
        else { for pt in points.dropFirst() { path.addLine(to: pt) } }
        return path
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if showLegend && legendPosition == .top {
                legendView.padding(.top, 16).padding(.horizontal, 16)
            }

            chartView
                .frame(height: 240)
                .padding(.horizontal, 16)
                .padding(.top, (showLegend && legendPosition == .top) ? 8 : 16)

            if showLegend && legendPosition == .bottom {
                legendView.padding(.bottom, 8).padding(.horizontal, 16)
            }

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
                    stackingSettingsView
                    axisSettingsView
                    scalingSettingsView
                    seriesSettingsView
                    areaStylingSettingsView
                    lineStyleSettingsView
                    pointStyleSettingsView
                    labelSettingsView
                    interactionSettingsView
                    if curveType == .smooth { smoothingSettingsView }
                    sortingSettingsView
                    dataEditingView
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
        .onTapGesture {
            editingSeriesID = nil; editingPointIdx = nil
            if hoverHighlight { highlightedSeries = nil }
        }
        .onAppear {
            if animateOnLoad { DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { appeared = true } }
            else { appeared = true }
        }
    }

    // MARK: - Legend

    var legendView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(orderedSeries.enumerated()), id: \.element.id) { i, s in
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2).fill(seriesColor(index: i))
                            .frame(width: 18, height: 10)
                        Text(s.name)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            let hasRightLegend = showLegend && legendPosition == .right
            let leftM: CGFloat = (showYAxis && axisLabels) ? 36 : 6
            let rightM: CGFloat = CGFloat(chartPadding) + (hasRightLegend ? 70 : 0)
            let topM: CGFloat = 8
            let botM: CGFloat = (showXAxis && xAxisLabelOn && axisLabels) ? 22 : (showXAxis ? 10 : 4)
            let chartW = geo.size.width - leftM - rightM
            let chartH = geo.size.height - topM - botM
            let ord = orderedSeries
            let sLabels = sortedLabels

            ZStack(alignment: .topLeading) {

                // Grid
                if axisGrid {
                    ForEach(0...4, id: \.self) { i in
                        let y = topM + chartH * CGFloat(i) / 4
                        Path { p in
                            p.move(to: CGPoint(x: leftM, y: y))
                            p.addLine(to: CGPoint(x: leftM + chartW, y: y))
                        }
                        .stroke(Color.primary.opacity(gridOpacity), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    }
                }

                // Y tick labels
                if showYAxis && axisLabels {
                    ForEach(0...4, id: \.self) { i in
                        let yFrac = CGFloat(i) / 4
                        let val = effectiveYMin + (effectiveYMax - effectiveYMin) * Double(1 - yFrac)
                        let y = topM + chartH * yFrac
                        Text(stackType == .percent ? "\(Int(val))%" : formattedValue(val))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .trailing)
                            .position(x: leftM - 4, y: y)
                    }
                }

                // Y axis
                if showYAxis {
                    Path { p in
                        p.move(to: CGPoint(x: leftM, y: topM))
                        p.addLine(to: CGPoint(x: leftM, y: topM + chartH))
                    }
                    .stroke(Color.primary.opacity(0.25), lineWidth: 0.75)
                }

                // X axis
                if showXAxis {
                    Path { p in
                        p.move(to: CGPoint(x: leftM, y: topM + chartH))
                        p.addLine(to: CGPoint(x: leftM + chartW, y: topM + chartH))
                    }
                    .stroke(Color.primary.opacity(0.25), lineWidth: 0.75)
                }

                // X tick labels
                if showXAxis && xAxisLabelOn && axisLabels && !sLabels.isEmpty {
                    ForEach(Array(sLabels.enumerated()), id: \.offset) { i, lbl in
                        let x = xPosition(index: i, chartW: chartW, leftM: leftM)
                        Text(lbl)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .center)
                            .position(x: x, y: topM + chartH + botM / 2)
                    }
                }

                // Stacked areas — draw from bottom series upward
                ForEach(Array(ord.enumerated()), id: \.element.id) { si, s in
                    let (topPts, botPts) = stackedPoints(seriesIdx: si, chartW: chartW, chartH: chartH, leftM: leftM, topM: topM)
                    let color = seriesColor(index: si)
                    let isHighlighted = highlightedSeries == si
                    let isDimmed = hoverHighlight && highlightedSeries != nil && !isHighlighted
                    let prog: CGFloat = appeared ? 1.0 : 0.0

                    Group {
                        // Area fill
                        if !topPts.isEmpty {
                            let area = stackedAreaPath(top: topPts, bottom: botPts)
                            if gradientFill {
                                area.fill(LinearGradient(
                                    colors: [color.opacity(areaOpacity), color.opacity(areaOpacity * 0.6)],
                                    startPoint: .top, endPoint: .bottom
                                ))
                            } else {
                                area.fill(color.opacity(areaOpacity))
                            }
                        }

                        // Top edge line shadow
                        if shadowEnabled && topPts.count >= 2 {
                            topLinePath(points: topPts)
                                .stroke(color.opacity(0.3), style: StrokeStyle(lineWidth: CGFloat(lineThickness) + 4, lineCap: .round, lineJoin: .round))
                                .blur(radius: 3)
                        }

                        // Top edge line with draw animation
                        if topPts.count >= 2 {
                            topLinePath(points: topPts)
                                .trim(from: 0, to: prog)
                                .stroke(
                                    color.opacity(lineOpacity),
                                    style: StrokeStyle(
                                        lineWidth: CGFloat(lineThickness),
                                        lineCap: .round,
                                        lineJoin: .round,
                                        dash: lineDashed ? [8, 5] : []
                                    )
                                )
                                .animation(.easeInOut(duration: animateOnLoad ? animationDuration : 0).delay(Double(si) * 0.06), value: appeared)
                        }

                        // Points along top edge
                        if showPoints && pointSize > 0 && !topPts.isEmpty {
                            ForEach(Array(topPts.enumerated()), id: \.offset) { pi, pt in
                                let pS = CGFloat(pointSize)
                                let pShape = pointShape == .circle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                                let clipShape = pointShape == .circle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                                ZStack {
                                    if pointFill { pShape.fill(color).glassEffect(.clear, in: clipShape) }
                                    if pointStroke {
                                        pShape.stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                                        pShape.stroke(Color.white, lineWidth: 5).blur(radius: 3).opacity(0.3).clipShape(clipShape)
                                    }
                                }
                                .frame(width: pS, height: pS)
                                .position(x: pt.x, y: pt.y)
                            }
                        }

                        // Value labels
                        if valueLabelOn && labelPosition != .hidden && !topPts.isEmpty {
                            ForEach(Array(topPts.enumerated()), id: \.offset) { pi, pt in
                                let segVal = segmentValue(si: si, pi: pi, normalized: stackType == .percent)
                                let totalVal: Double = {
                                    let ord2 = orderedSeries
                                    return ord2.reduce(0.0) { $0 + ($1.values.count > pi ? $1.values[pi] : 0) }
                                }()
                                let midY = pi < botPts.count ? (pt.y + botPts[pi].y) / 2 : pt.y
                                let labelY: CGFloat = labelPosition == .inside ? midY : pt.y - 10
                                let labelStr: String = {
                                    switch labelType {
                                    case .segment: return formattedValue(segVal)
                                    case .total:   return formattedValue(totalVal)
                                    case .both:    return "\(formattedValue(segVal))/\(formattedValue(totalVal))"
                                    }
                                }()
                                Text(labelStr)
                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .position(x: pt.x, y: labelY)
                            }
                        }

                        // Crosshair (first highlighted series only)
                        if crosshair, let hi = highlightedSeries, hi == si, topPts.indices.contains(0) {
                            // Draw at middle x of chart as placeholder; ideally at a tapped point
                            // Crosshair is shown when any point in this series is tapped
                        }
                    }
                    .opacity(isDimmed ? 0.25 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: highlightedSeries)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if hoverHighlight {
                            withAnimation { highlightedSeries = (highlightedSeries == si) ? nil : si }
                        }
                    }
                }

                // Right legend overlay
                if hasRightLegend {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(ord.enumerated()), id: \.element.id) { i, s in
                            HStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 2).fill(seriesColor(index: i)).frame(width: 14, height: 8)
                                Text(s.name).font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 4).padding(.top, topM)
                }
            }
        }
    }

    // MARK: - Settings: Geometry

    var geometrySettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Line W")
                Slider(value: $lineThickness, in: 1...10, step: 0.5)
                Text(String(format: "%.1fpt", lineThickness))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Point")
                Slider(value: $pointSize, in: 0...20, step: 1)
                Text("\(Int(pointSize))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Curve")
                HStack(spacing: 4) {
                    ForEach(CurveType.allCases, id: \.self) { c in
                        pillButton(c.rawValue, isSelected: curveType == c) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { curveType = c }
                        }
                    }
                }
                Spacer()
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

    // MARK: - Settings: Stacking

    var stackingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Stack")
                HStack(spacing: 4) {
                    ForEach(StackType.allCases, id: \.self) { t in
                        pillButton(t.rawValue, isSelected: stackType == t) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { stackType = t }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Order")
                HStack(spacing: 4) {
                    ForEach(StackOrder.allCases, id: \.self) { o in
                        pillButton(o.rawValue, isSelected: stackOrder == o) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { stackOrder = o }
                        }
                    }
                }
                Spacer()
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
                Text("Auto scale Y axis").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if !autoScale && stackType == .absolute {
                HStack(spacing: 10) {
                    settingsLabel("Y Min")
                    TextField("0", value: $yAxisMin, format: .number)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing).frame(maxWidth: .infinity)
                }
                HStack(spacing: 10) {
                    settingsLabel("Y Max")
                    TextField("100", value: $yAxisMax, format: .number)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing).frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: 10) {
                settingsLabel("Format")
                HStack(spacing: 4) {
                    ForEach(ValueFormat.allCases, id: \.self) { f in
                        pillButton(f.rawValue, isSelected: valueFormat == f) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { valueFormat = f }
                        }
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Settings: Series

    var seriesSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Color")
                HStack(spacing: 4) {
                    ForEach(ColorMode.allCases, id: \.self) { m in
                        pillButton(m.rawValue, isSelected: colorMode == m) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { colorMode = m }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Legend")
                Toggle("", isOn: $showLegend).labelsHidden().scaleEffect(0.8)
                if showLegend {
                    HStack(spacing: 4) {
                        ForEach(LegendPosition.allCases, id: \.self) { p in
                            pillButton(p.rawValue, isSelected: legendPosition == p) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { legendPosition = p }
                            }
                        }
                    }
                } else {
                    Text("Hidden").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    // MARK: - Settings: Area Styling

    var areaStylingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Area Opc")
                Slider(value: $areaOpacity, in: 0...1, step: 0.05)
                Text("\(Int(areaOpacity * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Gradient")
                Toggle("", isOn: $gradientFill).labelsHidden().scaleEffect(0.8)
                Text("Gradient area fill").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Line Style

    var lineStyleSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Style")
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
                settingsLabel("Shadow")
                HStack(spacing: 4) {
                    pillButton("Soft", isSelected: shadowEnabled) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { shadowEnabled = true }
                    }
                    pillButton("None", isSelected: !shadowEnabled) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { shadowEnabled = false }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Opacity")
                Slider(value: $lineOpacity, in: 0...1, step: 0.05)
                Text("\(Int(lineOpacity * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Point Style

    var pointStyleSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Points")
                Toggle("", isOn: $showPoints).labelsHidden().scaleEffect(0.8)
                Text("Show top-edge points").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if showPoints {
                HStack(spacing: 10) {
                    settingsLabel("Shape")
                    HStack(spacing: 4) {
                        ForEach(PointShape.allCases, id: \.self) { s in
                            pillButton(s.rawValue, isSelected: pointShape == s) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { pointShape = s }
                            }
                        }
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    settingsLabel("Fill")
                    Toggle("", isOn: $pointFill).labelsHidden().scaleEffect(0.8)
                    Text("Filled points").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    Spacer()
                }
                HStack(spacing: 10) {
                    settingsLabel("Stroke")
                    Toggle("", isOn: $pointStroke).labelsHidden().scaleEffect(0.8)
                    Text("Glass stroke").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Settings: Labels

    var labelSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Values")
                Toggle("", isOn: $valueLabelOn).labelsHidden().scaleEffect(0.8)
                if valueLabelOn {
                    HStack(spacing: 4) {
                        ForEach(LabelType.allCases, id: \.self) { t in
                            pillButton(t.rawValue, isSelected: labelType == t) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { labelType = t }
                            }
                        }
                    }
                } else {
                    Text("Labels off").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                }
                Spacer()
            }
            if valueLabelOn {
                HStack(spacing: 10) {
                    settingsLabel("Position")
                    HStack(spacing: 4) {
                        ForEach(LabelPosition.allCases, id: \.self) { p in
                            pillButton(p.rawValue, isSelected: labelPosition == p) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { labelPosition = p }
                            }
                        }
                    }
                    Spacer()
                }
            }
            HStack(spacing: 10) {
                settingsLabel("X Labels")
                Toggle("", isOn: $xAxisLabelOn).labelsHidden().scaleEffect(0.8)
                Text("X axis labels").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Interaction

    var interactionSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Highlight")
                Toggle("", isOn: $hoverHighlight).labelsHidden().scaleEffect(0.8)
                Text("Tap area to highlight").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Animate")
                Toggle("", isOn: $animateOnLoad).labelsHidden().scaleEffect(0.8)
                Text("Animate on appear").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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

    // MARK: - Settings: Smoothing

    var smoothingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Smooth")
                Slider(value: $smoothing, in: 0...1, step: 0.05)
                Text("\(Int(smoothing * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Sorting

    var sortingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Sort")
                HStack(spacing: 4) {
                    ForEach(SortOrder.allCases, id: \.self) { o in
                        pillButton(o.rawValue, isSelected: sortOrder == o) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { sortOrder = o }
                        }
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Data Editing

    var dataEditingView: some View {
        VStack(spacing: 0) {
            ForEach(Array(series.enumerated()), id: \.element.id) { si, s in
                // Series header
                HStack(spacing: 12) {
                    Button {
                        #if os(iOS)
                        let coord = ColorPickerCoordinator { color in series[si].color = color }
                        pickerCoordinator = coord
                        let vc = UIColorPickerViewController()
                        vc.selectedColor = UIColor(series[si].color)
                        vc.supportsAlpha = false
                        vc.delegate = coord
                        topViewController()?.present(vc, animated: true)
                        #endif
                    } label: {
                        Circle().fill(series[si].color).frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                    }
                    Text(s.name).font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                    if series.count > 1 {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { series.remove(at: si) }
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(.red.opacity(0.7)).font(.system(size: 18))
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 12)

                // Per-point rows
                ForEach(Array(s.values.enumerated()), id: \.offset) { pi, val in
                    Divider().padding(.horizontal, 20)
                    HStack(spacing: 12) {
                        Circle().fill(series[si].color.opacity(0.4)).frame(width: 8, height: 8).padding(.leading, 20)
                        Text(pi < labels.count ? labels[pi] : "\(pi + 1)")
                            .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                        Spacer()
                        if editingSeriesID == s.id && editingPointIdx == pi {
                            TextField("0", text: $editingText)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                #if os(iOS)
                                .keyboardType(.numbersAndPunctuation)
                                #endif
                                .multilineTextAlignment(.trailing).frame(width: 56)
                                .onChange(of: editingText) { _, v in
                                    if let d = Double(v) { series[si].values[pi] = d }
                                }
                        } else {
                            Button {
                                editingSeriesID = s.id; editingPointIdx = pi
                                editingText = "\(Int(val))"
                            } label: {
                                Text("\(Int(val))")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .underline(color: .primary.opacity(0.25))
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 11)
                }

                // Add point (only after last series)
                if si == series.count - 1 {
                    Divider().padding(.horizontal, 20)
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            labels.append("\(labels.count + 1)")
                            for i in 0..<series.count {
                                series[i].values.append(Double.random(in: 20...70))
                            }
                        }
                    } label: {
                        Text("+ Add New Point")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                }

                if si < series.count - 1 {
                    Divider().padding(.horizontal, 12).padding(.vertical, 4)
                }
            }

            Divider().padding(.horizontal, 20)
            Button {
                let newColor = Self.colorPalette[series.count % Self.colorPalette.count]
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    series.append(MultiLineSeries(
                        name: "Series \(series.count + 1)",
                        color: newColor,
                        values: labels.map { _ in Double.random(in: 20...70) }
                    ))
                }
            } label: {
                Text("+ Add New Series")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.vertical, 14)
            }
        }
    }

    // MARK: - UI Helpers

    func settingsSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 10) { content() }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color.black.opacity(0.04), in: .rect(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 4)
    }

    func settingsLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary).frame(width: 62, alignment: .leading)
    }

    func pillButton(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: 12, weight: .semibold, design: .rounded))
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(isSelected ? Color.black.opacity(0.1) : Color.clear, in: .capsule)
        }
        .foregroundStyle(isSelected ? .primary : .secondary)
    }
}

#Preview {
    ScrollView {
        StackedAreaChartCard(
            title: "Stacked Area Chart",
            categories: ["Line Chart"],
            series: [
                MultiLineSeries(name: "Design", color: AnalyticsCard.colorPalette[0], values: [30, 45, 25, 55, 40, 60, 50]),
                MultiLineSeries(name: "Dev",    color: AnalyticsCard.colorPalette[1], values: [20, 30, 45, 35, 55, 40, 60]),
                MultiLineSeries(name: "QA",     color: AnalyticsCard.colorPalette[2], values: [10, 15, 20, 25, 15, 30, 20]),
            ],
            labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul"]
        )
        .padding(.top, 20)
    }
}
