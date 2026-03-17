//
//  GroupedBarExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Data Models

struct GroupedSeries: Identifiable {
    let id = UUID()
    var name: String
    var color: Color
}

struct GroupedCategory: Identifiable {
    let id = UUID()
    var label: String
    var values: [Double]  // one value per series
}

// MARK: - Grouped Bar Card

struct GroupedBarCard: View {

    let title: String
    let categories: [String]
    @State private var series: [GroupedSeries]
    @State private var cats: [GroupedCategory]
    @State private var isExpanded = false
    @State private var highlightedSeriesID: UUID? = nil
    @State private var editingCatIdx: Int? = nil
    @State private var editingSeriesIdx: Int? = nil
    @State private var editingValCat: Int? = nil
    @State private var editingValSeries: Int? = nil
    @State private var editingText = ""

    // Chart Geometry
    @State private var barWidth: Double = 18
    @State private var barSpacing: Double = 4
    @State private var groupSpacing: Double = 16
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

    // Series Controls
    @State private var showLegend: Bool = true
    @State private var legendPosition: LegendPosition = .top
    @State private var colorMode: ColorMode = .distinct

    // Bar Styling
    @State private var cornerRadius: Double = 4
    @State private var gradientFill: Bool = false
    @State private var shadowEnabled: Bool = true
    @State private var barOpacity: Double = 0.85

    // Labels
    @State private var valueLabelOn: Bool = false
    @State private var labelPosition: LabelPosition = .top
    @State private var categoryLabelOn: Bool = true

    // Interaction
    @State private var hoverHighlight: Bool = true

    // Sorting
    @State private var sortOrder: SortOrder = .none

    #if os(iOS)
    @State private var pickerCoordinator: ColorPickerCoordinator? = nil
    #endif

    // MARK: - Enums

    enum ValueFormat: String, CaseIterable { case number = "Number", percent = "Percent", currency = "Currency" }
    enum ColorMode: String, CaseIterable { case distinct = "Distinct", monochrome = "Mono", gradient = "Gradient" }
    enum LegendPosition: String, CaseIterable { case top = "Top", bottom = "Bottom", hidden = "Hidden" }
    enum LabelPosition: String, CaseIterable { case top = "Top", inside = "Inside", hidden = "Hidden" }
    enum SortOrder: String, CaseIterable { case none = "Default", ascending = "Asc", descending = "Desc" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Init

    init(title: String, categories: [String], series: [GroupedSeries], cats: [GroupedCategory]) {
        self.title = title
        self.categories = categories
        self._series = State(initialValue: series)
        self._cats = State(initialValue: cats)
    }

    // MARK: - Computed

    var sortedCats: [GroupedCategory] {
        switch sortOrder {
        case .none: return cats
        case .ascending: return cats.sorted { maxVal($0) < maxVal($1) }
        case .descending: return cats.sorted { maxVal($0) > maxVal($1) }
        }
    }

    func maxVal(_ cat: GroupedCategory) -> Double {
        cat.values.prefix(series.count).max() ?? 0
    }

    var allValues: [Double] { cats.flatMap { $0.values.prefix(series.count) } }

    var effectiveYMax: Double {
        autoScale ? (allValues.max() ?? 100) * 1.2 : yAxisMax
    }

    var effectiveYMin: Double { autoScale ? 0 : yAxisMin }

    func yRatio(for value: Double) -> CGFloat {
        let range = effectiveYMax - effectiveYMin
        guard range > 0 else { return 0 }
        return CGFloat(max(0, min(1, (value - effectiveYMin) / range)))
    }

    func resolvedColor(for idx: Int) -> Color {
        switch colorMode {
        case .distinct: return series[idx].color
        case .monochrome:
            let t = 1.0 - Double(idx) / Double(max(1, series.count - 1)) * 0.55
            return series[0].color.opacity(t)
        case .gradient:
            let t = series.count > 1 ? Double(idx) / Double(series.count - 1) : 0
            return t < 0.5
                ? Self.colorPalette[0].opacity(0.5 + t)
                : Self.colorPalette[2].opacity(t)
        }
    }

    func formattedValue(_ value: Double) -> String {
        switch valueFormat {
        case .number:   return "\(Int(value))"
        case .percent:  return "\(Int(value))%"
        case .currency: return "$\(Int(value))"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                if showLegend && legendPosition == .top {
                    legendView
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }
                chartView
                    .frame(height: showLegend && legendPosition == .top ? 200 : 240)
                    .padding(.horizontal, 16)
                    .padding(.top, showLegend && legendPosition == .top ? 0 : 16)
                if showLegend && legendPosition == .bottom {
                    legendView
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                }
            }
            .shadow(color: .black.opacity(shadowEnabled ? 0.15 : 0), radius: 20, x: 0, y: 10)
            .shadow(color: .black.opacity(shadowEnabled ? 0.10 : 0), radius: 3, x: 0, y: 2)

            Divider().padding(.top, 8).padding(.horizontal, 12)

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
                    seriesControlsView
                    stylingSettingsView
                    labelSettingsView
                    interactionSettingsView
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
            editingValCat = nil; editingValSeries = nil
            editingCatIdx = nil; editingSeriesIdx = nil
            if hoverHighlight { highlightedSeriesID = nil }
        }
    }

    // MARK: - Legend

    var legendView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(series.enumerated()), id: \.element.id) { i, s in
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(resolvedColor(for: i).opacity(barOpacity))
                            .frame(width: 12, height: 12)
                        Text(s.name)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .opacity(highlightedSeriesID == nil || highlightedSeriesID == s.id ? 1 : 0.35)
                    .onTapGesture {
                        if hoverHighlight {
                            withAnimation { highlightedSeriesID = (highlightedSeriesID == s.id) ? nil : s.id }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            let sorted = sortedCats
            let leftM: CGFloat = (showYAxis && axisLabels) ? 36 : 6
            let rightM: CGFloat = CGFloat(chartPadding)
            let topM: CGFloat = (valueLabelOn && labelPosition == .top) ? 18 : 8
            let botM: CGFloat = categoryLabelOn ? 24 : (showXAxis ? 10 : 4)
            let chartW = geo.size.width - leftM - rightM
            let chartH = geo.size.height - topM - botM

            let n = series.count
            let groupW = CGFloat(barWidth) * CGFloat(n) + CGFloat(barSpacing) * CGFloat(max(0, n - 1))
            let nCats = max(1, sorted.count)
            let totalW = groupW * CGFloat(nCats) + CGFloat(groupSpacing) * CGFloat(max(0, nCats - 1))
            let startX = leftM + max(0, (chartW - totalW) / 2)

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

                // Groups
                HStack(alignment: .bottom, spacing: CGFloat(groupSpacing)) {
                    ForEach(sorted) { cat in
                        groupColumn(cat: cat, groupW: groupW, chartH: chartH, topM: topM, botM: botM)
                    }
                }
                .offset(x: startX, y: 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sorted.map { $0.values.first ?? 0 })
            }
        }
    }

    @ViewBuilder
    func groupColumn(cat: GroupedCategory, groupW: CGFloat, chartH: CGFloat, topM: CGFloat, botM: CGFloat) -> some View {
        let bW = CGFloat(barWidth)
        let barShape = RoundedRectangle(cornerRadius: CGFloat(cornerRadius), style: .continuous)

        ZStack(alignment: .top) {
            Color.clear.frame(width: groupW, height: topM + chartH + (categoryLabelOn ? 24 : 4))

            // Bars side by side
            HStack(alignment: .bottom, spacing: CGFloat(barSpacing)) {
                ForEach(Array(series.enumerated()), id: \.element.id) { si, s in
                    let val = si < cat.values.count ? cat.values[si] : 0
                    let barH = max(2, chartH * yRatio(for: val))
                    let color = resolvedColor(for: si)
                    let isHighlighted = highlightedSeriesID == s.id
                    let isDimmed = hoverHighlight && highlightedSeriesID != nil && !isHighlighted

                    ZStack(alignment: .bottom) {
                        Color.clear.frame(width: bW, height: chartH)

                        ZStack {
                            if gradientFill {
                                barShape.fill(LinearGradient(
                                    colors: [color.opacity(barOpacity), color.opacity(barOpacity * 0.6)],
                                    startPoint: .top, endPoint: .bottom
                                )).glassEffect(.clear, in: barShape)
                            } else {
                                barShape.fill(color.opacity(barOpacity))
                                    .glassEffect(.clear, in: barShape)
                            }
                            barShape.stroke(Color.white.opacity(0.25), lineWidth: 0.4)
                            barShape.stroke(Color.white, lineWidth: 8)
                                .blur(radius: 4).opacity(0.25).clipShape(barShape)

                            // Inside label
                            if valueLabelOn && labelPosition == .inside && barH > 16 {
                                Text(formattedValue(val))
                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .rotationEffect(.degrees(-90))
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: bW, height: barH)
                        .scaleEffect(y: isHighlighted ? 1.05 : 1.0, anchor: .bottom)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
                    }
                    .opacity(isDimmed ? 0.35 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDimmed)
                    .onTapGesture {
                        if hoverHighlight {
                            withAnimation { highlightedSeriesID = (highlightedSeriesID == s.id) ? nil : s.id }
                        }
                    }
                    // Top value label
                    .overlay(alignment: .top) {
                        if valueLabelOn && labelPosition == .top {
                            let barTopY = chartH - barH - 1
                            Text(formattedValue(val))
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                                .frame(width: bW + 6)
                                .offset(y: barTopY - 13 + topM)
                        }
                    }
                }
            }
            .offset(y: topM)

            // Category label
            if categoryLabelOn {
                Text(cat.label)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: groupW + 8)
                    .offset(y: topM + chartH + 6)
            }
        }
        .frame(width: groupW)
    }

    // MARK: - Settings: Geometry

    var geometrySettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Bar W")
                Slider(value: $barWidth, in: 10...60, step: 2)
                Text("\(Int(barWidth))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Bar Gap")
                Slider(value: $barSpacing, in: 0...30, step: 1)
                Text("\(Int(barSpacing))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Grp Gap")
                Slider(value: $groupSpacing, in: 0...60, step: 2)
                Text("\(Int(groupSpacing))pt")
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
                Text("Auto scale Y axis").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if !autoScale {
                HStack(spacing: 10) {
                    settingsLabel("Y Min")
                    TextField("0", value: $yAxisMin, format: .number)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.trailing).frame(maxWidth: .infinity)
                }
                HStack(spacing: 10) {
                    settingsLabel("Y Max")
                    TextField("100", value: $yAxisMax, format: .number)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numberPad)
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

    // MARK: - Settings: Series Controls

    var seriesControlsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Colors")
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
                    Text("Legend hidden").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    // MARK: - Settings: Styling

    var stylingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Radius")
                Slider(value: $cornerRadius, in: 0...20, step: 1)
                Text("\(Int(cornerRadius))pt")
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
                settingsLabel("Category")
                Toggle("", isOn: $categoryLabelOn).labelsHidden().scaleEffect(0.8)
                Text("Category labels").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
                Text("Tap series to highlight").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
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
            Text("Sorts groups by max series value")
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Data Editing

    var dataEditingView: some View {
        VStack(spacing: 0) {
            seriesHeaderView
            Divider().padding(.horizontal, 20)
            ForEach(Array(cats.enumerated()), id: \.element.id) { ci, cat in
                categorySection(ci: ci, cat: cat)
            }
            Divider().padding(.horizontal, 20)
            HStack(spacing: 0) {
                Button { addCategory() } label: {
                    Text("+ Add Category")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                Divider().frame(height: 20)
                Button { addSeries() } label: {
                    Text("+ Add Series")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
        }
    }

    var seriesHeaderView: some View {
        VStack(spacing: 0) {
            ForEach(Array(series.enumerated()), id: \.element.id) { si, s in
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
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(resolvedColor(for: si).opacity(barOpacity))
                            .frame(width: 26, height: 26)
                            .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Color.white, lineWidth: 2))
                            .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                    }
                    Text("Series")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                    if editingSeriesIdx == si {
                        TextField("Name", text: $editingText)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .onChange(of: editingText) { _, v in series[si].name = v }
                    } else {
                        Button {
                            editingSeriesIdx = si
                            editingText = series[si].name
                        } label: {
                            Text(s.name)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .underline(color: .primary.opacity(0.2))
                        }
                        .foregroundStyle(.primary)
                    }
                    Spacer()
                    if series.count > 1 {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                series.remove(at: si)
                                for ci in cats.indices {
                                    if si < cats[ci].values.count { cats[ci].values.remove(at: si) }
                                }
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 10)
                Divider().padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    func categorySection(ci: Int, cat: GroupedCategory) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                    .frame(width: 26)
                if editingCatIdx == ci {
                    TextField("Category", text: $editingText)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .onChange(of: editingText) { _, v in cats[ci].label = v }
                } else {
                    Button {
                        editingCatIdx = ci
                        editingText = cats[ci].label
                    } label: {
                        Text(cat.label)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .underline(color: .primary.opacity(0.2))
                    }
                    .foregroundStyle(.primary)
                }
                Spacer()
                if cats.count > 1 {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { cats.remove(at: ci) }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 10)

            ForEach(Array(series.enumerated()), id: \.element.id) { si, s in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(resolvedColor(for: si).opacity(barOpacity))
                        .frame(width: 10, height: 10)
                        .padding(.leading, 38)
                    Text(s.name)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if editingValCat == ci && editingValSeries == si {
                        TextField("0", text: $editingText)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                            .frame(width: 52)
                            .onChange(of: editingText) { _, val in
                                if let v = Double(val) {
                                    while cats[ci].values.count <= si { cats[ci].values.append(0) }
                                    cats[ci].values[si] = max(0, v)
                                }
                            }
                    } else {
                        Button {
                            editingValCat = ci; editingValSeries = si
                            let v = si < cat.values.count ? cat.values[si] : 0
                            editingText = "\(Int(v))"
                        } label: {
                            let v = si < cat.values.count ? cat.values[si] : 0
                            Text("\(Int(v))")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .underline(color: .primary.opacity(0.2))
                        }
                        .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 8)
                if si < series.count - 1 { Divider().padding(.horizontal, 38) }
            }

            Divider().padding(.horizontal, 20)
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

    func addCategory() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            cats.append(GroupedCategory(
                label: "Cat \(cats.count + 1)",
                values: series.indices.map { _ in Double.random(in: 20...70) }
            ))
        }
    }

    func addSeries() {
        guard series.count < 5 else { return }
        let colorIdx = series.count % Self.colorPalette.count
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            series.append(GroupedSeries(
                name: "Series \(series.count + 1)",
                color: Self.colorPalette[colorIdx]
            ))
            for i in cats.indices {
                cats[i].values.append(Double.random(in: 20...70))
            }
        }
    }
}

#Preview {
    ScrollView {
        GroupedBarCard(
            title: "Grouped Bar Chart",
            categories: ["Grouped Bar"],
            series: [
                GroupedSeries(name: "2023", color: AnalyticsCard.colorPalette[0]),
                GroupedSeries(name: "2024", color: AnalyticsCard.colorPalette[1]),
                GroupedSeries(name: "2025", color: AnalyticsCard.colorPalette[2]),
            ],
            cats: [
                GroupedCategory(label: "Jan", values: [42, 58, 35]),
                GroupedCategory(label: "Feb", values: [55, 40, 70]),
                GroupedCategory(label: "Mar", values: [30, 75, 50]),
                GroupedCategory(label: "Apr", values: [68, 45, 60]),
                GroupedCategory(label: "May", values: [48, 62, 80]),
            ]
        )
        .padding(.top, 20)
    }
}
