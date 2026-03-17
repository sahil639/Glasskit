//
//  LineChartExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Line Chart Card

struct LineChartCard: View {

    let title: String
    let categories: [String]
    @State private var items: [AnalyticsDataItem]
    @State private var isExpanded = false
    @State private var editingID: UUID? = nil
    @State private var editingText = ""
    @State private var highlightedIdx: Int? = nil

    // Chart Geometry
    @State private var lineThickness: Double = 2.5
    @State private var pointSize: Double = 10
    @State private var curveType: CurveType = .smooth
    @State private var chartPadding: Double = 12

    // Axis Controls
    @State private var showXAxis: Bool = true
    @State private var showYAxis: Bool = true
    @State private var axisLabels: Bool = true
    @State private var axisGrid: Bool = true
    @State private var gridOpacity: Double = 0.25

    // Value Scaling
    @State private var autoScale: Bool = true
    @State private var yAxisMin: Double = 0
    @State private var yAxisMax: Double = 100
    @State private var valueFormat: ValueFormat = .number

    // Line Styling
    @State private var lineDashed: Bool = false
    @State private var gradientFill: Bool = false
    @State private var shadowEnabled: Bool = true
    @State private var lineOpacity: Double = 1.0

    // Point Styling
    @State private var showPoints: Bool = true
    @State private var pointShape: PointShape = .circle
    @State private var pointStroke: Bool = true
    @State private var pointFill: Bool = true

    // Area Fill
    @State private var areaFill: Bool = true
    @State private var areaOpacity: Double = 0.25

    // Labels
    @State private var valueLabelOn: Bool = false
    @State private var labelPosition: LabelPosition = .above
    @State private var xAxisLabelOn: Bool = true

    // Interaction
    @State private var hoverHighlight: Bool = true
    @State private var crosshair: Bool = false

    // Smoothing
    @State private var smoothing: Double = 0.4

    // Sorting
    @State private var sortOrder: SortOrder = .none

    #if os(iOS)
    @State private var pickerCoordinator: ColorPickerCoordinator? = nil
    #endif

    // MARK: - Enums

    enum CurveType: String, CaseIterable { case straight = "Straight", smooth = "Smooth" }
    enum ValueFormat: String, CaseIterable { case number = "Number", percent = "Percent", currency = "Currency", time = "Time" }
    enum PointShape: String, CaseIterable { case circle = "Circle", square = "Square" }
    enum LabelPosition: String, CaseIterable { case above = "Above", below = "Below", hidden = "Hidden" }
    enum SortOrder: String, CaseIterable { case none = "Default", ascending = "Asc", descending = "Desc" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Init

    init(title: String, categories: [String], items: [AnalyticsDataItem]) {
        self.title = title
        self.categories = categories
        self._items = State(initialValue: items)
    }

    // MARK: - Computed

    var sortedItems: [AnalyticsDataItem] {
        switch sortOrder {
        case .none: return items
        case .ascending: return items.sorted { $0.percentage < $1.percentage }
        case .descending: return items.sorted { $0.percentage > $1.percentage }
        }
    }

    var lineColor: Color { items.first?.color ?? Self.colorPalette[0] }

    var effectiveYMax: Double {
        autoScale ? (items.map { $0.percentage }.max() ?? 100) * 1.15 : yAxisMax
    }

    var effectiveYMin: Double {
        autoScale ? max(0, (items.map { $0.percentage }.min() ?? 0) * 0.85) : yAxisMin
    }

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

    // MARK: - Path Helpers

    func dataPoints(chartW: CGFloat, chartH: CGFloat, leftM: CGFloat, topM: CGFloat) -> [CGPoint] {
        let sorted = sortedItems
        let n = sorted.count
        guard n > 0 else { return [] }
        let xStep = n > 1 ? chartW / CGFloat(n - 1) : chartW / 2
        return sorted.enumerated().map { i, item in
            CGPoint(
                x: leftM + (n > 1 ? CGFloat(i) * xStep : chartW / 2),
                y: topM + chartH * (1 - yRatio(for: item.percentage))
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
        return path
    }

    func areaPath(points: [CGPoint], topM: CGFloat, chartH: CGFloat) -> Path {
        guard points.count >= 2 else { return Path() }
        let baselineY = topM + chartH
        var path = linePath(points: points)
        path.addLine(to: CGPoint(x: points.last!.x, y: baselineY))
        path.addLine(to: CGPoint(x: points.first!.x, y: baselineY))
        path.closeSubpath()
        return path
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            chartView
                .frame(height: 240)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .shadow(color: .black.opacity(shadowEnabled ? 0.15 : 0), radius: 20, x: 0, y: 10)
                .shadow(color: .black.opacity(shadowEnabled ? 0.10 : 0), radius: 3, x: 0, y: 2)

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
                    lineStyleSettingsView
                    pointStyleSettingsView
                    areaFillSettingsView
                    labelSettingsView
                    interactionSettingsView
                    if curveType == .smooth { smoothingSettingsView }
                    sortingSettingsView
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
        .onTapGesture {
            editingID = nil
            if hoverHighlight { highlightedIdx = nil }
        }
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            let sorted = sortedItems
            let leftM: CGFloat = (showYAxis && axisLabels) ? 36 : 6
            let rightM: CGFloat = CGFloat(chartPadding)
            let topM: CGFloat = (valueLabelOn && labelPosition == .above) ? 18 : 8
            let botM: CGFloat = (showXAxis && axisLabelOn()) ? 22 : (showXAxis ? 10 : 4)
            let chartW = geo.size.width - leftM - rightM
            let chartH = geo.size.height - topM - botM
            let pts = dataPoints(chartW: chartW, chartH: chartH, leftM: leftM, topM: topM)

            ZStack(alignment: .topLeading) {

                // Horizontal grid lines
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
                        Text(formattedValue(val))
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
                if showXAxis && axisLabelOn() && !sorted.isEmpty {
                    ForEach(Array(sorted.enumerated()), id: \.offset) { i, item in
                        let x = pts.count > i ? pts[i].x : 0
                        Text(item.label)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .center)
                            .position(x: x, y: topM + chartH + botM / 2)
                    }
                }

                if !pts.isEmpty {

                    // Area fill
                    if areaFill {
                        let area = areaPath(points: pts, topM: topM, chartH: chartH)
                        if gradientFill {
                            area.fill(LinearGradient(
                                colors: [lineColor.opacity(areaOpacity), lineColor.opacity(areaOpacity * 0.1)],
                                startPoint: .top, endPoint: .bottom
                            ))
                        } else {
                            area.fill(lineColor.opacity(areaOpacity))
                        }
                    }

                    // Line shadow
                    if shadowEnabled {
                        linePath(points: pts)
                            .stroke(lineColor.opacity(0.3), style: StrokeStyle(lineWidth: CGFloat(lineThickness) + 4, lineCap: .round, lineJoin: .round))
                            .blur(radius: 4)
                    }

                    // Line
                    linePath(points: pts)
                        .stroke(
                            gradientFill
                                ? AnyShapeStyle(LinearGradient(colors: [lineColor, lineColor.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(lineColor.opacity(lineOpacity)),
                            style: StrokeStyle(
                                lineWidth: CGFloat(lineThickness),
                                lineCap: .round,
                                lineJoin: .round,
                                dash: lineDashed ? [8, 5] : []
                            )
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: pts.map { $0.y })

                    // Points
                    if showPoints && pointSize > 0 {
                        ForEach(Array(pts.enumerated()), id: \.offset) { i, pt in
                            let item = i < sorted.count ? sorted[i] : sorted[0]
                            let isHighlighted = highlightedIdx == i
                            let isDimmed = hoverHighlight && highlightedIdx != nil && !isHighlighted
                            let pS = CGFloat(pointSize)
                            let pShape = pointShape == .circle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 3, style: .continuous))

                            ZStack {
                                if pointFill {
                                    pShape.fill(lineColor).glassEffect(.clear, in: pointShape == .circle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 3, style: .continuous)))
                                }
                                if pointStroke {
                                    pShape.stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                                    pShape.stroke(Color.white, lineWidth: 5)
                                        .blur(radius: 3).opacity(0.3)
                                        .clipShape(pointShape == .circle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 3, style: .continuous)))
                                }
                            }
                            .frame(width: pS, height: pS)
                            .position(x: pt.x, y: pt.y)
                            .scaleEffect(isHighlighted ? 1.4 : 1.0)
                            .opacity(isDimmed ? 0.3 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
                            .onTapGesture {
                                if hoverHighlight {
                                    withAnimation { highlightedIdx = (highlightedIdx == i) ? nil : i }
                                }
                            }

                            // Value label
                            if valueLabelOn && labelPosition != .hidden {
                                let labelY = labelPosition == .above ? pt.y - pS / 2 - 12 : pt.y + pS / 2 + 12
                                Text(formattedValue(item.percentage))
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .position(x: pt.x, y: labelY)
                            }

                            // Crosshair on highlighted point
                            if crosshair && isHighlighted {
                                Path { p in
                                    p.move(to: CGPoint(x: pt.x, y: topM))
                                    p.addLine(to: CGPoint(x: pt.x, y: topM + chartH))
                                }
                                .stroke(lineColor.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))

                                Path { p in
                                    p.move(to: CGPoint(x: leftM, y: pt.y))
                                    p.addLine(to: CGPoint(x: leftM + chartW, y: pt.y))
                                }
                                .stroke(lineColor.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            }
                        }
                    }
                }
            }
        }
    }

    func axisLabelOn() -> Bool { axisLabels && xAxisLabelOn }

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
            if !autoScale {
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
                settingsLabel("Gradient")
                Toggle("", isOn: $gradientFill).labelsHidden().scaleEffect(0.8)
                Text("Gradient line & area").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
                Text("Show data points").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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

    // MARK: - Settings: Area Fill

    var areaFillSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Area Fill")
                Toggle("", isOn: $areaFill).labelsHidden().scaleEffect(0.8)
                Text("Fill area under line").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if areaFill {
                HStack(spacing: 10) {
                    settingsLabel("Area Opc")
                    Slider(value: $areaOpacity, in: 0...1, step: 0.05)
                    Text("\(Int(areaOpacity * 100))%")
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
                settingsLabel("Values")
                Toggle("", isOn: $valueLabelOn).labelsHidden().scaleEffect(0.8)
                if valueLabelOn {
                    HStack(spacing: 4) {
                        ForEach(LabelPosition.allCases, id: \.self) { p in
                            pillButton(p.rawValue, isSelected: labelPosition == p) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { labelPosition = p }
                            }
                        }
                    }
                } else {
                    Text("Labels off").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                }
                Spacer()
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
                Text("Tap point to highlight").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Crosshair")
                Toggle("", isOn: $crosshair).labelsHidden().scaleEffect(0.8)
                Text("Crosshair on tap").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
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
            // Line color swatch (only first item drives line color; show all as reference)
            Button {
                #if os(iOS)
                let coord = ColorPickerCoordinator { color in items[index].color = color }
                pickerCoordinator = coord
                let vc = UIColorPickerViewController()
                vc.selectedColor = UIColor(items[index].color)
                vc.supportsAlpha = false
                vc.delegate = coord
                topViewController()?.present(vc, animated: true)
                #endif
            } label: {
                Circle()
                    .fill(items[index].color)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                    .opacity(index == 0 ? 1 : 0.4)
            }
            Text(item.label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
            Spacer()
            if editingID == item.id {
                TextField("0", text: $editingText)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    #if os(iOS)
                    .keyboardType(.numbersAndPunctuation)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .frame(width: 52)
                    .onChange(of: editingText) { _, val in
                        if let v = Double(val) { items[index].percentage = v }
                    }
            } else {
                Button {
                    editingID = item.id
                    editingText = "\(Int(item.percentage))"
                } label: {
                    Text("\(Int(item.percentage))")
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
                label: "\(items.count + 1)",
                percentage: Double.random(in: 30...90),
                color: items.first?.color ?? Self.colorPalette[0]
            ))
        }
    }
}

#Preview {
    ScrollView {
        LineChartCard(
            title: "Simple Line Chart",
            categories: ["Line Chart"],
            items: [
                AnalyticsDataItem(label: "Jan", percentage: 42, color: AnalyticsCard.colorPalette[0]),
                AnalyticsDataItem(label: "Feb", percentage: 68, color: AnalyticsCard.colorPalette[0]),
                AnalyticsDataItem(label: "Mar", percentage: 55, color: AnalyticsCard.colorPalette[0]),
                AnalyticsDataItem(label: "Apr", percentage: 82, color: AnalyticsCard.colorPalette[0]),
                AnalyticsDataItem(label: "May", percentage: 71, color: AnalyticsCard.colorPalette[0]),
                AnalyticsDataItem(label: "Jun", percentage: 93, color: AnalyticsCard.colorPalette[0]),
                AnalyticsDataItem(label: "Jul", percentage: 78, color: AnalyticsCard.colorPalette[0]),
            ]
        )
        .padding(.top, 20)
    }
}
