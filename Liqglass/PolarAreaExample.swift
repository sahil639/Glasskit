//
//  PolarAreaExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Polar Area Slice Shape

struct PolarAreaSliceShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var outerRadiusRatio: CGFloat   // fraction of container half-size
    var innerRadiusRatio: CGFloat   // fraction of container half-size
    var gap: Double = 1.5

    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, Double> {
        get { AnimatablePair(AnimatablePair(startAngle.degrees, endAngle.degrees), Double(outerRadiusRatio)) }
        set {
            startAngle = .degrees(newValue.first.first)
            endAngle = .degrees(newValue.first.second)
            outerRadiusRatio = CGFloat(newValue.second)
        }
    }

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let maxR = min(rect.width, rect.height) / 2
        let outerR = maxR * outerRadiusRatio
        let innerR = maxR * innerRadiusRatio
        let s = Angle(degrees: startAngle.degrees + gap)
        let e = Angle(degrees: endAngle.degrees - gap)
        guard e.degrees > s.degrees, outerR > 0 else { return Path() }
        var p = Path()
        if innerR > 0 {
            p.move(to: CGPoint(x: c.x + innerR * CGFloat(cos(s.radians)), y: c.y + innerR * CGFloat(sin(s.radians))))
            p.addArc(center: c, radius: innerR, startAngle: s, endAngle: e, clockwise: false)
            p.addLine(to: CGPoint(x: c.x + outerR * CGFloat(cos(e.radians)), y: c.y + outerR * CGFloat(sin(e.radians))))
            p.addArc(center: c, radius: outerR, startAngle: e, endAngle: s, clockwise: true)
        } else {
            p.move(to: c)
            p.addLine(to: CGPoint(x: c.x + outerR * CGFloat(cos(s.radians)), y: c.y + outerR * CGFloat(sin(s.radians))))
            p.addArc(center: c, radius: outerR, startAngle: s, endAngle: e, clockwise: false)
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Polar Area Arc Path (for rounded edges)

struct PolarAreaArcPath: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var outerRadiusRatio: CGFloat
    var innerRadiusRatio: CGFloat
    var gap: Double = 1.5

    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, Double> {
        get { AnimatablePair(AnimatablePair(startAngle.degrees, endAngle.degrees), Double(outerRadiusRatio)) }
        set {
            startAngle = .degrees(newValue.first.first)
            endAngle = .degrees(newValue.first.second)
            outerRadiusRatio = CGFloat(newValue.second)
        }
    }

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let maxR = min(rect.width, rect.height) / 2
        let outerR = maxR * outerRadiusRatio
        let innerR = maxR * max(innerRadiusRatio, 0)
        let midR = (outerR + innerR) / 2
        let s = Angle(degrees: startAngle.degrees + gap)
        let e = Angle(degrees: endAngle.degrees - gap)
        guard e.degrees > s.degrees, midR > 0 else { return Path() }
        var p = Path()
        p.addArc(center: c, radius: midR, startAngle: s, endAngle: e, clockwise: false)
        return p
    }
}

// MARK: - Polar Area Card

struct PolarAreaCard: View {

    let title: String
    let categories: [String]
    @State private var items: [AnalyticsDataItem]
    @State private var isExpanded = false
    @State private var editingID: UUID? = nil
    @State private var editingText = ""

    // Chart Geometry
    @State private var innerRatio: Double = 0.0
    @State private var maxRadiusScale: Double = 0.95
    @State private var chartStartAngle: Double = -90.0
    @State private var sliceGap: Double = 1.5

    // Value Scaling
    @State private var radiusScale: RadiusScale = .linear
    @State private var normalizeValues: Bool = true

    // Slice Controls
    @State private var sortOrder: SortOrder = .none
    @State private var roundedEdges: Bool = false
    @State private var minRadiusRatio: Double = 0.08

    // Labels
    @State private var labelPosition: LabelPosition = .hidden
    @State private var percentageStyle: PercentageStyle = .value
    @State private var showRadialGrid: Bool = false
    @State private var radialGridOpacity: Double = 0.35

    // Center Content
    @State private var centerContent: CenterContent = .none
    @State private var centerAlignment: CenterAlignment = .middle
    @State private var centerSize: Double = 36

    // Visual
    @State private var gradientFill: Bool = false
    @State private var shadowEnabled: Bool = true

    // Interaction
    @State private var hoverHighlight: Bool = false
    @State private var sliceExpand: Bool = false
    @State private var expandedSliceID: UUID? = nil

    #if os(iOS)
    @State private var pickerCoordinator: ColorPickerCoordinator? = nil
    #endif

    // MARK: - Enums

    enum RadiusScale: String, CaseIterable { case linear = "Linear", logarithmic = "Log", squareRoot = "√ Root" }
    enum SortOrder: String, CaseIterable { case none = "Default", ascending = "Asc", descending = "Desc" }
    enum LabelPosition: String, CaseIterable { case inside = "Inside", outside = "Outside", legend = "Legend", hidden = "Hidden" }
    enum PercentageStyle: String, CaseIterable { case value = "Value", percent = "Pct", both = "Both" }
    enum CenterContent: String, CaseIterable { case none = "None", value = "Value", label = "Label", icon = "Icon" }
    enum CenterAlignment: String, CaseIterable { case top = "Top", middle = "Mid", bottom = "Bot" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Slice Model

    struct PolarSlice: Identifiable {
        let id: UUID
        var startAngle: Angle
        var endAngle: Angle
        var outerRadiusRatio: CGFloat
        let color: Color
        let label: String
        let value: Double
    }

    // MARK: - Init

    init(title: String, categories: [String], items: [AnalyticsDataItem]) {
        self.title = title
        self.categories = categories
        self._items = State(initialValue: items)
    }

    // MARK: - Computed

    var polarSlices: [PolarSlice] {
        let sorted: [AnalyticsDataItem]
        switch sortOrder {
        case .none: sorted = items
        case .ascending: sorted = items.sorted { $0.percentage < $1.percentage }
        case .descending: sorted = items.sorted { $0.percentage > $1.percentage }
        }
        guard !sorted.isEmpty else { return [] }
        let sweepAngle = 360.0 / Double(sorted.count)
        let maxVal = normalizeValues ? (sorted.map { $0.percentage }.max() ?? 100) : 100
        return sorted.enumerated().map { (i, item) in
            let startDeg = chartStartAngle + Double(i) * sweepAngle
            let ratio = computeRadiusRatio(value: item.percentage, maxValue: maxVal)
            return PolarSlice(
                id: item.id,
                startAngle: .degrees(startDeg),
                endAngle: .degrees(startDeg + sweepAngle),
                outerRadiusRatio: CGFloat(ratio) * CGFloat(maxRadiusScale),
                color: item.color,
                label: item.label,
                value: item.percentage
            )
        }
    }

    func computeRadiusRatio(value: Double, maxValue: Double) -> Double {
        guard maxValue > 0 else { return minRadiusRatio }
        let raw: Double
        switch radiusScale {
        case .linear: raw = value / maxValue
        case .logarithmic: raw = log(max(value, 0.001) + 1) / log(maxValue + 1)
        case .squareRoot: raw = sqrt(max(value, 0)) / sqrt(maxValue)
        }
        return max(minRadiusRatio, raw)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            chartView
                .frame(height: 240)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .shadow(color: .black.opacity(shadowEnabled ? 0.18 : 0), radius: 24, x: 0, y: 12)
                .shadow(color: .black.opacity(shadowEnabled ? 0.18 : 0), radius: 3, x: 0, y: 2)

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
                    scalingSettingsView
                    sliceSettingsView
                    labelSettingsView
                    centerSettingsView
                    visualSettingsView
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
        .onTapGesture { editingID = nil }
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let maxChartR = size / 2
            let innerR = CGFloat(innerRatio)
            let slices = polarSlices

            ZStack {
                if showRadialGrid {
                    ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { frac in
                        Circle()
                            .stroke(Color.primary.opacity(radialGridOpacity * frac), lineWidth: 0.5)
                            .frame(
                                width: maxChartR * 2 * CGFloat(frac) * CGFloat(maxRadiusScale),
                                height: maxChartR * 2 * CGFloat(frac) * CGFloat(maxRadiusScale)
                            )
                    }
                }
                ForEach(slices) { slice in
                    let strokeW = max(2, maxChartR * (slice.outerRadiusRatio - innerR))
                    sliceContent(slice: slice, maxChartR: maxChartR, innerR: innerR, strokeW: strokeW, chartSize: size)
                }
                if centerContent != .none {
                    centerOverlay(size: size, maxChartR: maxChartR, innerR: innerR)
                }
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: slices.map { $0.startAngle.degrees })
        }
    }

    @ViewBuilder
    func sliceContent(slice: PolarSlice, maxChartR: CGFloat, innerR: CGFloat, strokeW: CGFloat, chartSize: CGFloat) -> some View {
        let isSelected = expandedSliceID == slice.id
        let sliceShape = PolarAreaSliceShape(
            startAngle: slice.startAngle,
            endAngle: slice.endAngle,
            outerRadiusRatio: slice.outerRadiusRatio,
            innerRadiusRatio: innerR,
            gap: sliceGap
        )
        ZStack {
            sliceFill(slice: slice, sliceShape: sliceShape, innerR: innerR, strokeW: strokeW)
                .overlay(sliceShape.stroke(Color.white.opacity(0.25), lineWidth: 0.4))
                .overlay(
                    sliceShape.stroke(Color.white, lineWidth: 8)
                        .blur(radius: 4).opacity(0.25).clipShape(sliceShape)
                )
                .scaleEffect(isSelected && sliceExpand ? 1.04 : 1.0)
                .opacity(hoverHighlight && expandedSliceID != nil && !isSelected ? 0.55 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: expandedSliceID)
                .onTapGesture {
                    if sliceExpand {
                        withAnimation { expandedSliceID = (expandedSliceID == slice.id) ? nil : slice.id }
                    }
                }
            if labelPosition == .inside {
                let mid = (slice.startAngle.degrees + slice.endAngle.degrees) / 2
                let midRadiusRatio = (slice.outerRadiusRatio + innerR) / 2
                let midR = maxChartR * midRadiusRatio
                Text(labelText(for: slice))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .position(
                        x: chartSize / 2 + midR * CGFloat(cos(Angle(degrees: mid).radians)),
                        y: chartSize / 2 + midR * CGFloat(sin(Angle(degrees: mid).radians))
                    )
            }
        }
    }

    @ViewBuilder
    func sliceFill(slice: PolarSlice, sliceShape: PolarAreaSliceShape, innerR: CGFloat, strokeW: CGFloat) -> some View {
        let grad = LinearGradient(colors: [slice.color.opacity(0.9), slice.color.opacity(0.5)], startPoint: .top, endPoint: .bottom)
        if roundedEdges {
            let arcPath = PolarAreaArcPath(
                startAngle: slice.startAngle,
                endAngle: slice.endAngle,
                outerRadiusRatio: slice.outerRadiusRatio,
                innerRadiusRatio: innerR,
                gap: sliceGap
            )
            if gradientFill {
                arcPath.stroke(grad, style: StrokeStyle(lineWidth: strokeW, lineCap: .round))
                    .glassEffect(.clear, in: sliceShape)
            } else {
                arcPath.stroke(slice.color.opacity(0.75), style: StrokeStyle(lineWidth: strokeW, lineCap: .round))
                    .glassEffect(.clear, in: sliceShape)
            }
        } else {
            if gradientFill {
                sliceShape.fill(grad).glassEffect(.clear, in: sliceShape)
            } else {
                sliceShape.fill(slice.color.opacity(0.75)).glassEffect(.clear, in: sliceShape)
            }
        }
    }

    func labelText(for slice: PolarSlice) -> String {
        switch percentageStyle {
        case .value: return "\(Int(slice.value))"
        case .percent:
            let total = items.reduce(0.0) { $0 + $1.percentage }
            return total > 0 ? "\(Int(slice.value / total * 100))%" : "0%"
        case .both: return "\(slice.label) \(Int(slice.value))"
        }
    }

    @ViewBuilder
    func centerOverlay(size: CGFloat, maxChartR: CGFloat, innerR: CGFloat) -> some View {
        let actualInnerR = maxChartR * innerR
        let cy: CGFloat = {
            switch centerAlignment {
            case .top: return size / 2 - actualInnerR * 0.4
            case .middle: return size / 2
            case .bottom: return size / 2 + actualInnerR * 0.4
            }
        }()
        switch centerContent {
        case .none:
            EmptyView()
        case .value:
            Text("\(Int(items.max(by: { $0.percentage < $1.percentage })?.percentage ?? 0))")
                .font(.system(size: CGFloat(centerSize), weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .position(x: size / 2, y: cy)
        case .label:
            Text(items.max(by: { $0.percentage < $1.percentage })?.label ?? "")
                .font(.system(size: CGFloat(centerSize) * 0.45, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .frame(width: max(actualInnerR * 1.4, 60))
                .position(x: size / 2, y: cy)
        case .icon:
            Image(systemName: "chart.bar.fill")
                .font(.system(size: CGFloat(centerSize)))
                .foregroundStyle(.secondary)
                .position(x: size / 2, y: cy)
        }
    }

    // MARK: - Settings: Geometry

    var geometrySettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Inner R")
                Slider(value: $innerRatio, in: 0...0.4, step: 0.05)
                Text("\(Int(innerRatio * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Max R")
                Slider(value: $maxRadiusScale, in: 0.5...1.0, step: 0.05)
                Text("\(Int(maxRadiusScale * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Start")
                Slider(value: $chartStartAngle, in: -180...180, step: 15)
                Text("\(Int(chartStartAngle))°")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Spacing")
                Slider(value: $sliceGap, in: 0...10, step: 0.5)
                Text(String(format: "%.1f°", sliceGap))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Scaling

    var scalingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Scale")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(RadiusScale.allCases, id: \.self) { s in
                            pillButton(s.rawValue, isSelected: radiusScale == s) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { radiusScale = s }
                            }
                        }
                    }
                }
            }
            HStack(spacing: 10) {
                settingsLabel("Normalize")
                Toggle("", isOn: $normalizeValues).labelsHidden().scaleEffect(0.8)
                Text("Scale relative to max").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Slice

    var sliceSettingsView: some View {
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
            HStack(spacing: 10) {
                settingsLabel("Edges")
                HStack(spacing: 4) {
                    pillButton("Sharp", isSelected: !roundedEdges) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { roundedEdges = false }
                    }
                    pillButton("Rounded", isSelected: roundedEdges) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { roundedEdges = true }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Min R")
                Slider(value: $minRadiusRatio, in: 0...0.3, step: 0.01)
                Text("\(Int(minRadiusRatio * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Labels

    var labelSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Labels")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(LabelPosition.allCases, id: \.self) { p in
                            pillButton(p.rawValue, isSelected: labelPosition == p) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { labelPosition = p }
                            }
                        }
                    }
                }
            }
            if labelPosition != .hidden && labelPosition != .legend {
                HStack(spacing: 10) {
                    settingsLabel("Style")
                    HStack(spacing: 4) {
                        ForEach(PercentageStyle.allCases, id: \.self) { s in
                            pillButton(s.rawValue, isSelected: percentageStyle == s) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { percentageStyle = s }
                            }
                        }
                    }
                    Spacer()
                }
            }
            HStack(spacing: 10) {
                settingsLabel("Grid")
                Toggle("", isOn: $showRadialGrid).labelsHidden().scaleEffect(0.8)
                Text("Show radial grid").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if showRadialGrid {
                HStack(spacing: 10) {
                    settingsLabel("Opacity")
                    Slider(value: $radialGridOpacity, in: 0...1, step: 0.05)
                    Text("\(Int(radialGridOpacity * 100))%")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Settings: Center

    var centerSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Content")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(CenterContent.allCases, id: \.self) { c in
                            pillButton(c.rawValue, isSelected: centerContent == c) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { centerContent = c }
                            }
                        }
                    }
                }
            }
            if centerContent != .none {
                HStack(spacing: 10) {
                    settingsLabel("Align")
                    HStack(spacing: 4) {
                        ForEach(CenterAlignment.allCases, id: \.self) { a in
                            pillButton(a.rawValue, isSelected: centerAlignment == a) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { centerAlignment = a }
                            }
                        }
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    settingsLabel("Size")
                    Slider(value: $centerSize, in: 10...80, step: 2)
                    Text("\(Int(centerSize))pt")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Settings: Visual

    var visualSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Gradient")
                Toggle("", isOn: $gradientFill).labelsHidden().scaleEffect(0.8)
                Text("Gradient fill").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
                settingsLabel("Highlight")
                Toggle("", isOn: $hoverHighlight).labelsHidden().scaleEffect(0.8)
                Text("Dim others on tap").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Expand")
                Toggle("", isOn: $sliceExpand).labelsHidden().scaleEffect(0.8)
                Text("Tap slice to expand").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
            }
            Text(item.label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
            Spacer()
            if editingID == item.id {
                TextField("0", text: $editingText)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .frame(width: 48)
                    .onChange(of: editingText) { _, val in
                        if let v = Double(val) {
                            items[index].percentage = max(0, min(100, v))
                        }
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
        let colorIdx = items.count % Self.colorPalette.count
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            items.append(AnalyticsDataItem(
                label: "Item \(items.count + 1)",
                percentage: 50,
                color: Self.colorPalette[colorIdx]
            ))
        }
    }
}

#Preview {
    ScrollView {
        PolarAreaCard(
            title: "Polar Area Chart",
            categories: ["Polar Area"],
            items: [
                AnalyticsDataItem(label: "Design",  percentage: 80, color: AnalyticsCard.colorPalette[0]),
                AnalyticsDataItem(label: "Dev",     percentage: 60, color: AnalyticsCard.colorPalette[1]),
                AnalyticsDataItem(label: "QA",      percentage: 40, color: AnalyticsCard.colorPalette[2]),
                AnalyticsDataItem(label: "PM",      percentage: 55, color: AnalyticsCard.colorPalette[3]),
                AnalyticsDataItem(label: "DevOps",  percentage: 30, color: AnalyticsCard.colorPalette[4]),
            ]
        )
        .padding(.top, 20)
    }
}
