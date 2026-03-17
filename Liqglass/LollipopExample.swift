//
//  LollipopExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Lollipop Card

struct LollipopCard: View {

    let title: String
    let categories: [String]
    @State private var items: [AnalyticsDataItem]
    @State private var isExpanded = false
    @State private var highlightedID: UUID? = nil
    @State private var editingID: UUID? = nil
    @State private var editingText = ""

    // Chart Geometry
    @State private var stemWidth: Double = 2
    @State private var dotSize: Double = 14
    @State private var itemSpacing: Double = 12
    @State private var chartPadding: Double = 12

    // Axis Controls
    @State private var showXAxis: Bool = true
    @State private var showYAxis: Bool = true
    @State private var axisLabels: Bool = true
    @State private var axisGrid: Bool = true
    @State private var gridOpacity: Double = 0.25

    // Value Scaling
    @State private var autoScale: Bool = true
    @State private var axisMin: Double = 0
    @State private var axisMax: Double = 100
    @State private var valueFormat: ValueFormat = .number

    // Orientation
    @State private var orientation: Orientation = .horizontal

    // Dot Styling
    @State private var dotShape: DotShape = .circle
    @State private var dotFill: Bool = true
    @State private var dotStroke: Bool = true
    @State private var gradientFill: Bool = false
    @State private var shadowEnabled: Bool = true
    @State private var dotOpacity: Double = 0.85

    // Stem Styling
    @State private var stemDashed: Bool = false
    @State private var stemAlignment: StemAlignment = .center

    // Labels
    @State private var valueLabelOn: Bool = true
    @State private var labelPosition: LabelPosition = .end
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
    enum Orientation: String, CaseIterable { case horizontal = "Horizontal", vertical = "Vertical" }
    enum DotShape: String, CaseIterable { case circle = "Circle", square = "Square" }
    enum StemAlignment: String, CaseIterable { case center = "Center", offset = "Offset" }
    enum LabelPosition: String, CaseIterable { case end = "End", nearDot = "Near Dot", hidden = "Hidden" }
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

    var effectiveMax: Double {
        autoScale ? (items.map { $0.percentage }.max() ?? 100) * 1.2 : axisMax
    }

    var effectiveMin: Double { autoScale ? 0 : axisMin }

    func valueRatio(for value: Double) -> CGFloat {
        let range = effectiveMax - effectiveMin
        guard range > 0 else { return 0 }
        return CGFloat(max(0, min(1, (value - effectiveMin) / range)))
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
                    orientationSettingsView
                    dotSettingsView
                    stemSettingsView
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

    @ViewBuilder
    var chartView: some View {
        if orientation == .horizontal {
            horizontalChartView
        } else {
            verticalChartView
        }
    }

    // MARK: Horizontal

    var horizontalChartView: some View {
        GeometryReader { geo in
            let sorted = sortedItems
            let leftM: CGFloat = categoryLabelOn ? 68 : 6
            let rightM: CGFloat = CGFloat(chartPadding) + CGFloat(dotSize) / 2 + (valueLabelOn && labelPosition == .end ? 32 : 0)
            let topM: CGFloat = CGFloat(dotSize) / 2 + 2
            let botM: CGFloat = (showXAxis && axisLabels) ? 22 : (showXAxis ? 10 : 4)
            let chartW = geo.size.width - leftM - rightM
            let chartH = geo.size.height - topM - botM

            let n = max(1, sorted.count)
            let gap = CGFloat(itemSpacing) * CGFloat(max(0, n - 1))
            let rowH = max(CGFloat(dotSize) + 4, (chartH - gap) / CGFloat(n))
            let totalH = rowH * CGFloat(n) + gap
            let startY = topM + max(0, (chartH - totalH) / 2)

            ZStack(alignment: .topLeading) {
                // Grid lines
                if axisGrid {
                    ForEach(0...4, id: \.self) { i in
                        let x = leftM + chartW * CGFloat(i) / 4
                        Path { p in
                            p.move(to: CGPoint(x: x, y: topM))
                            p.addLine(to: CGPoint(x: x, y: topM + chartH))
                        }
                        .stroke(Color.primary.opacity(gridOpacity), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    }
                }

                // X tick labels
                if showXAxis && axisLabels {
                    ForEach(0...4, id: \.self) { i in
                        let xFrac = CGFloat(i) / 4
                        let val = effectiveMin + (effectiveMax - effectiveMin) * Double(xFrac)
                        let x = leftM + chartW * xFrac
                        Text(formattedValue(val))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .center)
                            .position(x: x, y: topM + chartH + botM / 2)
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

                // Lollipop rows
                VStack(alignment: .leading, spacing: CGFloat(itemSpacing)) {
                    ForEach(sorted) { item in
                        horizontalLollipop(item: item, rowH: rowH, chartW: chartW, leftM: leftM)
                    }
                }
                .offset(x: 0, y: startY)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sorted.map { $0.percentage })
            }
        }
    }

    @ViewBuilder
    func horizontalLollipop(item: AnalyticsDataItem, rowH: CGFloat, chartW: CGFloat, leftM: CGFloat) -> some View {
        let ratio = valueRatio(for: item.percentage)
        let dotX = chartW * ratio
        let dotR = CGFloat(dotSize) / 2
        let isHighlighted = highlightedID == item.id
        let isDimmed = hoverHighlight && highlightedID != nil && !isHighlighted

        let stemY: CGFloat = {
            switch stemAlignment {
            case .center: return rowH / 2
            case .offset: return rowH * 0.65
            }
        }()

        HStack(spacing: 0) {
            if categoryLabelOn {
                Text(item.label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: leftM - 6, alignment: .trailing)
                    .padding(.trailing, 6)
            } else {
                Color.clear.frame(width: leftM)
            }

            ZStack(alignment: .leading) {
                Color.clear.frame(width: chartW, height: rowH)

                // Stem
                Path { p in
                    p.move(to: CGPoint(x: 0, y: stemY))
                    p.addLine(to: CGPoint(x: dotX, y: stemY))
                }
                .stroke(
                    item.color.opacity(dotOpacity * 0.7),
                    style: StrokeStyle(lineWidth: CGFloat(stemWidth), lineCap: .round, dash: stemDashed ? [5, 4] : [])
                )

                // Dot
                dotView(color: item.color)
                    .frame(width: CGFloat(dotSize), height: CGFloat(dotSize))
                    .offset(x: dotX - dotR, y: stemY - dotR)
                    .scaleEffect(isHighlighted ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)

                // Value label
                if valueLabelOn && labelPosition != .hidden {
                    let labelX: CGFloat = labelPosition == .end ? dotX + dotR + 4 : dotX - dotR - 4
                    let anchor: Alignment = labelPosition == .end ? .leading : .trailing
                    Text(formattedValue(item.percentage))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .frame(width: 30, alignment: anchor)
                        .offset(x: labelX - (anchor == .leading ? 0 : 30), y: stemY - 7)
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

    // MARK: Vertical

    var verticalChartView: some View {
        GeometryReader { geo in
            let sorted = sortedItems
            let leftM: CGFloat = (showYAxis && axisLabels) ? 34 : 4
            let rightM: CGFloat = 4
            let topM: CGFloat = CGFloat(dotSize) / 2 + (valueLabelOn && labelPosition == .end ? 18 : 4)
            let botM: CGFloat = categoryLabelOn ? 28 : CGFloat(dotSize) / 2 + 4
            let chartW = geo.size.width - leftM - rightM
            let chartH = geo.size.height - topM - botM

            let n = max(1, sorted.count)
            let gap = CGFloat(itemSpacing) * CGFloat(max(0, n - 1))
            let colW = max(CGFloat(dotSize) + 4, (chartW - gap) / CGFloat(n))
            let totalW = colW * CGFloat(n) + gap
            let startX = leftM + max(0, (chartW - totalW) / 2)

            ZStack(alignment: .topLeading) {
                // Horizontal grid lines
                if axisGrid {
                    ForEach(0...4, id: \.self) { i in
                        let y = topM + chartH * (1 - CGFloat(i) / 4)
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
                        let val = effectiveMin + (effectiveMax - effectiveMin) * Double(yFrac)
                        let y = topM + chartH * (1 - yFrac)
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

                // Lollipop columns
                HStack(alignment: .bottom, spacing: CGFloat(itemSpacing)) {
                    ForEach(sorted) { item in
                        verticalLollipop(item: item, colW: colW, chartH: chartH, topM: topM, botM: botM)
                    }
                }
                .offset(x: startX, y: 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sorted.map { $0.percentage })
            }
        }
    }

    @ViewBuilder
    func verticalLollipop(item: AnalyticsDataItem, colW: CGFloat, chartH: CGFloat, topM: CGFloat, botM: CGFloat) -> some View {
        let ratio = valueRatio(for: item.percentage)
        let stemH = chartH * ratio
        let dotR = CGFloat(dotSize) / 2
        let isHighlighted = highlightedID == item.id
        let isDimmed = hoverHighlight && highlightedID != nil && !isHighlighted

        let stemX: CGFloat = {
            switch stemAlignment {
            case .center: return colW / 2
            case .offset: return colW * 0.65
            }
        }()

        VStack(spacing: 0) {
            // Top padding + value label zone
            ZStack {
                Color.clear.frame(height: topM)
                if valueLabelOn && labelPosition == .end {
                    Text(formattedValue(item.percentage))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .offset(y: topM - (chartH * (1 - ratio)) - dotR - 14)
                }
            }
            .frame(height: topM)

            // Chart area
            ZStack(alignment: .bottom) {
                Color.clear.frame(width: colW, height: chartH)

                ZStack(alignment: .bottom) {
                    // Stem
                    Path { p in
                        p.move(to: CGPoint(x: stemX, y: chartH))
                        p.addLine(to: CGPoint(x: stemX, y: chartH - stemH))
                    }
                    .stroke(
                        item.color.opacity(dotOpacity * 0.7),
                        style: StrokeStyle(lineWidth: CGFloat(stemWidth), lineCap: .round, dash: stemDashed ? [5, 4] : [])
                    )

                    // Dot
                    dotView(color: item.color)
                        .frame(width: CGFloat(dotSize), height: CGFloat(dotSize))
                        .offset(x: stemX - dotR - colW / 2 + dotR, y: -(stemH - dotR))
                        .scaleEffect(isHighlighted ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)

                    // Near-dot label
                    if valueLabelOn && labelPosition == .nearDot {
                        Text(formattedValue(item.percentage))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .offset(x: stemX - colW / 2 + 2, y: -(stemH + dotR + 10))
                    }
                }
            }

            // Category label
            if categoryLabelOn {
                Text(item.label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: colW)
                    .padding(.top, 6)
            }
        }
        .frame(width: colW)
        .opacity(isDimmed ? 0.4 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDimmed)
        .onTapGesture {
            if hoverHighlight {
                withAnimation { highlightedID = (highlightedID == item.id) ? nil : item.id }
            }
        }
    }

    // MARK: - Dot View

    @ViewBuilder
    func dotView(color: Color) -> some View {
        if dotShape == .circle {
            let shape = Circle()
            ZStack {
                if dotFill {
                    if gradientFill {
                        shape.fill(LinearGradient(
                            colors: [color.opacity(dotOpacity), color.opacity(dotOpacity * 0.5)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )).glassEffect(.clear, in: shape)
                    } else {
                        shape.fill(color.opacity(dotOpacity)).glassEffect(.clear, in: shape)
                    }
                }
                if dotStroke {
                    shape.stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    shape.stroke(Color.white, lineWidth: 6)
                        .blur(radius: 3).opacity(0.3).clipShape(shape)
                }
            }
        } else {
            let shape = RoundedRectangle(cornerRadius: 3, style: .continuous)
            ZStack {
                if dotFill {
                    if gradientFill {
                        shape.fill(LinearGradient(
                            colors: [color.opacity(dotOpacity), color.opacity(dotOpacity * 0.5)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )).glassEffect(.clear, in: shape)
                    } else {
                        shape.fill(color.opacity(dotOpacity)).glassEffect(.clear, in: shape)
                    }
                }
                if dotStroke {
                    shape.stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    shape.stroke(Color.white, lineWidth: 6)
                        .blur(radius: 3).opacity(0.3).clipShape(shape)
                }
            }
        }
    }

    // MARK: - Settings: Geometry

    var geometrySettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Stem W")
                Slider(value: $stemWidth, in: 1...10, step: 0.5)
                Text(String(format: "%.1fpt", stemWidth))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Dot Size")
                Slider(value: $dotSize, in: 6...30, step: 1)
                Text("\(Int(dotSize))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Spacing")
                Slider(value: $itemSpacing, in: 0...40, step: 2)
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
                Text("Auto scale axis").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if !autoScale {
                HStack(spacing: 10) {
                    settingsLabel("Min")
                    TextField("0", value: $axisMin, format: .number)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity)
                }
                HStack(spacing: 10) {
                    settingsLabel("Max")
                    TextField("100", value: $axisMax, format: .number)
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

    // MARK: - Settings: Orientation

    var orientationSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Orient")
                HStack(spacing: 4) {
                    ForEach(Orientation.allCases, id: \.self) { o in
                        pillButton(o.rawValue, isSelected: orientation == o) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { orientation = o }
                        }
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Settings: Dot Styling

    var dotSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Shape")
                HStack(spacing: 4) {
                    ForEach(DotShape.allCases, id: \.self) { s in
                        pillButton(s.rawValue, isSelected: dotShape == s) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { dotShape = s }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Fill")
                Toggle("", isOn: $dotFill).labelsHidden().scaleEffect(0.8)
                Text("Filled dot").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Stroke")
                Toggle("", isOn: $dotStroke).labelsHidden().scaleEffect(0.8)
                Text("Glass stroke").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
            HStack(spacing: 10) {
                settingsLabel("Opacity")
                Slider(value: $dotOpacity, in: 0...1, step: 0.05)
                Text("\(Int(dotOpacity * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Stem

    var stemSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Style")
                HStack(spacing: 4) {
                    pillButton("Solid", isSelected: !stemDashed) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { stemDashed = false }
                    }
                    pillButton("Dashed", isSelected: stemDashed) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { stemDashed = true }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Align")
                HStack(spacing: 4) {
                    ForEach(StemAlignment.allCases, id: \.self) { a in
                        pillButton(a.rawValue, isSelected: stemAlignment == a) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { stemAlignment = a }
                        }
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
                Text("Tap to highlight").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
                        if let v = Double(val) { items[index].percentage = max(0, v) }
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
        LollipopCard(
            title: "Lollipop Chart",
            categories: ["Lollipop"],
            items: [
                AnalyticsDataItem(label: "Design",  percentage: 82, color: AnalyticsCard.colorPalette[0]),
                AnalyticsDataItem(label: "Dev",     percentage: 67, color: AnalyticsCard.colorPalette[1]),
                AnalyticsDataItem(label: "QA",      percentage: 45, color: AnalyticsCard.colorPalette[2]),
                AnalyticsDataItem(label: "DevOps",  percentage: 58, color: AnalyticsCard.colorPalette[3]),
                AnalyticsDataItem(label: "PM",      percentage: 39, color: AnalyticsCard.colorPalette[4]),
            ]
        )
        .padding(.top, 20)
    }
}
