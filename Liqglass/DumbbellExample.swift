//
//  DumbbellExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Dumbbell Data Model

struct DumbbellDataItem: Identifiable {
    let id = UUID()
    var label: String
    var startValue: Double
    var endValue: Double
    var color: Color
}

// MARK: - Dumbbell Card

struct DumbbellCard: View {

    let title: String
    let categories: [String]
    @State private var items: [DumbbellDataItem]
    @State private var isExpanded = false
    @State private var highlightedID: UUID? = nil
    @State private var editingID: UUID? = nil
    @State private var editingField: EditField = .start
    @State private var editingText = ""

    // Chart Geometry
    @State private var dotSize: Double = 14
    @State private var lineThickness: Double = 3
    @State private var itemSpacing: Double = 14
    @State private var chartPadding: Double = 12

    // Axis Controls
    @State private var showXAxis: Bool = true
    @State private var showYAxis: Bool = true
    @State private var axisLabels: Bool = true
    @State private var axisGrid: Bool = true
    @State private var gridOpacity: Double = 0.25

    // Value Scaling
    @State private var autoScale: Bool = true
    @State private var xAxisMin: Double = 0
    @State private var xAxisMax: Double = 100
    @State private var valueFormat: ValueFormat = .number

    // Connection Styling
    @State private var lineDashed: Bool = false
    @State private var lineOpacity: Double = 0.65

    // Dot Styling
    @State private var dotShapeStyle: DotShapeStyle = .circle
    @State private var dotShadow: Bool = true
    @State private var dotGradient: Bool = false

    // Labels
    @State private var valueLabelOn: Bool = true
    @State private var labelType: LabelType = .both

    // Difference Highlight
    @State private var diffHighlight: Bool = true
    @State private var diffType: DiffType = .absolute

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
    enum DotShapeStyle: String, CaseIterable { case circle = "Circle", square = "Square" }
    enum LabelType: String, CaseIterable { case start = "Start", end = "End", both = "Both", diff = "Diff" }
    enum DiffType: String, CaseIterable { case absolute = "Absolute", percent = "Percent" }
    enum SortOrder: String, CaseIterable { case none = "Default", ascending = "Asc", descending = "Desc" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Init

    init(title: String, categories: [String], items: [DumbbellDataItem]) {
        self.title = title
        self.categories = categories
        self._items = State(initialValue: items)
    }

    // MARK: - Computed

    var sortedItems: [DumbbellDataItem] {
        switch sortOrder {
        case .none: return items
        case .ascending: return items.sorted { ($0.endValue - $0.startValue) < ($1.endValue - $1.startValue) }
        case .descending: return items.sorted { ($0.endValue - $0.startValue) > ($1.endValue - $1.startValue) }
        }
    }

    var allValues: [Double] { items.flatMap { [$0.startValue, $0.endValue] } }

    var effectiveXMax: Double {
        autoScale ? (allValues.max() ?? 100) * 1.15 : xAxisMax
    }

    var effectiveXMin: Double {
        autoScale ? max(0, (allValues.min() ?? 0) * 0.85) : xAxisMin
    }

    func xRatio(for value: Double) -> CGFloat {
        let range = effectiveXMax - effectiveXMin
        guard range > 0 else { return 0 }
        return CGFloat(max(0, min(1, (value - effectiveXMin) / range)))
    }

    func formattedValue(_ value: Double) -> String {
        switch valueFormat {
        case .number:   return "\(Int(value))"
        case .percent:  return "\(Int(value))%"
        case .currency: return "$\(Int(value))"
        }
    }

    func formattedDiff(_ item: DumbbellDataItem) -> String {
        let diff = item.endValue - item.startValue
        switch diffType {
        case .absolute:
            return (diff >= 0 ? "+" : "") + "\(Int(diff))"
        case .percent:
            guard item.startValue != 0 else { return "—" }
            let pct = (diff / item.startValue) * 100
            return (pct >= 0 ? "+" : "") + "\(Int(pct))%"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            chartView
                .frame(height: 240)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .shadow(color: .black.opacity(dotShadow ? 0.15 : 0), radius: 20, x: 0, y: 10)
                .shadow(color: .black.opacity(dotShadow ? 0.10 : 0), radius: 3, x: 0, y: 2)

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
                    connectionSettingsView
                    dotSettingsView
                    labelSettingsView
                    diffSettingsView
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
            let leftM: CGFloat = axisLabels ? 68 : 6
            let rightM: CGFloat = CGFloat(chartPadding) + CGFloat(dotSize) / 2
            let topM: CGFloat = valueLabelOn ? 18 : CGFloat(dotSize) / 2 + 2
            let botM: CGFloat = (showXAxis && axisLabels) ? 22 : (showXAxis ? 10 : 4)
            let chartW = geo.size.width - leftM - rightM
            let chartH = geo.size.height - topM - botM

            let n = max(1, sorted.count)
            let gap = CGFloat(itemSpacing) * CGFloat(max(0, n - 1))
            let rowH = max(CGFloat(dotSize) + 4, (chartH - gap) / CGFloat(n))
            let totalH = rowH * CGFloat(n) + gap
            let startY = topM + max(0, (chartH - totalH) / 2)

            ZStack(alignment: .topLeading) {

                // Vertical grid lines
                if axisGrid {
                    ForEach(0...4, id: \.self) { i in
                        let xFrac = CGFloat(i) / 4
                        let x = leftM + chartW * xFrac
                        Path { p in
                            p.move(to: CGPoint(x: x, y: topM))
                            p.addLine(to: CGPoint(x: x, y: topM + chartH))
                        }
                        .stroke(
                            Color.primary.opacity(gridOpacity),
                            style: StrokeStyle(lineWidth: 0.5, dash: [4, 4])
                        )
                    }
                }

                // X axis tick labels
                if showXAxis && axisLabels {
                    ForEach(0...4, id: \.self) { i in
                        let xFrac = CGFloat(i) / 4
                        let val = effectiveXMin + (effectiveXMax - effectiveXMin) * Double(xFrac)
                        let x = leftM + chartW * xFrac
                        Text(formattedValue(val))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .center)
                            .position(x: x, y: topM + chartH + botM / 2)
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

                // Dumbbell rows
                VStack(alignment: .leading, spacing: CGFloat(itemSpacing)) {
                    ForEach(sorted) { item in
                        dumbbellRow(item: item, rowH: rowH, chartW: chartW, leftM: leftM)
                    }
                }
                .offset(x: 0, y: startY)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sorted.map { $0.startValue + $0.endValue })
            }
        }
    }

    @ViewBuilder
    func dumbbellRow(item: DumbbellDataItem, rowH: CGFloat, chartW: CGFloat, leftM: CGFloat) -> some View {
        let startRatio = xRatio(for: item.startValue)
        let endRatio = xRatio(for: item.endValue)
        let startX = chartW * startRatio
        let endX = chartW * endRatio
        let dotR = CGFloat(dotSize) / 2
        let isHighlighted = highlightedID == item.id
        let isDimmed = hoverHighlight && highlightedID != nil && !isHighlighted
        let isPositive = item.endValue >= item.startValue
        let lineColor: Color = diffHighlight
            ? (isPositive ? Color.green.opacity(lineOpacity) : Color.red.opacity(lineOpacity))
            : item.color.opacity(lineOpacity)

        HStack(spacing: 0) {

            // Category label zone (always occupies leftM width)
            if axisLabels {
                Text(item.label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: leftM - 6, alignment: .trailing)
                    .padding(.trailing, 6)
            } else {
                Color.clear.frame(width: leftM)
            }

            // Dumbbell zone
            ZStack(alignment: .leading) {
                Color.clear.frame(width: chartW, height: rowH)

                // Connecting line
                Path { p in
                    p.move(to: CGPoint(x: startX, y: rowH / 2))
                    p.addLine(to: CGPoint(x: endX, y: rowH / 2))
                }
                .stroke(lineColor, style: StrokeStyle(
                    lineWidth: CGFloat(lineThickness),
                    lineCap: .round,
                    dash: lineDashed ? [6, 4] : []
                ))

                // Diff label (above midpoint)
                if valueLabelOn && labelType == .diff {
                    let midX = (startX + endX) / 2
                    Text(formattedDiff(item))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(isPositive ? Color.green : Color.red)
                        .frame(width: 40, alignment: .center)
                        .offset(x: midX - 20, y: rowH / 2 - dotR - 13)
                }

                // Start dot
                dotView(color: item.color)
                    .frame(width: CGFloat(dotSize), height: CGFloat(dotSize))
                    .offset(x: startX - dotR, y: (rowH - CGFloat(dotSize)) / 2)
                    .scaleEffect(isHighlighted ? 1.25 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)

                // Start value label (above dot)
                if valueLabelOn && (labelType == .start || labelType == .both) {
                    Text(formattedValue(item.startValue))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, alignment: .center)
                        .offset(x: startX - 16, y: rowH / 2 - dotR - 13)
                }

                // End dot
                dotView(color: item.color.opacity(0.7))
                    .frame(width: CGFloat(dotSize), height: CGFloat(dotSize))
                    .offset(x: endX - dotR, y: (rowH - CGFloat(dotSize)) / 2)
                    .scaleEffect(isHighlighted ? 1.25 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)

                // End value label (above dot)
                if valueLabelOn && (labelType == .end || labelType == .both) {
                    Text(formattedValue(item.endValue))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .frame(width: 32, alignment: .center)
                        .offset(x: endX - 16, y: rowH / 2 - dotR - 13)
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
        .frame(height: rowH)
    }

    @ViewBuilder
    func dotView(color: Color) -> some View {
        if dotShapeStyle == .circle {
            let shape = Circle()
            ZStack {
                if dotGradient {
                    shape.fill(LinearGradient(
                        colors: [color, color.opacity(0.5)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )).glassEffect(.clear, in: shape)
                } else {
                    shape.fill(color).glassEffect(.clear, in: shape)
                }
                shape.stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                shape.stroke(Color.white, lineWidth: 6)
                    .blur(radius: 3).opacity(0.3).clipShape(shape)
            }
        } else {
            let shape = RoundedRectangle(cornerRadius: 3, style: .continuous)
            ZStack {
                if dotGradient {
                    shape.fill(LinearGradient(
                        colors: [color, color.opacity(0.5)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )).glassEffect(.clear, in: shape)
                } else {
                    shape.fill(color).glassEffect(.clear, in: shape)
                }
                shape.stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                shape.stroke(Color.white, lineWidth: 6)
                    .blur(radius: 3).opacity(0.3).clipShape(shape)
            }
        }
    }

    // MARK: - Settings: Geometry

    var geometrySettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Dot Size")
                Slider(value: $dotSize, in: 8...32, step: 1)
                Text("\(Int(dotSize))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Line W")
                Slider(value: $lineThickness, in: 1...12, step: 0.5)
                Text(String(format: "%.1fpt", lineThickness))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Spacing")
                Slider(value: $itemSpacing, in: 0...48, step: 2)
                Text("\(Int(itemSpacing))pt")
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
                Text("Category labels").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
                Text("Auto scale X axis").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if !autoScale {
                HStack(spacing: 10) {
                    settingsLabel("X Min")
                    TextField("0", value: $xAxisMin, format: .number)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity)
                }
                HStack(spacing: 10) {
                    settingsLabel("X Max")
                    TextField("100", value: $xAxisMax, format: .number)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numberPad)
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

    // MARK: - Settings: Connection

    var connectionSettingsView: some View {
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
                settingsLabel("Opacity")
                Slider(value: $lineOpacity, in: 0...1, step: 0.05)
                Text("\(Int(lineOpacity * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Dot Styling

    var dotSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Shape")
                HStack(spacing: 4) {
                    ForEach(DotShapeStyle.allCases, id: \.self) { s in
                        pillButton(s.rawValue, isSelected: dotShapeStyle == s) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { dotShapeStyle = s }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Gradient")
                Toggle("", isOn: $dotGradient).labelsHidden().scaleEffect(0.8)
                Text("Gradient fill").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Shadow")
                Toggle("", isOn: $dotShadow).labelsHidden().scaleEffect(0.8)
                Text("Drop shadow").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
        }
    }

    // MARK: - Settings: Difference Highlight

    var diffSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Diff Color")
                Toggle("", isOn: $diffHighlight).labelsHidden().scaleEffect(0.8)
                Text("Color line by direction").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if diffHighlight || (valueLabelOn && labelType == .diff) {
                HStack(spacing: 10) {
                    settingsLabel("Diff Type")
                    HStack(spacing: 4) {
                        ForEach(DiffType.allCases, id: \.self) { t in
                            pillButton(t.rawValue, isSelected: diffType == t) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { diffType = t }
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Settings: Interaction

    var interactionSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Highlight")
                Toggle("", isOn: $hoverHighlight).labelsHidden().scaleEffect(0.8)
                Text("Tap to highlight row").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
            Text("Sorts by end − start value")
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
    func itemRow(index: Int, item: DumbbellDataItem) -> some View {
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

            // Start value field
            VStack(alignment: .trailing, spacing: 1) {
                Text("start")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
                if editingID == item.id && editingField == .start {
                    TextField("0", text: $editingText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(width: 42)
                        .onChange(of: editingText) { _, val in
                            if let v = Double(val) { items[index].startValue = max(0, v) }
                        }
                } else {
                    Button {
                        editingID = item.id
                        editingField = .start
                        editingText = "\(Int(item.startValue))"
                    } label: {
                        Text("\(Int(item.startValue))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .underline(color: .primary.opacity(0.2))
                    }
                    .foregroundStyle(.primary)
                }
            }
            .frame(width: 42, alignment: .trailing)

            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

            // End value field
            VStack(alignment: .trailing, spacing: 1) {
                Text("end")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
                if editingID == item.id && editingField == .end {
                    TextField("0", text: $editingText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(width: 42)
                        .onChange(of: editingText) { _, val in
                            if let v = Double(val) { items[index].endValue = max(0, v) }
                        }
                } else {
                    Button {
                        editingID = item.id
                        editingField = .end
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
            items.append(DumbbellDataItem(
                label: "Item \(items.count + 1)",
                startValue: 20,
                endValue: 60,
                color: Self.colorPalette[colorIdx]
            ))
        }
    }
}

#Preview {
    ScrollView {
        DumbbellCard(
            title: "Dumbbell Chart",
            categories: ["Dumbbell"],
            items: [
                DumbbellDataItem(label: "Design",  startValue: 42, endValue: 78, color: AnalyticsCard.colorPalette[0]),
                DumbbellDataItem(label: "Dev",     startValue: 55, endValue: 88, color: AnalyticsCard.colorPalette[1]),
                DumbbellDataItem(label: "QA",      startValue: 30, endValue: 52, color: AnalyticsCard.colorPalette[2]),
                DumbbellDataItem(label: "DevOps",  startValue: 60, endValue: 45, color: AnalyticsCard.colorPalette[3]),
                DumbbellDataItem(label: "PM",      startValue: 25, endValue: 70, color: AnalyticsCard.colorPalette[4]),
            ]
        )
        .padding(.top, 20)
    }
}
