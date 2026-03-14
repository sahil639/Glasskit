//
//  MultiRingDonutExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Data Models

struct RingDataItem: Identifiable {
    let id = UUID()
    var label: String
    var percentage: Double
    var color: Color
}

struct DonutRing: Identifiable {
    let id = UUID()
    var name: String
    var items: [RingDataItem]
}

// MARK: - Ring Slice Shape

struct RingSliceShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var outerRadius: CGFloat
    var innerRadius: CGFloat
    var gap: Double = 1.5

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set { startAngle = .degrees(newValue.first); endAngle = .degrees(newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let s = Angle(degrees: startAngle.degrees + gap)
        let e = Angle(degrees: endAngle.degrees - gap)
        guard e.degrees > s.degrees, outerRadius > innerRadius else { return Path() }
        var p = Path()
        p.move(to: CGPoint(x: c.x + innerRadius * CGFloat(cos(s.radians)), y: c.y + innerRadius * CGFloat(sin(s.radians))))
        p.addArc(center: c, radius: innerRadius, startAngle: s, endAngle: e, clockwise: false)
        p.addLine(to: CGPoint(x: c.x + outerRadius * CGFloat(cos(e.radians)), y: c.y + outerRadius * CGFloat(sin(e.radians))))
        p.addArc(center: c, radius: outerRadius, startAngle: e, endAngle: s, clockwise: true)
        p.closeSubpath()
        return p
    }
}

// MARK: - Ring Arc Path (rounded edges)

struct RingArcPath: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var outerRadius: CGFloat
    var innerRadius: CGFloat
    var gap: Double = 1.5

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set { startAngle = .degrees(newValue.first); endAngle = .degrees(newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let midR = (outerRadius + innerRadius) / 2
        let s = Angle(degrees: startAngle.degrees + gap)
        let e = Angle(degrees: endAngle.degrees - gap)
        guard e.degrees > s.degrees else { return Path() }
        var p = Path()
        p.addArc(center: c, radius: midR, startAngle: s, endAngle: e, clockwise: false)
        return p
    }
}

// MARK: - Multi Ring Donut Card

struct MultiRingDonutCard: View {

    let title: String
    let categories: [String]
    @State private var rings: [DonutRing]
    @State private var isExpanded = false
    @State private var editingRingID: UUID? = nil
    @State private var editingItemID: UUID? = nil
    @State private var editingText = ""

    // Ring Structure
    @State private var ringThickness: Double = 28
    @State private var ringSpacing: Double = 6
    @State private var innerRatio: Double = 0.25

    // Rotation & Layout
    @State private var chartStartAngle: Double = -90
    @State private var sliceGap: Double = 1.5
    @State private var sortOrder: SortOrder = .none
    @State private var roundedEdges = false

    // Ring Behaviour
    @State private var independentRings = true
    @State private var hoverHighlight = false
    @State private var ringHoverExpand = false
    @State private var highlightedRingID: UUID? = nil

    // Center Content
    @State private var centerContent: CenterContent = .none
    @State private var centerAlignment: CenterAlignment = .middle
    @State private var centerSize: Double = 36

    // Labels
    @State private var labelPosition: LabelPosition = .hidden
    @State private var percentageStyle: PercentageStyle = .percent
    @State private var showRingLabels = false

    // Visual
    @State private var gradientFill = false
    @State private var shadowEnabled = true
    @State private var showTrack = false

    #if os(iOS)
    @State private var pickerCoordinator: ColorPickerCoordinator? = nil
    #endif

    // MARK: - Enums

    enum SortOrder: String, CaseIterable { case none = "Default", ascending = "Asc", descending = "Desc" }
    enum CenterContent: String, CaseIterable { case none = "None", value = "Value", label = "Label", icon = "Icon" }
    enum CenterAlignment: String, CaseIterable { case top = "Top", middle = "Mid", bottom = "Bot" }
    enum LabelPosition: String, CaseIterable { case inside = "Inside", outside = "Outside", legend = "Legend", hidden = "Hidden" }
    enum PercentageStyle: String, CaseIterable { case value = "Value", percent = "Pct", both = "Both" }

    static let colorPalettes: [[Color]] = [
        [Color(red: 0.28, green: 0.16, blue: 0.72), Color(red: 0.62, green: 0.52, blue: 0.88), Color(red: 0.82, green: 0.78, blue: 0.94)],
        [Color(red: 0.38, green: 0.65, blue: 0.58), Color(red: 0.56, green: 0.82, blue: 0.72), Color(red: 0.82, green: 0.92, blue: 0.88)],
        [Color(red: 0.20, green: 0.40, blue: 0.80), Color(red: 0.40, green: 0.60, blue: 0.90), Color(red: 0.70, green: 0.80, blue: 0.95)],
        [Color(red: 0.80, green: 0.35, blue: 0.25), Color(red: 0.90, green: 0.60, blue: 0.40), Color(red: 0.95, green: 0.80, blue: 0.60)],
        [Color(red: 0.75, green: 0.25, blue: 0.55), Color(red: 0.88, green: 0.50, blue: 0.70), Color(red: 0.95, green: 0.75, blue: 0.85)],
    ]

    // MARK: - Slice Model

    struct RingSlice: Identifiable {
        let id: UUID
        var startAngle: Angle
        var endAngle: Angle
        let color: Color
        let label: String
        let percentage: Double
    }

    // MARK: - Init

    init(title: String, categories: [String], rings: [DonutRing]) {
        self.title = title
        self.categories = categories
        self._rings = State(initialValue: rings)
    }

    // MARK: - Helpers

    func ringRadii(index: Int, totalOuterR: CGFloat) -> (outerR: CGFloat, innerR: CGFloat) {
        let thickness = CGFloat(ringThickness)
        let spacing = CGFloat(ringSpacing)
        let minInnerR = totalOuterR * CGFloat(innerRatio)
        let outerR = max(totalOuterR - CGFloat(index) * (thickness + spacing), 0)
        let innerR = max(outerR - thickness, minInnerR)
        return (outerR, innerR)
    }

    func computeSlices(for ring: DonutRing) -> [RingSlice] {
        let sorted: [RingDataItem] = {
            switch sortOrder {
            case .none: return ring.items
            case .ascending: return ring.items.sorted { $0.percentage < $1.percentage }
            case .descending: return ring.items.sorted { $0.percentage > $1.percentage }
            }
        }()
        let total = sorted.reduce(0.0) { $0 + $1.percentage }
        guard total > 0 else { return [] }
        var cursor = chartStartAngle
        return sorted.map { item in
            let sweep = 360.0 * item.percentage / total
            let slice = RingSlice(id: item.id, startAngle: .degrees(cursor), endAngle: .degrees(cursor + sweep), color: item.color, label: item.label, percentage: item.percentage)
            cursor += sweep
            return slice
        }
    }

    func labelText(for slice: RingSlice) -> String {
        switch percentageStyle {
        case .value: return "\(Int(slice.percentage))"
        case .percent: return "\(Int(slice.percentage))%"
        case .both: return "\(slice.label) \(Int(slice.percentage))%"
        }
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
                    ringStructureView
                    rotationLayoutView
                    ringBehaviourView
                    centerSettingsView
                    labelSettingsView
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
        .onTapGesture { editingItemID = nil }
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let totalOuterR = size / 2
            ZStack {
                ForEach(Array(rings.enumerated()), id: \.element.id) { ringIdx, ring in
                    let radii = ringRadii(index: ringIdx, totalOuterR: totalOuterR)
                    let outerR = radii.outerR
                    let innerR = radii.innerR
                    let strokeW = outerR - innerR
                    let slices = computeSlices(for: ring)
                    let isHighlighted = highlightedRingID == ring.id

                    if showTrack && outerR > innerR {
                        RingSliceShape(
                            startAngle: .degrees(chartStartAngle),
                            endAngle: .degrees(chartStartAngle + 360),
                            outerRadius: outerR, innerRadius: innerR, gap: 0
                        )
                        .fill(Color.black.opacity(0.06))
                    }

                    ForEach(slices) { slice in
                        ringSliceContent(
                            slice: slice, outerR: outerR, innerR: innerR,
                            strokeW: strokeW, chartSize: size,
                            ring: ring, isHighlighted: isHighlighted
                        )
                    }

                    if showRingLabels && outerR > 0 {
                        let labelR = outerR + 10
                        Text(ring.name)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .position(
                                x: size / 2 + labelR * CGFloat(cos(Angle(degrees: chartStartAngle).radians)),
                                y: size / 2 + labelR * CGFloat(sin(Angle(degrees: chartStartAngle).radians))
                            )
                    }
                }

                if centerContent != .none {
                    centerOverlay(size: size, totalOuterR: totalOuterR)
                }
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: rings.map { $0.id })
        }
    }

    @ViewBuilder
    func ringSliceContent(slice: RingSlice, outerR: CGFloat, innerR: CGFloat, strokeW: CGFloat, chartSize: CGFloat, ring: DonutRing, isHighlighted: Bool) -> some View {
        let sliceShape = RingSliceShape(startAngle: slice.startAngle, endAngle: slice.endAngle, outerRadius: outerR, innerRadius: innerR, gap: sliceGap)
        ZStack {
            sliceFill(slice: slice, sliceShape: sliceShape, outerR: outerR, innerR: innerR, strokeW: strokeW)
                .overlay(sliceShape.stroke(Color.white.opacity(0.25), lineWidth: 0.4))
                .overlay(
                    sliceShape.stroke(Color.white, lineWidth: 8)
                        .blur(radius: 4).opacity(0.25).clipShape(sliceShape)
                )
                .scaleEffect(ringHoverExpand && isHighlighted ? 1.04 : 1.0)
                .opacity(hoverHighlight && highlightedRingID != nil && !isHighlighted ? 0.45 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: highlightedRingID)
                .onTapGesture {
                    if hoverHighlight || ringHoverExpand {
                        withAnimation { highlightedRingID = highlightedRingID == ring.id ? nil : ring.id }
                    }
                }

            if labelPosition == .inside {
                let mid = (slice.startAngle.degrees + slice.endAngle.degrees) / 2
                let midR = (outerR + innerR) / 2
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
    func sliceFill(slice: RingSlice, sliceShape: RingSliceShape, outerR: CGFloat, innerR: CGFloat, strokeW: CGFloat) -> some View {
        let grad = LinearGradient(colors: [slice.color.opacity(0.9), slice.color.opacity(0.5)], startPoint: .top, endPoint: .bottom)
        if roundedEdges {
            if gradientFill {
                RingArcPath(startAngle: slice.startAngle, endAngle: slice.endAngle, outerRadius: outerR, innerRadius: innerR, gap: sliceGap)
                    .stroke(grad, style: StrokeStyle(lineWidth: strokeW, lineCap: .round))
                    .glassEffect(.clear, in: sliceShape)
            } else {
                RingArcPath(startAngle: slice.startAngle, endAngle: slice.endAngle, outerRadius: outerR, innerRadius: innerR, gap: sliceGap)
                    .stroke(slice.color.opacity(0.75), style: StrokeStyle(lineWidth: strokeW, lineCap: .round))
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

    @ViewBuilder
    func centerOverlay(size: CGFloat, totalOuterR: CGFloat) -> some View {
        let innerHoleR = totalOuterR * CGFloat(innerRatio)
        let cy: CGFloat = {
            switch centerAlignment {
            case .top: return size / 2 - innerHoleR * 0.5
            case .middle: return size / 2
            case .bottom: return size / 2 + innerHoleR * 0.5
            }
        }()
        let totalPct = rings.first?.items.reduce(0.0) { $0 + $1.percentage } ?? 0
        switch centerContent {
        case .none:
            EmptyView()
        case .value:
            Text("\(Int(totalPct))%")
                .font(.system(size: CGFloat(centerSize), weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .position(x: size / 2, y: cy)
        case .label:
            Text(rings.first?.name ?? "")
                .font(.system(size: CGFloat(centerSize) * 0.45, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .frame(width: innerHoleR * 1.4)
                .position(x: size / 2, y: cy)
        case .icon:
            Image(systemName: "circle.grid.3x3.fill")
                .font(.system(size: CGFloat(centerSize)))
                .foregroundStyle(.secondary)
                .position(x: size / 2, y: cy)
        }
    }

    // MARK: - Settings: Ring Structure

    var ringStructureView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Rings")
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { n in
                        pillButton("\(n)", isSelected: rings.count == n) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { setRingCount(n) }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Thickness")
                Slider(value: $ringThickness, in: 10...60, step: 1)
                Text("\(Int(ringThickness))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Spacing")
                Slider(value: $ringSpacing, in: 0...20, step: 1)
                Text("\(Int(ringSpacing))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Inner R")
                Slider(value: $innerRatio, in: 0...0.6, step: 0.05)
                Text("\(Int(innerRatio * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Rotation & Layout

    var rotationLayoutView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Start")
                Slider(value: $chartStartAngle, in: -180...180, step: 15)
                Text("\(Int(chartStartAngle))°")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Gap")
                Slider(value: $sliceGap, in: 0...10, step: 0.5)
                Text(String(format: "%.1f°", sliceGap))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
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
        }
    }

    // MARK: - Settings: Ring Behaviour

    var ringBehaviourView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Mode")
                pillButton("Independent", isSelected: independentRings) {
                    independentRings = true
                }
                pillButton("Linked", isSelected: !independentRings) {
                    independentRings = false
                    linkAllRings()
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Highlight")
                Toggle("", isOn: $hoverHighlight).labelsHidden().scaleEffect(0.8)
                Text("Tap ring to highlight").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Expand")
                Toggle("", isOn: $ringHoverExpand).labelsHidden().scaleEffect(0.8)
                Text("Tap ring to expand").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
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
                settingsLabel("Ring ID")
                Toggle("", isOn: $showRingLabels).labelsHidden().scaleEffect(0.8)
                Text("Show ring name").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Visual

    var visualSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Track")
                Toggle("", isOn: $showTrack).labelsHidden().scaleEffect(0.8)
                Text("Background ring").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
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
        }
    }

    // MARK: - Item List

    var itemListView: some View {
        VStack(spacing: 0) {
            ForEach(Array(rings.enumerated()), id: \.element.id) { ringIdx, ring in
                ringSection(ringIdx: ringIdx, ring: ring)
            }
            Divider().padding(.horizontal, 20)
            Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { addRing() } } label: {
                Text("+ Add New Ring")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
    }

    @ViewBuilder
    func ringSection(ringIdx: Int, ring: DonutRing) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Circle()
                    .fill(ring.items.first?.color ?? .gray)
                    .frame(width: 8, height: 8)
                Text(ring.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                if rings.count > 1 {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { rings.removeAll { $0.id == ring.id } }
                    } label: {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 10)

            Divider().padding(.horizontal, 20)

            ForEach(Array(ring.items.enumerated()), id: \.element.id) { itemIdx, item in
                itemRow(ringIdx: ringIdx, itemIdx: itemIdx, item: item)
            }

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { addItem(to: ringIdx) }
            } label: {
                Text("+ Add Item to \(ring.name)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }

            if ringIdx < rings.count - 1 { Divider().padding(.horizontal, 20) }
        }
    }

    @ViewBuilder
    func itemRow(ringIdx: Int, itemIdx: Int, item: RingDataItem) -> some View {
        HStack(spacing: 12) {
            Button {
                #if os(iOS)
                let coord = ColorPickerCoordinator { color in rings[ringIdx].items[itemIdx].color = color }
                pickerCoordinator = coord
                let vc = UIColorPickerViewController()
                vc.selectedColor = UIColor(rings[ringIdx].items[itemIdx].color)
                vc.supportsAlpha = false
                vc.delegate = coord
                topViewController()?.present(vc, animated: true)
                #endif
            } label: {
                Circle()
                    .fill(rings[ringIdx].items[itemIdx].color)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
            }
            Text(item.label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
            Spacer()
            if editingRingID == rings[ringIdx].id && editingItemID == item.id {
                HStack(spacing: 2) {
                    TextField("0", text: $editingText)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(width: 48)
                        .onChange(of: editingText) { _, val in
                            if let v = Double(val) { redistribute(in: ringIdx, for: item.id, to: v) }
                        }
                    Text("%").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
                }
            } else {
                Button {
                    editingRingID = rings[ringIdx].id
                    editingItemID = item.id
                    editingText = "\(Int(item.percentage))"
                } label: {
                    Text("\(Int(item.percentage))%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .underline(color: .primary.opacity(0.25))
                }
                .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        if itemIdx < rings[ringIdx].items.count - 1 { Divider().padding(.horizontal, 20) }
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

    func setRingCount(_ n: Int) {
        while rings.count < n { addRing() }
        while rings.count > n { rings.removeLast() }
    }

    func addRing() {
        let idx = rings.count
        let palette = Self.colorPalettes[idx % Self.colorPalettes.count]
        rings.append(DonutRing(
            name: "Ring \(idx + 1)",
            items: [
                RingDataItem(label: "Item A", percentage: 40, color: palette[0]),
                RingDataItem(label: "Item B", percentage: 35, color: palette[1]),
                RingDataItem(label: "Item C", percentage: 25, color: palette[2]),
            ]
        ))
    }

    func addItem(to ringIdx: Int) {
        guard ringIdx < rings.count else { return }
        let palette = Self.colorPalettes[ringIdx % Self.colorPalettes.count]
        let colorIdx = rings[ringIdx].items.count % palette.count
        let gap = max(0.0, 100.0 - rings[ringIdx].items.reduce(0) { $0 + $1.percentage })
        rings[ringIdx].items.append(RingDataItem(
            label: "Item \(rings[ringIdx].items.count + 1)",
            percentage: gap,
            color: palette[colorIdx]
        ))
    }

    func redistribute(in ringIdx: Int, for id: UUID, to newValue: Double) {
        guard ringIdx < rings.count,
              let idx = rings[ringIdx].items.firstIndex(where: { $0.id == id }) else { return }
        let clamped = min(100, max(0, newValue))
        let remaining = 100.0 - clamped
        let others = rings[ringIdx].items.indices.filter { $0 != idx }
        let otherSum = others.reduce(0.0) { $0 + rings[ringIdx].items[$1].percentage }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            rings[ringIdx].items[idx].percentage = clamped
            if otherSum > 0 {
                let scale = remaining / otherSum
                for i in others { rings[ringIdx].items[i].percentage = max(0, rings[ringIdx].items[i].percentage * scale) }
            } else if !others.isEmpty {
                let share = remaining / Double(others.count)
                for i in others { rings[ringIdx].items[i].percentage = share }
            }
        }
    }

    func linkAllRings() {
        guard let first = rings.first else { return }
        for i in 1..<rings.count {
            let palette = Self.colorPalettes[i % Self.colorPalettes.count]
            rings[i].items = first.items.enumerated().map { j, item in
                RingDataItem(label: item.label, percentage: item.percentage, color: palette[j % palette.count])
            }
        }
    }
}

#Preview {
    ScrollView {
        MultiRingDonutCard(
            title: "Multi Ring Donut",
            categories: ["Multi Ring"],
            rings: [
                DonutRing(name: "Ring 1", items: [
                    RingDataItem(label: "Design", percentage: 40, color: MultiRingDonutCard.colorPalettes[0][0]),
                    RingDataItem(label: "Dev",    percentage: 35, color: MultiRingDonutCard.colorPalettes[0][1]),
                    RingDataItem(label: "Other",  percentage: 25, color: MultiRingDonutCard.colorPalettes[0][2]),
                ]),
                DonutRing(name: "Ring 2", items: [
                    RingDataItem(label: "Q1", percentage: 30, color: MultiRingDonutCard.colorPalettes[1][0]),
                    RingDataItem(label: "Q2", percentage: 45, color: MultiRingDonutCard.colorPalettes[1][1]),
                    RingDataItem(label: "Q3", percentage: 25, color: MultiRingDonutCard.colorPalettes[1][2]),
                ]),
            ]
        )
        .padding(.top, 20)
    }
}
