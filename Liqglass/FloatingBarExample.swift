//
//  FloatingBarExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Floating Bar Data Model

struct FloatingBarItem: Identifiable {
    let id = UUID()
    var label: String
    var startValue: Double
    var endValue: Double
    var color: Color
}

// MARK: - Floating Bar Card

struct FloatingBarCard: View {

    let title: String
    let categories: [String]
    @State private var items: [FloatingBarItem]
    @State private var isExpanded = false
    @State private var highlightedID: UUID? = nil
    @State private var editingID: UUID? = nil
    @State private var editingField: EditField = .end
    @State private var editingText = ""

    // Chart Geometry
    @State private var barWidth: Double = 28
    @State private var barSpacing: Double = 12
    @State private var chartPadding: Double = 12

    // Axis Controls
    @State private var showXAxis: Bool = true
    @State private var showYAxis: Bool = true
    @State private var axisLabels: Bool = true
    @State private var axisGrid: Bool = true
    @State private var gridOpacity: Double = 0.25

    // Value Scaling
    @State private var autoScale: Bool = true
    @State private var yAxisMin: Double = -50
    @State private var yAxisMax: Double = 100
    @State private var valueFormat: ValueFormat = .number

    // Baseline
    @State private var baselineValue: Double = 0
    @State private var baselineStyle: BaselineStyle = .solid
    @State private var baselineHighlight: Bool = true

    // Bar Controls
    @State private var barMode: BarMode = .diverging
    @State private var rangeInput: Bool = false

    // Bar Styling
    @State private var cornerRadius: Double = 6
    @State private var gradientFill: Bool = false
    @State private var shadowEnabled: Bool = true
    @State private var barOpacity: Double = 0.85

    // Labels
    @State private var valueLabelOn: Bool = true
    @State private var labelType: LabelType = .end
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

    enum EditField { case start, end }
    enum ValueFormat: String, CaseIterable { case number = "Number", percent = "Percent", currency = "Currency" }
    enum BaselineStyle: String, CaseIterable { case solid = "Solid", dashed = "Dashed", hidden = "Hidden" }
    enum BarMode: String, CaseIterable { case positive = "Positive", negative = "Negative", diverging = "Diverging" }
    enum LabelType: String, CaseIterable { case start = "Start", end = "End", both = "Both" }
    enum LabelPosition: String, CaseIterable { case top = "Top", inside = "Inside", hidden = "Hidden" }
    enum SortOrder: String, CaseIterable { case none = "Default", ascending = "Asc", descending = "Desc" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Init

    init(title: String, categories: [String], items: [FloatingBarItem]) {
        self.title = title
        self.categories = categories
        self._items = State(initialValue: items)
    }

    // MARK: - Computed

    var sortedItems: [FloatingBarItem] {
        switch sortOrder {
        case .none: return items
        case .ascending: return items.sorted { $0.endValue < $1.endValue }
        case .descending: return items.sorted { $0.endValue > $1.endValue }
        }
    }

    var allValues: [Double] {
        items.flatMap { [$0.startValue, $0.endValue] } + [baselineValue]
    }

    var effectiveYMax: Double {
        if autoScale { return (allValues.max() ?? 100) + abs((allValues.max() ?? 100) - (allValues.min() ?? 0)) * 0.15 }
        return yAxisMax
    }

    var effectiveYMin: Double {
        if autoScale { return (allValues.min() ?? 0) - abs((allValues.max() ?? 100) - (allValues.min() ?? 0)) * 0.15 }
        return yAxisMin
    }

    func yRatio(for value: Double) -> CGFloat {
        let range = effectiveYMax - effectiveYMin
        guard range > 0 else { return 0 }
        return CGFloat(max(0, min(1, (value - effectiveYMin) / range)))
    }

    func barColor(for item: FloatingBarItem) -> Color {
        switch barMode {
        case .positive: return item.color
        case .negative: return item.color
        case .diverging:
            let delta = item.endValue - item.startValue
            if delta >= 0 { return Color(red: 0.25, green: 0.72, blue: 0.48) }
            else { return Color(red: 0.88, green: 0.32, blue: 0.32) }
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
                    baselineSettingsView
                    barControlsView
                    stylingSettingsView
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
        .onTapGesture {
            editingID = nil
            if hoverHighlight { highlightedID = nil }
        }
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            let sorted = sortedItems
            let leftM: CGFloat = (showYAxis && axisLabels) ? 36 : 6
            let rightM: CGFloat = CGFloat(chartPadding)
            let topM: CGFloat = (valueLabelOn && labelPosition == .top) ? 20 : 8
            let botM: CGFloat = categoryLabelOn ? 26 : (showXAxis ? 10 : 4)
            let chartW = geo.size.width - leftM - rightM
            let chartH = geo.size.height - topM - botM

            let n = max(1, sorted.count)
            let gap = CGFloat(barSpacing) * CGFloat(max(0, n - 1))
            let bW = min(CGFloat(barWidth), max(6, (chartW - gap) / CGFloat(n)))
            let totalW = bW * CGFloat(n) + gap
            let startX = leftM + max(0, (chartW - totalW) / 2)

            // Y positions
            let baselineY = topM + chartH * (1 - yRatio(for: baselineValue))

            ZStack(alignment: .topLeading) {

                // Horizontal grid lines
                if axisGrid {
                    ForEach(0...4, id: \.self) { i in
                        let yFrac = CGFloat(i) / 4
                        let y = topM + chartH * yFrac
                        Path { p in
                            p.move(to: CGPoint(x: leftM, y: y))
                            p.addLine(to: CGPoint(x: leftM + chartW, y: y))
                        }
                        .stroke(Color.primary.opacity(gridOpacity), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    }
                }

                // Y axis tick labels
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

                // Y axis line
                if showYAxis {
                    Path { p in
                        p.move(to: CGPoint(x: leftM, y: topM))
                        p.addLine(to: CGPoint(x: leftM, y: topM + chartH))
                    }
                    .stroke(Color.primary.opacity(0.25), lineWidth: 0.75)
                }

                // X axis (bottom)
                if showXAxis {
                    Path { p in
                        p.move(to: CGPoint(x: leftM, y: topM + chartH))
                        p.addLine(to: CGPoint(x: leftM + chartW, y: topM + chartH))
                    }
                    .stroke(Color.primary.opacity(0.25), lineWidth: 0.75)
                }

                // Baseline line
                if baselineStyle != .hidden {
                    Path { p in
                        p.move(to: CGPoint(x: leftM, y: baselineY))
                        p.addLine(to: CGPoint(x: leftM + chartW, y: baselineY))
                    }
                    .stroke(
                        baselineHighlight ? Color.primary.opacity(0.55) : Color.primary.opacity(0.25),
                        style: StrokeStyle(
                            lineWidth: baselineHighlight ? 1.5 : 0.75,
                            dash: baselineStyle == .dashed ? [6, 4] : []
                        )
                    )
                }

                // Bars
                HStack(alignment: .top, spacing: CGFloat(barSpacing)) {
                    ForEach(sorted) { item in
                        barColumn(item: item, bW: bW, chartH: chartH, topM: topM)
                    }
                }
                .offset(x: startX, y: 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sorted.map { $0.endValue })
            }
        }
    }

    @ViewBuilder
    func barColumn(item: FloatingBarItem, bW: CGFloat, chartH: CGFloat, topM: CGFloat) -> some View {
        let lo = min(item.startValue, item.endValue)
        let hi = max(item.startValue, item.endValue)
        let yTop = topM + chartH * (1 - yRatio(for: hi))
        let yBot = topM + chartH * (1 - yRatio(for: lo))
        let barH = max(2, yBot - yTop)

        let color = barColor(for: item)
        let barShape = RoundedRectangle(cornerRadius: CGFloat(cornerRadius), style: .continuous)
        let isHighlighted = highlightedID == item.id
        let isDimmed = hoverHighlight && highlightedID != nil && !isHighlighted

        ZStack(alignment: .top) {
            Color.clear.frame(width: bW, height: topM + chartH + (categoryLabelOn ? 26 : 4))

            // Bar body — positioned via offset from top
            ZStack {
                if gradientFill {
                    barShape.fill(LinearGradient(
                        colors: [color.opacity(barOpacity), color.opacity(barOpacity * 0.55)],
                        startPoint: .top, endPoint: .bottom
                    )).glassEffect(.clear, in: barShape)
                } else {
                    barShape.fill(color.opacity(barOpacity)).glassEffect(.clear, in: barShape)
                }
                barShape.stroke(Color.white.opacity(0.25), lineWidth: 0.4)
                barShape.stroke(Color.white, lineWidth: 8)
                    .blur(radius: 4).opacity(0.25).clipShape(barShape)

                // Inside labels
                if valueLabelOn && labelPosition == .inside && barH > 24 {
                    VStack(spacing: 1) {
                        if labelType == .start || labelType == .both {
                            Text(formattedValue(item.startValue))
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        if labelType == .end || labelType == .both {
                            Text(formattedValue(item.endValue))
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .frame(width: bW, height: barH)
            .offset(y: yTop)
            .scaleEffect(isHighlighted ? 1.04 : 1.0, anchor: .center)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)

            // Top label
            if valueLabelOn && labelPosition == .top {
                VStack(spacing: 1) {
                    if labelType == .end || labelType == .both {
                        Text(formattedValue(item.endValue))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    if labelType == .start || labelType == .both {
                        Text(formattedValue(item.startValue))
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: bW + 10)
                .offset(y: max(2, yTop - 18))
            }

            // Category label
            if categoryLabelOn {
                Text(item.label)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: bW + 8)
                    .offset(y: topM + chartH + 6)
            }
        }
        .opacity(isDimmed ? 0.4 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDimmed)
        .onTapGesture {
            if hoverHighlight {
                withAnimation { highlightedID = (highlightedID == item.id) ? nil : item.id }
            }
        }
    }

    // MARK: - Settings: Geometry

    var geometrySettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Bar W")
                Slider(value: $barWidth, in: 10...80, step: 2)
                Text("\(Int(barWidth))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Spacing")
                Slider(value: $barSpacing, in: 0...40, step: 2)
                Text("\(Int(barSpacing))pt")
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
                    TextField("-50", value: $yAxisMin, format: .number)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity)
                }
                HStack(spacing: 10) {
                    settingsLabel("Y Max")
                    TextField("100", value: $yAxisMax, format: .number)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity)
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

    // MARK: - Settings: Baseline

    var baselineSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Baseline")
                TextField("0", value: $baselineValue, format: .number)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    #if os(iOS)
                    .keyboardType(.numbersAndPunctuation)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity)
                    .onChange(of: baselineValue) { _, val in
                        if !rangeInput {
                            for i in items.indices { items[i].startValue = val }
                        }
                    }
            }
            HStack(spacing: 10) {
                settingsLabel("Style")
                HStack(spacing: 4) {
                    ForEach(BaselineStyle.allCases, id: \.self) { s in
                        pillButton(s.rawValue, isSelected: baselineStyle == s) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { baselineStyle = s }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Highlight")
                Toggle("", isOn: $baselineHighlight).labelsHidden().scaleEffect(0.8)
                Text("Emphasise baseline").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Bar Controls

    var barControlsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Mode")
                HStack(spacing: 4) {
                    ForEach(BarMode.allCases, id: \.self) { m in
                        pillButton(m.rawValue, isSelected: barMode == m) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { barMode = m }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Range")
                Toggle("", isOn: $rangeInput).labelsHidden().scaleEffect(0.8)
                Text("Custom start + end per bar").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            .onChange(of: rangeInput) { _, on in
                if !on {
                    for i in items.indices { items[i].startValue = baselineValue }
                }
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
                Text("Tap to highlight bar").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
            Text("Sorts by end value")
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(.tertiary)
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
    func itemRow(index: Int, item: FloatingBarItem) -> some View {
        HStack(spacing: 10) {
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
                    .frame(width: 26, height: 26)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
            }

            Text(item.label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .lineLimit(1)

            Spacer()

            if rangeInput {
                // Start value
                VStack(alignment: .trailing, spacing: 1) {
                    Text("from")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                    if editingID == item.id && editingField == .start {
                        TextField("0", text: $editingText)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            #if os(iOS)
                            .keyboardType(.numbersAndPunctuation)
                            #endif
                            .multilineTextAlignment(.trailing)
                            .frame(width: 42)
                            .onChange(of: editingText) { _, val in
                                if let v = Double(val) { items[index].startValue = v }
                            }
                    } else {
                        Button {
                            editingID = item.id; editingField = .start
                            editingText = "\(Int(item.startValue))"
                        } label: {
                            Text("\(Int(item.startValue))")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .underline(color: .primary.opacity(0.2))
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 42, alignment: .trailing)

                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // End value
            VStack(alignment: .trailing, spacing: 1) {
                Text(rangeInput ? "to" : "value")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
                if editingID == item.id && editingField == .end {
                    TextField("0", text: $editingText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(width: 42)
                        .onChange(of: editingText) { _, val in
                            if let v = Double(val) { items[index].endValue = v }
                        }
                } else {
                    Button {
                        editingID = item.id; editingField = .end
                        editingText = "\(Int(item.endValue))"
                    } label: {
                        Text("\(Int(item.endValue))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .underline(color: .primary.opacity(0.2))
                    }
                    .foregroundStyle(.primary)
                }
            }
            .frame(width: 42, alignment: .trailing)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
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
            items.append(FloatingBarItem(
                label: "Item \(items.count + 1)",
                startValue: baselineValue,
                endValue: 30,
                color: Self.colorPalette[colorIdx]
            ))
        }
    }
}

#Preview {
    ScrollView {
        FloatingBarCard(
            title: "Floating Bar Chart",
            categories: ["Floating Bar"],
            items: [
                FloatingBarItem(label: "Jan", startValue: 0,   endValue:  45,  color: AnalyticsCard.colorPalette[0]),
                FloatingBarItem(label: "Feb", startValue: 0,   endValue: -20,  color: AnalyticsCard.colorPalette[1]),
                FloatingBarItem(label: "Mar", startValue: 0,   endValue:  72,  color: AnalyticsCard.colorPalette[2]),
                FloatingBarItem(label: "Apr", startValue: 0,   endValue: -35,  color: AnalyticsCard.colorPalette[3]),
                FloatingBarItem(label: "May", startValue: 0,   endValue:  58,  color: AnalyticsCard.colorPalette[4]),
                FloatingBarItem(label: "Jun", startValue: 0,   endValue:  88,  color: AnalyticsCard.colorPalette[5]),
            ]
        )
        .padding(.top, 20)
    }
}
