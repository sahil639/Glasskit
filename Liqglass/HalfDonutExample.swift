//
//  HalfDonutExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Half Donut Card

struct HalfDonutCard: View {

    let title: String
    let categories: [String]
    @State private var items: [AnalyticsDataItem]
    @State private var isExpanded = false
    @State private var editingID: UUID? = nil
    @State private var editingText = ""

    // Chart Geometry
    @State private var arcPreset: ArcPreset = .half
    @State private var customArcAngle: Double = 180
    @State private var innerRatio: Double = 0.52
    @State private var arcOffset: Double = 0

    // Slice Controls
    @State private var sliceGap: Double = 1.5
    @State private var chartStartAngle: Double = 180
    @State private var sortOrder: SortOrder = .none
    @State private var roundedEdges = false
    @State private var hoverExpand = false
    @State private var minSliceAngle: Double = 0
    @State private var expandedSliceID: UUID? = nil

    // Center Content
    @State private var centerContent: CenterContent = .none
    @State private var centerAlignment: CenterAlignment = .middle
    @State private var centerSize: Double = 36

    // Labels
    @State private var labelPosition: LabelPosition = .hidden
    @State private var percentageStyle: PercentageStyle = .percent

    // Visual
    @State private var showTrack = false
    @State private var gradientFill = false
    @State private var shadowEnabled = true

    #if os(iOS)
    @State private var pickerCoordinator: ColorPickerCoordinator? = nil
    #endif

    // MARK: - Enums

    enum ArcPreset: String, CaseIterable {
        case half = "180°", wide = "220°", wider = "240°", quarter = "270°", custom = "Custom"
        var degrees: Double? {
            switch self {
            case .half: return 180; case .wide: return 220
            case .wider: return 240; case .quarter: return 270; case .custom: return nil
            }
        }
    }

    enum SortOrder: String, CaseIterable { case none = "Default", ascending = "Asc", descending = "Desc" }
    enum CenterContent: String, CaseIterable { case none = "None", value = "Value", label = "Label", icon = "Icon" }
    enum CenterAlignment: String, CaseIterable { case top = "Top", middle = "Mid", bottom = "Bot" }
    enum LabelPosition: String, CaseIterable { case inside = "Inside", outside = "Outside", legend = "Legend", hidden = "Hidden" }
    enum PercentageStyle: String, CaseIterable { case value = "Value", percent = "Pct", both = "Both" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Slice Model

    struct Slice: Identifiable {
        let id: UUID
        var startAngle: Angle
        var endAngle: Angle
        let color: Color
        let label: String
        let percentage: Double
    }

    // MARK: - Computed

    var effectiveArcAngle: Double { arcPreset.degrees ?? customArcAngle }

    var slices: [Slice] {
        let arc = effectiveArcAngle
        var cursor = chartStartAngle
        let sorted: [AnalyticsDataItem] = {
            switch sortOrder {
            case .none: return items
            case .ascending: return items.sorted { $0.percentage < $1.percentage }
            case .descending: return items.sorted { $0.percentage > $1.percentage }
            }
        }()
        let total = sorted.reduce(0.0) { $0 + $1.percentage }
        guard total > 0 else { return [] }
        var result: [Slice] = []
        for item in sorted {
            let sweep = max(minSliceAngle, arc * item.percentage / total)
            result.append(Slice(
                id: item.id,
                startAngle: .degrees(cursor),
                endAngle: .degrees(cursor + sweep),
                color: item.color,
                label: item.label,
                percentage: item.percentage
            ))
            cursor += sweep
        }
        return result
    }

    // MARK: - Init

    init(title: String, categories: [String], items: [AnalyticsDataItem]) {
        self.title = title
        self.categories = categories
        self._items = State(initialValue: items)
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
                    sliceSettingsView
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
        .onTapGesture { editingID = nil }
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let outerR = size / 2
            let innerR = CGFloat(innerRatio)
            let strokeW = outerR * (1 - innerR)
            ZStack {
                if showTrack {
                    PieSliceShape(
                        startAngle: .degrees(chartStartAngle),
                        endAngle: .degrees(chartStartAngle + effectiveArcAngle),
                        innerRadiusRatio: innerR, gap: 0
                    )
                    .fill(Color.black.opacity(0.06))
                }
                ForEach(slices) { slice in
                    sliceContent(slice: slice, outerR: outerR, innerR: innerR, strokeW: strokeW, chartSize: size)
                }
                if centerContent != .none {
                    centerOverlay(size: size, outerR: outerR, innerR: innerR)
                }
            }
            .frame(width: size, height: size)
            .offset(y: arcOffset)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: slices.map { $0.startAngle.degrees })
        }
    }

    @ViewBuilder
    func sliceContent(slice: Slice, outerR: CGFloat, innerR: CGFloat, strokeW: CGFloat, chartSize: CGFloat) -> some View {
        let isSelected = expandedSliceID == slice.id
        let sliceShape = PieSliceShape(startAngle: slice.startAngle, endAngle: slice.endAngle, innerRadiusRatio: innerR, gap: sliceGap)
        ZStack {
            sliceFill(slice: slice, sliceShape: sliceShape, innerR: innerR, strokeW: strokeW)
                .overlay(sliceShape.stroke(Color.white.opacity(0.25), lineWidth: 0.4))
                .overlay(
                    sliceShape.stroke(Color.white, lineWidth: 8)
                        .blur(radius: 4).opacity(0.25).clipShape(sliceShape)
                )
                .scaleEffect(isSelected && hoverExpand ? 1.04 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: expandedSliceID)
                .onTapGesture {
                    if hoverExpand {
                        withAnimation { expandedSliceID = (expandedSliceID == slice.id) ? nil : slice.id }
                    }
                }
            if labelPosition == .inside {
                let mid = (slice.startAngle.degrees + slice.endAngle.degrees) / 2
                let midR = outerR * (1 + innerR) / 2
                Text(labelText(for: slice))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .position(
                        x: chartSize / 2 + midR * CGFloat(cos(Angle(degrees: mid).radians)),
                        y: chartSize / 2 + midR * CGFloat(sin(Angle(degrees: mid).radians))
                    )
            }
        }
    }

    @ViewBuilder
    func sliceFill(slice: Slice, sliceShape: PieSliceShape, innerR: CGFloat, strokeW: CGFloat) -> some View {
        let grad = LinearGradient(colors: [slice.color.opacity(0.9), slice.color.opacity(0.5)], startPoint: .top, endPoint: .bottom)
        if roundedEdges {
            if gradientFill {
                PieArcPath(startAngle: slice.startAngle, endAngle: slice.endAngle, innerRadiusRatio: innerR, gap: sliceGap)
                    .stroke(grad, style: StrokeStyle(lineWidth: strokeW, lineCap: .round))
                    .glassEffect(.clear, in: sliceShape)
            } else {
                PieArcPath(startAngle: slice.startAngle, endAngle: slice.endAngle, innerRadiusRatio: innerR, gap: sliceGap)
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

    func labelText(for slice: Slice) -> String {
        switch percentageStyle {
        case .value: return "\(Int(slice.percentage))"
        case .percent: return "\(Int(slice.percentage))%"
        case .both: return "\(slice.label) \(Int(slice.percentage))%"
        }
    }

    @ViewBuilder
    func centerOverlay(size: CGFloat, outerR: CGFloat, innerR: CGFloat) -> some View {
        let actualInnerR = outerR * innerR
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
            Text("\(Int(items.reduce(0.0) { $0 + $1.percentage }))%")
                .font(.system(size: CGFloat(centerSize), weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .position(x: size / 2, y: cy)
        case .label:
            Text(items.max(by: { $0.percentage < $1.percentage })?.label ?? "")
                .font(.system(size: CGFloat(centerSize) * 0.45, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .frame(width: actualInnerR * 1.4)
                .position(x: size / 2, y: cy)
        case .icon:
            Image(systemName: "chart.pie.fill")
                .font(.system(size: CGFloat(centerSize)))
                .foregroundStyle(.secondary)
                .position(x: size / 2, y: cy)
        }
    }

    // MARK: - Settings: Geometry

    var geometrySettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Arc")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(ArcPreset.allCases, id: \.self) { preset in
                            pillButton(preset.rawValue, isSelected: arcPreset == preset) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { arcPreset = preset }
                            }
                        }
                    }
                }
            }
            if arcPreset == .custom {
                HStack(spacing: 10) {
                    settingsLabel("Angle")
                    Slider(value: $customArcAngle, in: 90...360, step: 5)
                    Text("\(Int(customArcAngle))°")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
            HStack(spacing: 10) {
                settingsLabel("Radius")
                Slider(value: $innerRatio, in: 0...0.8, step: 0.05)
                Text("\(Int(innerRatio * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Offset")
                Slider(value: $arcOffset, in: -100...100, step: 1)
                Text("\(Int(arcOffset))")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Slice

    var sliceSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Spacing")
                Slider(value: $sliceGap, in: 0...10, step: 0.5)
                Text(String(format: "%.1f°", sliceGap))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Start")
                Slider(value: $chartStartAngle, in: 0...360, step: 15)
                Text("\(Int(chartStartAngle))°")
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
            HStack(spacing: 10) {
                settingsLabel("Expand")
                Toggle("", isOn: $hoverExpand).labelsHidden().scaleEffect(0.8)
                Text("Tap slice to expand").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Min °")
                Slider(value: $minSliceAngle, in: 0...10, step: 0.5)
                Text(String(format: "%.1f°", minSliceAngle))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
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
        }
    }

    // MARK: - Settings: Visual

    var visualSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Track")
                Toggle("", isOn: $showTrack).labelsHidden().scaleEffect(0.8)
                Text("Background arc").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
                HStack(spacing: 2) {
                    TextField("0", text: $editingText)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 48)
                        .onChange(of: editingText) { _, val in
                            if let v = Double(val) { redistribute(for: item.id, to: v) }
                        }
                    Text("%").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
                }
            } else {
                Button {
                    editingID = item.id
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
        if index < items.count - 1 { Divider().padding(.horizontal, 20) }
    }

    // MARK: - Reusable UI Helpers

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

    func redistribute(for id: UUID, to newValue: Double) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let clamped = min(100, max(0, newValue))
        let remaining = 100.0 - clamped
        let others = items.indices.filter { $0 != idx }
        let otherSum = others.reduce(0.0) { $0 + items[$1].percentage }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            items[idx].percentage = clamped
            if otherSum > 0 {
                let scale = remaining / otherSum
                for i in others { items[i].percentage = max(0, items[i].percentage * scale) }
            } else if !others.isEmpty {
                let share = remaining / Double(others.count)
                for i in others { items[i].percentage = share }
            }
        }
    }

    func addItem() {
        let colorIdx = items.count % Self.colorPalette.count
        let gap = max(0.0, 100.0 - items.reduce(0) { $0 + $1.percentage })
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            items.append(AnalyticsDataItem(
                label: "Item \(items.count + 1)",
                percentage: gap,
                color: Self.colorPalette[colorIdx]
            ))
        }
    }
}

#Preview {
    ScrollView {
        HalfDonutCard(
            title: "Half Donut Chart",
            categories: ["Half Donut"],
            items: [
                AnalyticsDataItem(label: "Design", percentage: 40, color: AnalyticsCard.colorPalette[0]),
                AnalyticsDataItem(label: "Dev",    percentage: 35, color: AnalyticsCard.colorPalette[1]),
                AnalyticsDataItem(label: "Other",  percentage: 25, color: AnalyticsCard.colorPalette[2]),
            ]
        )
        .padding(.top, 20)
    }
}
