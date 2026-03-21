//
//  DensityCurveChartExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Data Model

struct DensitySeries: Identifiable {
    let id = UUID()
    var name: String
    var values: [Double]
    var color: Color
}

// MARK: - Density Curve Chart Card

struct DensityCurveChartCard: View {

    let title: String
    let categories: [String]
    @State private var series: [DensitySeries]
    @State private var isExpanded = false
    @State private var appeared = false
    @State private var highlightedSeries: UUID? = nil
    @State private var editingSeriesID: UUID? = nil
    @State private var editingValueIndex: Int? = nil
    @State private var editingText = ""

    // Zoom & Pan
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragTranslation: CGSize = .zero

    // Kernel & Bandwidth
    @State private var kernelType: DensKernel = .gaussian
    @State private var bandwidthMode: DensBWMode = .auto_
    @State private var manualBandwidth: Double = 5.0
    @State private var bandwidthText: String = "5.0"

    // Overlays
    @State private var showHistogram: Bool = false
    @State private var histogramBins: Double = 10
    @State private var histogramOpacity: Double = 0.25
    @State private var showRugPlot: Bool = true
    @State private var showAreaFill: Bool = true
    @State private var areaFillOpacity: Double = 0.18

    // Axis
    @State private var showXAxis: Bool = true
    @State private var showYAxis: Bool = true
    @State private var axisLabels: Bool = true
    @State private var axisGrid: Bool = true
    @State private var gridOpacity: Double = 0.20

    // Scaling
    @State private var autoScale: Bool = true
    @State private var xMinText = "0";  @State private var xMaxText = "100"
    @State private var yMinText = "0";  @State private var yMaxText = "0.1"
    @State private var xMinManual: Double = 0; @State private var xMaxManual: Double = 100
    @State private var yMinManual: Double = 0; @State private var yMaxManual: Double = 0.1

    // Curve Styling
    @State private var curveThickness: Double = 2.5
    @State private var curveSmooth: Bool = true
    @State private var lineStyle: DensLineStyle = .solid
    @State private var chartPadding: Double = 12

    // Interaction
    @State private var hoverHighlight: Bool = true
    @State private var zoomPanEnabled: Bool = false
    @State private var animateOnLoad: Bool = true
    @State private var animationDuration: Double = 0.8
    @State private var showTooltip: Bool = true
    @State private var tooltipPoint: CGPoint? = nil
    @State private var tooltipSeries: UUID? = nil
    @State private var tooltipX: Double = 0

    // Enums
    enum DensKernel: String, CaseIterable { case gaussian = "Gaussian", epanechnikov = "Epanechnikov", uniform = "Uniform" }
    enum DensBWMode: String, CaseIterable { case auto_ = "Auto", manual = "Manual" }
    enum DensLineStyle: String, CaseIterable { case solid = "Solid", dashed = "Dashed", dotted = "Dotted" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Init

    init(title: String, categories: [String], series: [DensitySeries]) {
        self.title = title
        self.categories = categories
        self._series = State(initialValue: series)
    }

    // MARK: - Computed: Data

    var allValues: [Double] { series.flatMap { $0.values } }
    var dataMin: Double { allValues.min() ?? 0 }
    var dataMax: Double { allValues.max() ?? 100 }
    var dataRange: Double { Swift.max(dataMax - dataMin, 1e-9) }

    var effectiveXMin: Double { autoScale ? dataMin - dataRange * 0.12 : xMinManual }
    var effectiveXMax: Double { autoScale ? dataMax + dataRange * 0.12 : xMaxManual }
    var effectiveXRange: Double { Swift.max(effectiveXMax - effectiveXMin, 1e-9) }

    func bandwidth(for s: DensitySeries) -> Double {
        if bandwidthMode == .manual { return Swift.max(0.01, manualBandwidth) }
        guard s.values.count >= 2 else { return 1.0 }
        let n = Double(s.values.count)
        let std = s.values.densityStandardDeviation()
        return Swift.max(0.01, 1.06 * std * pow(n, -0.2))
    }

    func kde(at x: Double, for s: DensitySeries) -> Double {
        let vals = s.values
        guard vals.count >= 1 else { return 0 }
        let n = Double(vals.count)
        let h = bandwidth(for: s)
        return vals.reduce(0.0) { acc, xi in
            let u = (x - xi) / h
            let k: Double
            switch kernelType {
            case .gaussian:
                k = exp(-0.5 * u * u) / sqrt(2 * .pi)
            case .epanechnikov:
                k = abs(u) <= 1 ? 0.75 * (1 - u * u) : 0
            case .uniform:
                k = abs(u) <= 1 ? 0.5 : 0
            }
            return acc + k
        } / (n * h)
    }

    func kdeCurvePoints(for s: DensitySeries, steps: Int, chartW: CGFloat, chartH: CGFloat, leftM: CGFloat, topM: CGFloat, yMax: Double) -> [CGPoint] {
        guard !s.values.isEmpty else { return [] }
        let xRange = effectiveXRange
        return (0...steps).map { i in
            let xV = effectiveXMin + xRange * Double(i) / Double(steps)
            let yV = kde(at: xV, for: s)
            let yFrac = yMax > 0 ? min(1, max(0, yV / yMax)) : 0
            return CGPoint(
                x: leftM + CGFloat((xV - effectiveXMin) / xRange) * chartW,
                y: topM + chartH * CGFloat(1 - yFrac)
            )
        }
    }

    func computedYMax() -> Double {
        if !autoScale { return yMaxManual }
        var maxVal = 0.0
        let steps = 60
        for s in series {
            for i in 0...steps {
                let xV = effectiveXMin + effectiveXRange * Double(i) / Double(steps)
                maxVal = max(maxVal, kde(at: xV, for: s))
            }
        }
        return maxVal * 1.2
    }

    // MARK: - Histogram overlay bins

    struct OverlayBin { var lo: Double; var hi: Double; var count: Int }

    func histBins(for s: DensitySeries) -> [OverlayBin] {
        let n = max(2, Int(histogramBins))
        let bw = effectiveXRange / Double(n)
        guard bw > 0 else { return [] }
        let total = Double(max(1, s.values.count))
        return (0..<n).map { i in
            let lo = effectiveXMin + Double(i) * bw
            let hi = lo + bw
            let cnt = s.values.filter { i == n - 1 ? $0 >= lo && $0 <= hi : $0 >= lo && $0 < hi }.count
            return OverlayBin(lo: lo, hi: hi, count: cnt)
        }
    }

    func histMaxDensity() -> Double {
        let bw = effectiveXRange / Double(max(2, Int(histogramBins)))
        var mx = 0.0
        for s in series {
            let total = Double(max(1, s.values.count))
            let bins = histBins(for: s)
            for b in bins {
                let d = Double(b.count) / (total * bw)
                mx = max(mx, d)
            }
        }
        return mx
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
                    kernelSettingsView
                    bandwidthSettingsView
                    overlaySettingsView
                    axisSettingsView
                    scalingSettingsView
                    curveStyleSettingsView
                    interactionSettingsView
                    seriesListView
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
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            let leftM:  CGFloat = (showYAxis && axisLabels) ? 44 : 8
            let rightM: CGFloat = CGFloat(chartPadding)
            let topM:   CGFloat = 12
            let botM:   CGFloat = (showXAxis && axisLabels) ? 26 : (showXAxis ? 10 : 8)
            let rugH:   CGFloat = showRugPlot ? 12 : 0
            let chartW = geo.size.width  - leftM - rightM
            let chartH = geo.size.height - topM  - botM - rugH
            let yMax   = computedYMax()

            ZStack(alignment: .topLeading) {

                // Grid
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
                        let val = yMax * Double(1 - frac)
                        Text(String(format: val < 0.01 ? "%.4f" : "%.3f", val))
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

                // X axis labels
                if showXAxis && axisLabels {
                    ForEach(0...5, id: \.self) { i in
                        let val = effectiveXMin + effectiveXRange * Double(i) / 5
                        let xPos = leftM + chartW * CGFloat(i) / 5
                        Text(val == Double(Int(val)) ? "\(Int(val))" : String(format: "%.1f", val))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .center)
                            .position(x: xPos, y: topM + chartH + botM / 2)
                    }
                }

                // Histogram overlay
                if showHistogram {
                    let histY = histMaxDensity()
                    ForEach(series) { s in
                        let bins = histBins(for: s)
                        let total = Double(max(1, s.values.count))
                        let bw = effectiveXRange / Double(max(2, Int(histogramBins)))
                        ForEach(Array(bins.enumerated()), id: \.offset) { _, bin in
                            let density = Double(bin.count) / (total * bw)
                            let yFrac = histY > 0 ? min(1, density / histY) * (yMax > 0 ? histY / yMax : 1) : 0
                            let barH = chartH * CGFloat(yFrac)
                            let xFrac = (bin.lo - effectiveXMin) / effectiveXRange
                            let widthFrac = bw / effectiveXRange
                            let barX = leftM + chartW * CGFloat(xFrac)
                            let barW = chartW * CGFloat(widthFrac) - 1
                            if barH > 0 && barW > 0 {
                                Rectangle()
                                    .fill(s.color.opacity(histogramOpacity))
                                    .frame(width: barW, height: barH)
                                    .position(x: barX + barW / 2, y: topM + chartH - barH / 2)
                            }
                        }
                    }
                }

                // KDE curves — area fill
                if showAreaFill {
                    ForEach(series) { s in
                        let pts = kdeCurvePoints(for: s, steps: 80, chartW: chartW, chartH: chartH,
                                                 leftM: leftM, topM: topM, yMax: yMax)
                        let isHL = highlightedSeries == nil || highlightedSeries == s.id
                        if pts.count > 1 {
                            Path { path in
                                path.move(to: CGPoint(x: pts[0].x, y: topM + chartH))
                                path.addLine(to: pts[0])
                                for i in 1..<pts.count {
                                    if curveSmooth {
                                        let prev2 = pts[max(0, i - 2)]
                                        let prev  = pts[i - 1]
                                        let curr  = pts[i]
                                        let next  = pts[min(pts.count - 1, i + 1)]
                                        let cp1 = CGPoint(x: prev.x + (curr.x - prev2.x) / 6,
                                                          y: prev.y + (curr.y - prev2.y) / 6)
                                        let cp2 = CGPoint(x: curr.x - (next.x - prev.x) / 6,
                                                          y: curr.y - (next.y - prev.y) / 6)
                                        path.addCurve(to: curr, control1: cp1, control2: cp2)
                                    } else {
                                        path.addLine(to: pts[i])
                                    }
                                }
                                path.addLine(to: CGPoint(x: pts.last!.x, y: topM + chartH))
                                path.closeSubpath()
                            }
                            .fill(s.color.opacity(appeared ? areaFillOpacity : 0))
                            .opacity(isHL ? 1 : 0.3)
                            .animation(.easeOut(duration: animationDuration).delay(0.1), value: appeared)
                        }
                    }
                }

                // KDE curves — stroke
                ForEach(series) { s in
                    let pts = kdeCurvePoints(for: s, steps: 80, chartW: chartW, chartH: chartH,
                                             leftM: leftM, topM: topM, yMax: yMax)
                    let isHL = highlightedSeries == nil || highlightedSeries == s.id
                    if pts.count > 1 {
                        let dash: [CGFloat] = lineStyle == .dashed ? [8, 5] : (lineStyle == .dotted ? [2, 5] : [])
                        let strokeStyle = StrokeStyle(lineWidth: CGFloat(curveThickness), lineCap: .round, lineJoin: .round, dash: dash)
                        Path { path in
                            path.move(to: pts[0])
                            for i in 1..<pts.count {
                                if curveSmooth {
                                    let prev2 = pts[max(0, i - 2)]
                                    let prev  = pts[i - 1]
                                    let curr  = pts[i]
                                    let next  = pts[min(pts.count - 1, i + 1)]
                                    let cp1 = CGPoint(x: prev.x + (curr.x - prev2.x) / 6,
                                                      y: prev.y + (curr.y - prev2.y) / 6)
                                    let cp2 = CGPoint(x: curr.x - (next.x - prev.x) / 6,
                                                      y: curr.y - (next.y - prev.y) / 6)
                                    path.addCurve(to: curr, control1: cp1, control2: cp2)
                                } else {
                                    path.addLine(to: pts[i])
                                }
                            }
                        }
                        .trim(from: 0, to: appeared ? 1 : 0)
                        .stroke(s.color, style: strokeStyle)
                        .opacity(isHL ? 1 : 0.25)
                        .animation(.easeOut(duration: animationDuration), value: appeared)
                        .onTapGesture {
                            guard hoverHighlight else { return }
                            withAnimation(.spring(response: 0.3)) {
                                highlightedSeries = highlightedSeries == s.id ? nil : s.id
                            }
                        }
                    }
                }

                // Rug plot
                if showRugPlot {
                    ForEach(series) { s in
                        let isHL = highlightedSeries == nil || highlightedSeries == s.id
                        ForEach(Array(s.values.enumerated()), id: \.offset) { _, v in
                            let xFrac = (v - effectiveXMin) / effectiveXRange
                            let xPos = leftM + chartW * CGFloat(min(1, max(0, xFrac)))
                            let yBase = topM + chartH + 2
                            Path { p in
                                p.move(to: CGPoint(x: xPos, y: yBase))
                                p.addLine(to: CGPoint(x: xPos, y: yBase + rugH - 2))
                            }
                            .stroke(s.color.opacity(isHL ? 0.65 : 0.15), lineWidth: 1.5)
                        }
                    }
                }

                // Tooltip tap overlay
                if showTooltip {
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .frame(width: chartW, height: chartH)
                        .position(x: leftM + chartW / 2, y: topM + chartH / 2)
                        .onTapGesture { location in
                            tooltipPoint = nil
                            tooltipSeries = nil
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { v in
                                    guard !zoomPanEnabled, showTooltip else { return }
                                    let relX = v.location.x - leftM
                                    let xV = effectiveXMin + effectiveXRange * Double(relX / chartW)
                                    tooltipX = xV
                                    tooltipPoint = v.location
                                    tooltipSeries = series.first?.id
                                }
                                .onEnded { _ in }
                        )
                }

                // Tooltip
                if let tPoint = tooltipPoint, showTooltip, !series.isEmpty {
                    tooltipView(at: tPoint, xVal: tooltipX, chartW: chartW, chartH: chartH,
                                leftM: leftM, topM: topM, yMax: yMax)
                }

                // Legend
                legendView
                    .position(x: leftM + chartW - 60, y: topM + 18)
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

    // MARK: - Legend

    var legendView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ForEach(series) { s in
                HStack(spacing: 4) {
                    Text(s.name)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(s.color)
                        .frame(width: 18, height: 3)
                }
                .opacity(highlightedSeries == nil || highlightedSeries == s.id ? 1 : 0.3)
                .onTapGesture {
                    guard hoverHighlight else { return }
                    withAnimation(.spring(response: 0.3)) {
                        highlightedSeries = highlightedSeries == s.id ? nil : s.id
                    }
                }
            }
        }
    }

    // MARK: - Tooltip

    @ViewBuilder
    func tooltipView(at pt: CGPoint, xVal: Double, chartW: CGFloat, chartH: CGFloat, leftM: CGFloat, topM: CGFloat, yMax: Double) -> some View {
        let densities = series.map { s in (s, kde(at: xVal, for: s)) }
        let xPos = min(max(pt.x, leftM + 60), leftM + chartW - 10)
        let yPos = max(topM + 30, min(pt.y - 10, topM + chartH - 30))

        VStack(alignment: .leading, spacing: 3) {
            Text("x = \(String(format: "%.2f", xVal))")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            Divider()
            ForEach(densities, id: \.0.id) { s, d in
                HStack(spacing: 4) {
                    Circle().fill(s.color).frame(width: 6, height: 6)
                    Text(s.name)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.4f", d))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
        )
        .frame(width: 150)
        .position(x: xPos - 40, y: yPos)
    }

    // MARK: - Settings Views

    @ViewBuilder
    var kernelSettingsView: some View {
        settingsSection("Kernel Function") {
            HStack(spacing: 6) {
                ForEach(DensKernel.allCases, id: \.self) { k in
                    pillButton(k.rawValue, selected: kernelType == k) { kernelType = k }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    var bandwidthSettingsView: some View {
        settingsSection("Bandwidth") {
            HStack(spacing: 6) {
                ForEach(DensBWMode.allCases, id: \.self) { m in
                    pillButton(m.rawValue, selected: bandwidthMode == m) { bandwidthMode = m }
                }
            }
            .padding(.horizontal, 20)
            if bandwidthMode == .manual {
                HStack {
                    settingsLabel("Value")
                    Slider(value: $manualBandwidth, in: 0.1...50)
                    Text(String(format: "%.1f", manualBandwidth))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            } else {
                let bwInfo = series.map { "\($0.name): \(String(format: "%.2f", bandwidth(for: $0)))" }.joined(separator: " · ")
                Text(bwInfo.isEmpty ? "Auto (Scott's rule)" : "Auto · \(bwInfo)")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    var overlaySettingsView: some View {
        settingsSection("Overlays") {
            Toggle(isOn: $showAreaFill) { settingsLabel("Area Fill") }
                .padding(.horizontal, 20)
            if showAreaFill {
                HStack {
                    settingsLabel("Fill Opacity")
                    Slider(value: $areaFillOpacity, in: 0.02...0.5)
                    Text(String(format: "%.0f%%", areaFillOpacity * 100))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
            Toggle(isOn: $showHistogram) { settingsLabel("Histogram") }
                .padding(.horizontal, 20)
            if showHistogram {
                HStack {
                    settingsLabel("Bins")
                    Slider(value: $histogramBins, in: 3...40, step: 1)
                    Text("\(Int(histogramBins))")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .trailing)
                }
                HStack {
                    settingsLabel("Opacity")
                    Slider(value: $histogramOpacity, in: 0.05...0.6)
                    Text(String(format: "%.0f%%", histogramOpacity * 100))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
            Toggle(isOn: $showRugPlot) { settingsLabel("Rug Plot") }
                .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    var axisSettingsView: some View {
        settingsSection("Axis") {
            Toggle(isOn: $showXAxis) { settingsLabel("X Axis") }.padding(.horizontal, 20)
            Toggle(isOn: $showYAxis) { settingsLabel("Y Axis") }.padding(.horizontal, 20)
            Toggle(isOn: $axisLabels) { settingsLabel("Labels") }.padding(.horizontal, 20)
            Toggle(isOn: $axisGrid) { settingsLabel("Grid Lines") }.padding(.horizontal, 20)
            if axisGrid {
                HStack {
                    settingsLabel("Grid Opacity")
                    Slider(value: $gridOpacity, in: 0.05...0.5)
                    Text(String(format: "%.0f%%", gridOpacity * 100))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    @ViewBuilder
    var scalingSettingsView: some View {
        settingsSection("Scale") {
            Toggle(isOn: $autoScale) { settingsLabel("Auto Scale") }.padding(.horizontal, 20)
            if !autoScale {
                HStack {
                    settingsLabel("X Min")
                    TextField("0", text: $xMinText)
                        .textFieldStyle(.roundedBorder).frame(width: 70)
                        .onSubmit { xMinManual = Double(xMinText) ?? xMinManual }
                    settingsLabel("Max")
                    TextField("100", text: $xMaxText)
                        .textFieldStyle(.roundedBorder).frame(width: 70)
                        .onSubmit { xMaxManual = Double(xMaxText) ?? xMaxManual }
                }
                HStack {
                    settingsLabel("Y Max")
                    TextField("0.1", text: $yMaxText)
                        .textFieldStyle(.roundedBorder).frame(width: 70)
                        .onSubmit { yMaxManual = Double(yMaxText) ?? yMaxManual }
                }
            }
        }
    }

    @ViewBuilder
    var curveStyleSettingsView: some View {
        settingsSection("Curve Style") {
            HStack(spacing: 6) {
                ForEach(DensLineStyle.allCases, id: \.self) { s in
                    pillButton(s.rawValue, selected: lineStyle == s) { lineStyle = s }
                }
            }
            .padding(.horizontal, 20)
            Toggle(isOn: $curveSmooth) { settingsLabel("Smooth Curve") }.padding(.horizontal, 20)
            HStack {
                settingsLabel("Thickness")
                Slider(value: $curveThickness, in: 1...6)
                Text(String(format: "%.1f", curveThickness))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .trailing)
            }
        }
    }

    @ViewBuilder
    var interactionSettingsView: some View {
        settingsSection("Interaction") {
            Toggle(isOn: $hoverHighlight) { settingsLabel("Highlight on Tap") }.padding(.horizontal, 20)
            Toggle(isOn: $showTooltip) { settingsLabel("Tooltip") }.padding(.horizontal, 20)
            Toggle(isOn: $zoomPanEnabled) { settingsLabel("Zoom & Pan") }.padding(.horizontal, 20)
            Toggle(isOn: $animateOnLoad) { settingsLabel("Animate on Load") }.padding(.horizontal, 20)
            if animateOnLoad {
                HStack {
                    settingsLabel("Duration")
                    Slider(value: $animationDuration, in: 0.3...2.0)
                    Text(String(format: "%.1fs", animationDuration))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Series List

    var seriesListView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Series")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    let idx = series.count % DensityCurveChartCard.colorPalette.count
                    let newS = DensitySeries(name: "Series \(series.count + 1)",
                                             values: [Double.random(in: 20...80), Double.random(in: 20...80)],
                                             color: DensityCurveChartCard.colorPalette[idx])
                    withAnimation(.spring(response: 0.4)) { series.append(newS) }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(DensityCurveChartCard.colorPalette[series.count % DensityCurveChartCard.colorPalette.count])
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            ForEach(Array(series.enumerated()), id: \.element.id) { si, s in
                seriesRow(si: si, s: s)
                if si < series.count - 1 {
                    Divider().padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    func seriesRow(si: Int, s: DensitySeries) -> some View {
        VStack(spacing: 0) {
            // Series header
            HStack(spacing: 10) {
                Circle()
                    .fill(s.color)
                    .frame(width: 10, height: 10)
                    .glassEffect(.clear, in: .circle)

                if editingSeriesID == s.id && editingValueIndex == nil {
                    TextField("Name", text: Binding(
                        get: { s.name },
                        set: { series[si].name = $0 }
                    ))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .textFieldStyle(.plain)
                    .onSubmit { editingSeriesID = nil }
                } else {
                    Text(s.name)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .onTapGesture {
                            editingSeriesID = s.id
                            editingValueIndex = nil
                        }
                }

                Spacer()

                Text("\(s.values.count) pts")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)

                if series.count > 1 {
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            series.removeSubrange(si...si)
                        }
                    } label: {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(.red.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            // Values list
            VStack(spacing: 4) {
                ForEach(Array(s.values.enumerated()), id: \.offset) { vi, v in
                    HStack(spacing: 8) {
                        Text("\(vi + 1).")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.tertiary)
                            .frame(width: 20, alignment: .trailing)

                        if editingSeriesID == s.id && editingValueIndex == vi {
                            TextField("Value", text: $editingText)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .textFieldStyle(.plain)
                                .keyboardType(.decimalPad)
                                .onSubmit {
                                    if let d = Double(editingText) {
                                        series[si].values[vi] = d
                                    }
                                    editingSeriesID = nil; editingValueIndex = nil
                                }
                        } else {
                            Text(String(format: "%.2f", v))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.primary)
                                .onTapGesture {
                                    editingSeriesID = s.id
                                    editingValueIndex = vi
                                    editingText = String(format: "%.2f", v)
                                }
                        }

                        Spacer()

                        // Slider for value
                        Slider(value: Binding(
                            get: { s.values[vi] },
                            set: { series[si].values[vi] = $0 }
                        ), in: (dataMin - dataRange * 0.2)...(dataMax + dataRange * 0.2))
                        .frame(width: 100)

                        if s.values.count > 2 {
                            Button {
                                withAnimation { series[si].values.removeSubrange(vi...vi) }
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Add value row
                HStack(spacing: 8) {
                    Spacer()
                    Button {
                        let mid = (dataMin + dataMax) / 2 + Double.random(in: -dataRange * 0.3...dataRange * 0.3)
                        withAnimation { series[si].values.append(mid) }
                    } label: {
                        Label("Add value", systemImage: "plus.circle")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(s.color)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    func settingsSection<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            content()
        }
    }

    @ViewBuilder
    func settingsLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, design: .rounded))
            .foregroundStyle(.primary)
            .frame(minWidth: 80, alignment: .leading)
            .padding(.leading, 20)
    }

    @ViewBuilder
    func pillButton(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: selected ? .semibold : .regular, design: .rounded))
                .foregroundStyle(selected ? Color.primary : Color.secondary)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(
                    Capsule().fill(selected ? Color.primary.opacity(0.1) : Color.clear)
                )
                .overlay(Capsule().stroke(selected ? Color.primary.opacity(0.2) : Color.clear, lineWidth: 0.5))
        }
    }
}

// MARK: - Double Array Extension (local, avoids conflict with HistogramChartExample)
private extension Array where Element == Double {
    func densityStandardDeviation() -> Double {
        guard count >= 2 else { return 1 }
        let mean = reduce(0, +) / Double(count)
        let variance = map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(count - 1)
        return sqrt(Swift.max(0, variance))
    }
}

