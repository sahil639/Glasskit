//
//  HistogramChartExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Data Model

struct HistogramValue: Identifiable {
    let id = UUID()
    var value: Double
}

// MARK: - Histogram Chart Card

struct HistogramChartCard: View {

    let title: String
    let categories: [String]
    @State private var rawValues: [HistogramValue]
    @State private var isExpanded = false
    @State private var editingID: UUID? = nil
    @State private var editingText = ""
    @State private var appeared = false
    @State private var highlightedBin: Int? = nil

    // Zoom & Pan
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragTranslation: CGSize = .zero

    // Chart Geometry
    @State private var barWidthScale: Double = 0.88
    @State private var barSpacing: Double = 2
    @State private var chartPadding: Double = 12

    // Bins & Distribution
    @State private var numBins: Double = 10
    @State private var binSizeText: String = ""
    @State private var autoBinning: Bool = true
    @State private var distributionMode: HistDistMode = .frequency

    // Axis Controls
    @State private var showXAxis: Bool = true
    @State private var showYAxis: Bool = true
    @State private var axisLabels: Bool = true
    @State private var axisGrid: Bool = true
    @State private var gridOpacity: Double = 0.20

    // Value Scaling
    @State private var autoScale: Bool = true
    @State private var xMinText = "0";  @State private var xMaxText = "100"
    @State private var yMinText = "0";  @State private var yMaxText = "20"
    @State private var xMinManual: Double = 0; @State private var xMaxManual: Double = 100
    @State private var yMinManual: Double = 0; @State private var yMaxManual: Double = 20
    @State private var valueFormat: HistValueFormat = .number

    // Bar Styling
    @State private var cornerRadius: Double = 6
    @State private var gradientFill: Bool = true
    @State private var shadowEnabled: Bool = true
    @State private var barOpacity: Double = 0.85

    // Distribution Overlay
    @State private var showDensityCurve: Bool = false
    @State private var densityCurveSmooth: Bool = true
    @State private var curveThickness: Double = 2.0

    // Outliers
    @State private var outlierHighlight: Bool = false
    @State private var outlierThresholdText: String = "1.5"
    @State private var outlierIQR: Double = 1.5

    // Labels
    @State private var showValueLabel: Bool = false
    @State private var valueLabelPos: HistLabelPos = .top
    @State private var showBinRangeLabel: Bool = false

    // Interaction
    @State private var hoverHighlight: Bool = true
    @State private var hoverTooltip: Bool = true
    @State private var zoomPanEnabled: Bool = false
    @State private var animateOnLoad: Bool = true
    @State private var animationDuration: Double = 0.7

    // Sorting
    @State private var sortMode: HistSort = .default_

    // Color
    @State private var primaryColor: Color = AnalyticsCard.colorPalette[0]

    #if os(iOS)
    @State private var pickerCoordinator: ColorPickerCoordinator? = nil
    #endif

    // MARK: - Enums

    enum HistDistMode: String, CaseIterable { case frequency = "Frequency", probability = "Prob", density = "Density" }
    enum HistValueFormat: String, CaseIterable { case number = "Number", percent = "Percent" }
    enum HistLabelPos: String, CaseIterable { case top = "Top", inside = "Inside", hidden = "Hidden" }
    enum HistSort: String, CaseIterable { case default_ = "Default", asc = "Asc", desc = "Desc" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Init

    init(title: String, categories: [String], rawValues: [HistogramValue]) {
        self.title = title
        self.categories = categories
        self._rawValues = State(initialValue: rawValues)
    }

    // MARK: - Computed: Data

    var values: [Double] { rawValues.map { $0.value } }

    var effectiveNumBins: Int {
        if autoBinning {
            let n = Swift.max(2, values.count)
            return Swift.max(5, Swift.min(50, Int(ceil(log2(Double(n)) + 1))))
        }
        return Swift.max(2, Int(numBins))
    }

    var dataMin: Double { values.min() ?? 0 }
    var dataMax: Double { values.max() ?? 100 }
    var dataRange: Double { Swift.max(dataMax - dataMin, 1e-9) }

    var effectiveXMin: Double { autoScale ? dataMin - dataRange * 0.04 : xMinManual }
    var effectiveXMax: Double { autoScale ? dataMax + dataRange * 0.04 : xMaxManual }

    // MARK: - Bin Struct

    struct HistBin {
        var index: Int
        var lower: Double
        var upper: Double
        var count: Int
        var yValue: Double   // frequency / probability / density
        var isOutlier: Bool
    }

    var outlierLower: Double {
        let s = values.sorted()
        guard s.count >= 4 else { return -Double.infinity }
        let q1 = s[s.count / 4], q3 = s[3 * s.count / 4]
        return q1 - outlierIQR * (q3 - q1)
    }
    var outlierUpper: Double {
        let s = values.sorted()
        guard s.count >= 4 else { return Double.infinity }
        let q1 = s[s.count / 4], q3 = s[3 * s.count / 4]
        return q3 + outlierIQR * (q3 - q1)
    }

    var unsortedBins: [HistBin] {
        guard !values.isEmpty else { return [] }
        let n = effectiveNumBins
        let bw = dataRange / Double(n)
        let total = Double(values.count)
        return (0..<n).map { i in
            let lo = dataMin + Double(i) * bw
            let hi = lo + bw
            let inBin: (Double) -> Bool = { v in
                i == n - 1 ? v >= lo && v <= hi : v >= lo && v < hi
            }
            let cnt = values.filter(inBin).count
            let yV: Double
            switch distributionMode {
            case .frequency:   yV = Double(cnt)
            case .probability: yV = total > 0 ? Double(cnt) / total : 0
            case .density:     yV = total > 0 && bw > 0 ? Double(cnt) / (total * bw) : 0
            }
            let hasOut = outlierHighlight && values.filter { v in
                inBin(v) && (v < outlierLower || v > outlierUpper)
            }.count > 0
            return HistBin(index: i, lower: lo, upper: hi, count: cnt, yValue: yV, isOutlier: hasOut)
        }
    }

    var computedBins: [HistBin] {
        switch sortMode {
        case .default_: return unsortedBins
        case .asc:      return unsortedBins.sorted { $0.yValue < $1.yValue }
        case .desc:     return unsortedBins.sorted { $0.yValue > $1.yValue }
        }
    }

    var maxBinY: Double { computedBins.map { $0.yValue }.max() ?? 1 }
    var effectiveYMax: Double { autoScale ? maxBinY * 1.15 : yMaxManual }
    var effectiveYMin: Double { autoScale ? 0 : yMinManual }

    func yRatio(for v: Double) -> CGFloat {
        let range = effectiveYMax - effectiveYMin
        guard range > 0 else { return 0 }
        return CGFloat(max(0, min(1, (v - effectiveYMin) / range)))
    }

    func formattedY(_ v: Double) -> String {
        switch distributionMode {
        case .frequency:   return v == Double(Int(v)) ? "\(Int(v))" : String(format: "%.1f", v)
        case .probability: return String(format: "%.2f", v)
        case .density:     return String(format: "%.3f", v)
        }
    }

    func formattedX(_ v: Double) -> String {
        v == Double(Int(v)) ? "\(Int(v))" : String(format: "%.1f", v)
    }

    // MARK: - KDE

    func kde(at x: Double) -> Double {
        guard values.count >= 2 else { return 0 }
        let n = Double(values.count)
        let std = values.standardDeviation()
        let h = max(1e-9, 1.06 * std * pow(n, -0.2))
        return values.reduce(0.0) { acc, xi in
            let u = (x - xi) / h
            return acc + exp(-0.5 * u * u) / sqrt(2 * .pi)
        } / (n * h)
    }

    func scaledKDE(at x: Double) -> Double {
        let rawKDE = kde(at: x)
        let bw = dataRange / Double(effectiveNumBins)
        switch distributionMode {
        case .frequency:   return rawKDE * Double(values.count) * bw
        case .probability: return rawKDE * bw
        case .density:     return rawKDE
        }
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
                    geometrySettingsView
                    binSettingsView
                    axisSettingsView
                    scalingSettingsView
                    barStyleSettingsView
                    densityCurveSettingsView
                    outlierSettingsView
                    labelSettingsView
                    interactionSettingsView
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
        .onTapGesture { editingID = nil; highlightedBin = nil }
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            let leftM:  CGFloat = (showYAxis && axisLabels) ? 44 : 8
            let rightM: CGFloat = CGFloat(chartPadding)
            let topM:   CGFloat = showValueLabel && valueLabelPos == .top ? 24 : 10
            let botM:   CGFloat = (showXAxis && axisLabels) ? 26 : (showXAxis ? 10 : 8)
            let chartW = geo.size.width  - leftM - rightM
            let chartH = geo.size.height - topM  - botM

            let bins = computedBins
            let n = bins.count
            let slotW = n > 0 ? chartW / CGFloat(n) : chartW
            let barW = max(2, slotW * CGFloat(barWidthScale) - CGFloat(barSpacing))
            let barOffset = (slotW - barW) / 2

            ZStack(alignment: .topLeading) {

                // Horizontal grid lines
                if axisGrid {
                    ForEach(0...4, id: \.self) { i in
                        let yPos = topM + chartH * CGFloat(i) / 4
                        Path { p in
                            p.move(to: CGPoint(x: leftM, y: yPos))
                            p.addLine(to: CGPoint(x: leftM + chartW, y: yPos))
                        }
                        .stroke(Color.primary.opacity(gridOpacity),
                                style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    }
                }

                // Y axis labels
                if showYAxis && axisLabels {
                    ForEach(0...4, id: \.self) { i in
                        let frac = CGFloat(i) / 4
                        let val = effectiveYMin + (effectiveYMax - effectiveYMin) * Double(1 - frac)
                        Text(formattedY(val))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 38, alignment: .trailing)
                            .position(x: leftM - 6, y: topM + chartH * frac)
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

                // X axis labels (bin ranges or bin centers)
                if showXAxis && axisLabels && sortMode == .default_ {
                    let step = max(1, n / 5)
                    ForEach(Array(stride(from: 0, through: n, by: step)), id: \.self) { i in
                        let v = dataMin + Double(i) * (dataRange / Double(n))
                        let xPos = leftM + CGFloat(i) / CGFloat(n) * chartW
                        Text(formattedX(v))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .center)
                            .position(x: xPos, y: topM + chartH + botM / 2)
                    }
                }

                // Density curve overlay
                if showDensityCurve && !values.isEmpty {
                    densityCurvePath(chartW: chartW, chartH: chartH, leftM: leftM, topM: topM)
                }

                // Bars
                ForEach(Array(bins.enumerated()), id: \.element.index) { i, bin in
                    let barH = chartH * yRatio(for: bin.yValue)
                    let barX = leftM + CGFloat(i) * slotW + barOffset
                    let barY = topM + chartH - barH
                    let isHL = highlightedBin == i
                    let col: Color = bin.isOutlier ? .orange : primaryColor
                    let r = CGFloat(cornerRadius)
                    let shape = RoundedRectangle(cornerRadius: r, style: .continuous)

                    ZStack(alignment: .bottom) {
                        // Shadow
                        if shadowEnabled {
                            shape
                                .fill(col.opacity(0.15))
                                .blur(radius: 4)
                                .offset(y: 3)
                        }
                        // Bar fill
                        if gradientFill {
                            shape.fill(
                                LinearGradient(
                                    colors: [col.opacity(barOpacity), col.opacity(barOpacity * 0.55)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .glassEffect(.clear, in: shape)
                        } else {
                            shape.fill(col.opacity(barOpacity))
                                .glassEffect(.clear, in: shape)
                        }
                        // Stroke
                        shape.stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                        shape.stroke(Color.white, lineWidth: 4)
                            .blur(radius: 2.5).opacity(isHL ? 0.45 : 0.25).clipShape(shape)
                    }
                    .frame(width: barW, height: max(2, barH))
                    .scaleEffect(y: appeared ? 1.0 : 0.01, anchor: .bottom)
                    .opacity(appeared ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.72)
                            .delay(animateOnLoad ? Double(i) * 0.03 : 0),
                        value: appeared
                    )
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHL)
                    .position(x: barX + barW / 2, y: barY + barH / 2)
                    .onTapGesture {
                        guard hoverHighlight else { return }
                        withAnimation(.spring(response: 0.3)) {
                            highlightedBin = highlightedBin == i ? nil : i
                        }
                    }

                    // Value label
                    if showValueLabel && valueLabelPos != .hidden && bin.count > 0 {
                        let lY: CGFloat = valueLabelPos == .top
                            ? barY - 10
                            : barY + min(barH / 2, 14)
                        Text(formattedY(bin.yValue))
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(valueLabelPos == .inside ? Color.white.opacity(0.85) : Color.primary.opacity(0.7))
                            .position(x: barX + barW / 2, y: lY)
                            .opacity(appeared ? 1 : 0)
                    }

                    // Bin range label
                    if showBinRangeLabel && sortMode == .default_ {
                        Text("\(formattedX(bin.lower))–\(formattedX(bin.upper))")
                            .font(.system(size: 7, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary.opacity(0.7))
                            .rotationEffect(.degrees(-45))
                            .frame(width: slotW)
                            .position(x: barX + barW / 2, y: topM + chartH + 14)
                    }

                    // Hit-area for tapping (full height)
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: slotW, height: chartH)
                        .position(x: leftM + CGFloat(i) * slotW + slotW / 2, y: topM + chartH / 2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard hoverHighlight else { return }
                            withAnimation(.spring(response: 0.3)) {
                                highlightedBin = highlightedBin == i ? nil : i
                            }
                        }
                }

                // Tooltip
                if hoverTooltip, let hi = highlightedBin, hi < bins.count {
                    let bin = bins[hi]
                    let barX = leftM + CGFloat(hi) * slotW + slotW / 2
                    histTooltip(bin: bin, x: barX, y: topM, chartW: chartW, leftM: leftM)
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

    // MARK: - Density Curve

    @ViewBuilder
    func densityCurvePath(chartW: CGFloat, chartH: CGFloat, leftM: CGFloat, topM: CGFloat) -> some View {
        let steps = 80
        let xRange = effectiveXMax - effectiveXMin
        let kdePts: [CGPoint] = (0...steps).map { i in
            let xV = effectiveXMin + xRange * Double(i) / Double(steps)
            let yV = scaledKDE(at: xV)
            return CGPoint(
                x: leftM + CGFloat((xV - effectiveXMin) / xRange) * chartW,
                y: topM + chartH * (1 - yRatio(for: yV))
            )
        }

        if densityCurveSmooth {
            // Catmull-Rom smooth curve
            Path { path in
                guard kdePts.count > 1 else { return }
                path.move(to: kdePts[0])
                for i in 1..<kdePts.count {
                    let prev2 = kdePts[max(0, i - 2)]
                    let prev  = kdePts[i - 1]
                    let curr  = kdePts[i]
                    let next  = kdePts[min(kdePts.count - 1, i + 1)]
                    let cp1 = CGPoint(x: prev.x + (curr.x - prev2.x) / 6,
                                      y: prev.y + (curr.y - prev2.y) / 6)
                    let cp2 = CGPoint(x: curr.x - (next.x - prev.x) / 6,
                                      y: curr.y - (next.y - prev.y) / 6)
                    path.addCurve(to: curr, control1: cp1, control2: cp2)
                }
            }
            .trim(from: 0, to: appeared ? 1 : 0)
            .stroke(primaryColor.opacity(0.85), style: StrokeStyle(lineWidth: CGFloat(curveThickness), lineCap: .round))
        } else {
            // Step curve
            Path { path in
                guard kdePts.count > 0 else { return }
                path.move(to: kdePts[0])
                for i in 1..<kdePts.count {
                    path.addLine(to: CGPoint(x: kdePts[i].x, y: kdePts[i - 1].y))
                    path.addLine(to: kdePts[i])
                }
            }
            .trim(from: 0, to: appeared ? 1 : 0)
            .stroke(primaryColor.opacity(0.85), style: StrokeStyle(lineWidth: CGFloat(curveThickness), lineCap: .square))
        }
    }

    // MARK: - Tooltip

    @ViewBuilder
    func histTooltip(bin: HistBin, x: CGFloat, y: CGFloat, chartW: CGFloat, leftM: CGFloat) -> some View {
        let w: CGFloat = 108
        let clampedX = max(leftM + w / 2, min(x, leftM + chartW - w / 2))
        VStack(alignment: .leading, spacing: 3) {
            Text("Bin \(bin.index + 1)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            HStack(spacing: 4) {
                Text("Range:")
                    .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Text("\(formattedX(bin.lower)) – \(formattedX(bin.upper))")
                    .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            }
            HStack(spacing: 4) {
                Text("Count:")
                    .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Text("\(bin.count)")
                    .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            }
            HStack(spacing: 4) {
                Text("\(distributionMode.rawValue):")
                    .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Text(formattedY(bin.yValue))
                    .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(Color(uiColor: .systemBackground).opacity(0.92), in: .rect(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        .position(x: clampedX, y: y + 36)
    }

    // MARK: - Settings: Geometry

    var geometrySettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Bar Width")
                Slider(value: $barWidthScale, in: 0.2...1.0, step: 0.02)
                Text("\(Int(barWidthScale * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Spacing")
                Slider(value: $barSpacing, in: 0...10, step: 0.5)
                Text(String(format: "%.1fpt", barSpacing))
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

    // MARK: - Settings: Bins

    var binSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Auto Bin")
                Toggle("", isOn: $autoBinning).labelsHidden().scaleEffect(0.8)
                Text("Sturges' rule").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
                Text("\(effectiveNumBins) bins")
                    .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
            }
            if !autoBinning {
                HStack(spacing: 10) {
                    settingsLabel("Num Bins")
                    Slider(value: $numBins, in: 5...50, step: 1)
                    Text("\(Int(numBins))")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
            HStack(spacing: 10) {
                settingsLabel("Mode")
                HStack(spacing: 4) {
                    ForEach(HistDistMode.allCases, id: \.self) { m in
                        pillButton(m.rawValue, isSelected: distributionMode == m) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { distributionMode = m }
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
                Text("Auto scale to data").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Format")
                HStack(spacing: 4) {
                    ForEach(HistValueFormat.allCases, id: \.self) { f in
                        pillButton(f.rawValue, isSelected: valueFormat == f) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { valueFormat = f }
                        }
                    }
                }
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
                        .onChange(of: xMinText) { _, v in if let d = Double(v) { xMinManual = d } }
                }
                HStack(spacing: 10) {
                    settingsLabel("X Max")
                    TextField("100", text: $xMaxText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing).frame(maxWidth: .infinity)
                        .onChange(of: xMaxText) { _, v in if let d = Double(v) { xMaxManual = d } }
                }
                HStack(spacing: 10) {
                    settingsLabel("Y Min")
                    TextField("0", text: $yMinText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing).frame(maxWidth: .infinity)
                        .onChange(of: yMinText) { _, v in if let d = Double(v) { yMinManual = d } }
                }
                HStack(spacing: 10) {
                    settingsLabel("Y Max")
                    TextField("20", text: $yMaxText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing).frame(maxWidth: .infinity)
                        .onChange(of: yMaxText) { _, v in if let d = Double(v) { yMaxManual = d } }
                }
            }
        }
    }

    // MARK: - Settings: Bar Style

    var barStyleSettingsView: some View {
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
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white, lineWidth: 2))
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                }
                Text("Bar color").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Radius")
                Slider(value: $cornerRadius, in: 0...10, step: 0.5)
                Text(String(format: "%.1fpt", cornerRadius))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Opacity")
                Slider(value: $barOpacity, in: 0...1, step: 0.05)
                Text("\(Int(barOpacity * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Gradient")
                Toggle("", isOn: $gradientFill).labelsHidden().scaleEffect(0.8)
                Text("Gradient fill").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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

    // MARK: - Settings: Density Curve

    var densityCurveSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("KDE Curve")
                Toggle("", isOn: $showDensityCurve).labelsHidden().scaleEffect(0.8)
                Text("Density overlay").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if showDensityCurve {
                HStack(spacing: 10) {
                    settingsLabel("Curve")
                    HStack(spacing: 4) {
                        pillButton("Smooth", isSelected: densityCurveSmooth) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { densityCurveSmooth = true }
                        }
                        pillButton("Step", isSelected: !densityCurveSmooth) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { densityCurveSmooth = false }
                        }
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    settingsLabel("Thickness")
                    Slider(value: $curveThickness, in: 1...6, step: 0.5)
                    Text(String(format: "%.1fpt", curveThickness))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Settings: Outliers

    var outlierSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Outliers")
                Toggle("", isOn: $outlierHighlight).labelsHidden().scaleEffect(0.8)
                Text("Highlight outlier bins").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if outlierHighlight {
                HStack(spacing: 10) {
                    settingsLabel("IQR ×")
                    TextField("1.5", text: $outlierThresholdText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .multilineTextAlignment(.trailing).frame(maxWidth: .infinity)
                        .onChange(of: outlierThresholdText) { _, v in if let d = Double(v) { outlierIQR = d } }
                    Text("IQR")
                        .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Settings: Labels

    var labelSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Val Label")
                Toggle("", isOn: $showValueLabel).labelsHidden().scaleEffect(0.8)
                Text("Show bar values").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if showValueLabel {
                HStack(spacing: 10) {
                    settingsLabel("Position")
                    HStack(spacing: 4) {
                        ForEach(HistLabelPos.allCases, id: \.self) { p in
                            pillButton(p.rawValue, isSelected: valueLabelPos == p) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { valueLabelPos = p }
                            }
                        }
                    }
                    Spacer()
                }
            }
            HStack(spacing: 10) {
                settingsLabel("Bin Range")
                Toggle("", isOn: $showBinRangeLabel).labelsHidden().scaleEffect(0.8)
                Text("Show bin ranges").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
                Text("Tap to highlight").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Tooltip")
                Toggle("", isOn: $hoverTooltip).labelsHidden().scaleEffect(0.8)
                Text("Bin range & count").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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

    // MARK: - Settings: Sorting

    var sortingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Sort")
                HStack(spacing: 4) {
                    ForEach(HistSort.allCases, id: \.self) { s in
                        pillButton(s.rawValue, isSelected: sortMode == s) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { sortMode = s }
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
            // Stats summary
            HStack(spacing: 16) {
                statPill(label: "n", value: "\(values.count)")
                if let mn = values.min(), let mx = values.max() {
                    statPill(label: "min", value: formattedX(mn))
                    statPill(label: "max", value: formattedX(mx))
                    statPill(label: "μ", value: formattedX(values.reduce(0, +) / max(1, Double(values.count))))
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 10)
            Divider().padding(.horizontal, 20)

            ForEach(Array(rawValues.enumerated()), id: \.element.id) { index, hv in
                valueRow(index: index, hv: hv)
            }
            Divider().padding(.horizontal, 20)
            Button { addValue() } label: {
                Text("+ Add New Item")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
    }

    @ViewBuilder
    func statPill(label: String, value: String) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.primary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color.black.opacity(0.04), in: .capsule)
    }

    @ViewBuilder
    func valueRow(index: Int, hv: HistogramValue) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .trailing)

            if editingID == hv.id {
                TextField("Value", text: $editingText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    #if os(iOS)
                    .keyboardType(.numbersAndPunctuation)
                    #endif
                    .frame(maxWidth: .infinity)
                    .onChange(of: editingText) { _, val in
                        if let d = Double(val) { rawValues[index].value = d }
                    }
            } else {
                Button {
                    editingID = hv.id
                    editingText = formattedX(hv.value)
                } label: {
                    Text(formattedX(hv.value))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .underline(color: .primary.opacity(0.2))
                }
                .foregroundStyle(.primary)
            }

            Button {
                withAnimation(.spring(response: 0.3)) {
                    rawValues.removeSubrange(index...index)
                }
            } label: {
                Image(systemName: "minus.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        if index < rawValues.count - 1 { Divider().padding(.horizontal, 20) }
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

    func addValue() {
        let mean = values.reduce(0, +) / max(1, Double(values.count))
        let std = values.standardDeviation()
        let newVal = mean + Double.random(in: -std...std)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            rawValues.append(HistogramValue(value: max(dataMin, min(dataMax, newVal))))
        }
    }
}

// MARK: - Array Statistics Extension

private extension Array where Element == Double {
    func standardDeviation() -> Double {
        guard count > 1 else { return 1 }
        let mean = reduce(0, +) / Double(count)
        let variance = reduce(0.0) { $0 + ($1 - mean) * ($1 - mean) } / Double(count - 1)
        return sqrt(Swift.max(variance, 1e-9))
    }
}

#Preview {
    ScrollView {
        HistogramChartCard(
            title: "Histogram Chart",
            categories: ["Histogram", "Distribution"],
            rawValues: [
                18, 22, 25, 28, 30, 30, 32, 33, 35, 36,
                38, 39, 40, 40, 41, 42, 43, 44, 45, 46,
                47, 48, 48, 50, 51, 52, 54, 55, 58, 62
            ].map { HistogramValue(value: Double($0)) }
        )
        .padding(.top, 20)
    }
}
