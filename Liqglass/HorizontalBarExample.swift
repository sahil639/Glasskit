//
//  HorizontalBarExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Horizontal Bar Card

struct HorizontalBarCard: View {

    let title: String
    let categories: [String]
    @State private var items: [AnalyticsDataItem]
    @State private var isExpanded = false
    @State private var editingID: UUID? = nil
    @State private var editingText = ""
    @State private var highlightedID: UUID? = nil

    // Chart Geometry
    @State private var barHeight: Double = 28
    @State private var barSpacing: Double = 10
    @State private var chartPadding: Double = 12

    // Axis Controls
    @State private var showXAxis: Bool = true
    @State private var showYAxis: Bool = true
    @State private var axisLabels: Bool = true
    @State private var axisGrid: Bool = true
    @State private var gridOpacity: Double = 0.3

    // Value Scaling
    @State private var xAxisMin: Double = 0
    @State private var xAxisMax: Double = 100
    @State private var autoScale: Bool = true
    @State private var valueFormat: ValueFormat = .number

    // Bar Styling
    @State private var cornerRadius: Double = 0
    @State private var gradientFill: Bool = false
    @State private var shadowEnabled: Bool = true
    @State private var barOpacity: Double = 0.85

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
    enum LabelPosition: String, CaseIterable { case end = "End", inside = "Inside", hidden = "Hidden" }
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

    var effectiveXMax: Double {
        autoScale ? (items.map { $0.percentage }.max() ?? 100) * 1.15 : xAxisMax
    }

    var effectiveXMin: Double { autoScale ? 0 : xAxisMin }

    func barWidthRatio(for value: Double) -> CGFloat {
        let range = effectiveXMax - effectiveXMin
        guard range > 0 else { return 0 }
        return CGFloat(max(0, (value - effectiveXMin) / range))
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
                    axisSettingsView
                    scalingSettingsView
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
            let leftM: CGFloat = categoryLabelOn ? 68 : 6
            let rightM: CGFloat = (valueLabelOn && labelPosition == .end) ? 36 : CGFloat(chartPadding)
            let topM: CGFloat = 4
            let botM: CGFloat = (showXAxis && axisLabels) ? 20 : (showXAxis ? 10 : 4)
            let chartW = geo.size.width - leftM - rightM
            let chartH = geo.size.height - topM - botM

            let n = max(1, sorted.count)
            let gap = CGFloat(barSpacing) * CGFloat(max(0, n - 1))
            let bH = min(CGFloat(barHeight), max(6, (chartH - gap) / CGFloat(n)))
            let totalContentH = bH * CGFloat(n) + gap
            let startY = topM + max(0, (chartH - totalContentH) / 2)

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

                // X axis tick labels (bottom)
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

                // Bar rows
                VStack(alignment: .leading, spacing: CGFloat(barSpacing)) {
                    ForEach(sorted) { item in
                        barRow(item: item, bH: bH, chartW: chartW, leftM: leftM)
                    }
                }
                .offset(x: 0, y: startY)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sorted.map { $0.percentage })
            }
        }
    }

    @ViewBuilder
    func barRow(item: AnalyticsDataItem, bH: CGFloat, chartW: CGFloat, leftM: CGFloat) -> some View {
        let ratio = barWidthRatio(for: item.percentage)
        let barW = max(4, chartW * ratio)
        let barShape = RoundedRectangle(cornerRadius: CGFloat(cornerRadius), style: .continuous)
        let isHighlighted = highlightedID == item.id
        let isDimmed = hoverHighlight && highlightedID != nil && !isHighlighted

        HStack(spacing: 0) {

            // Category label zone (always occupies leftM width)
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

            // Bar zone — bar anchored to leading edge via ZStack(.leading)
            ZStack(alignment: .leading) {
                Color.clear.frame(width: chartW, height: bH)

                ZStack {
                    let grad = LinearGradient(
                        colors: [item.color.opacity(barOpacity), item.color.opacity(barOpacity * 0.55)],
                        startPoint: .leading, endPoint: .trailing
                    )
                    if gradientFill {
                        barShape.fill(grad).glassEffect(.clear, in: barShape)
                    } else {
                        barShape.fill(item.color.opacity(barOpacity)).glassEffect(.clear, in: barShape)
                    }
                    barShape.stroke(Color.white.opacity(0.25), lineWidth: 0.4)
                    barShape.stroke(Color.white, lineWidth: 8)
                        .blur(radius: 4).opacity(0.25).clipShape(barShape)

                    if valueLabelOn && labelPosition == .inside && barW > 36 {
                        HStack {
                            Spacer()
                            Text(formattedValue(item.percentage))
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.trailing, 6)
                        }
                    }
                }
                .frame(width: barW, height: bH)
                .scaleEffect(x: isHighlighted ? 1.02 : 1.0, y: isHighlighted ? 1.08 : 1.0, anchor: .leading)

                // Value label at end
                if valueLabelOn && labelPosition == .end {
                    Text(formattedValue(item.percentage))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .offset(x: barW + 4)
                }
            }
            .opacity(isDimmed ? 0.45 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: highlightedID)
            .onTapGesture {
                if hoverHighlight {
                    withAnimation { highlightedID = (highlightedID == item.id) ? nil : item.id }
                }
            }
        }
        .frame(height: bH)
    }

    // MARK: - Settings: Geometry

    var geometrySettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Bar H")
                Slider(value: $barHeight, in: 10...80, step: 2)
                Text("\(Int(barHeight))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Spacing")
                Slider(value: $barSpacing, in: 0...40, step: 1)
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
                    Text("Value labels off").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
        HorizontalBarCard(
            title: "Horizontal Bar Chart",
            categories: ["Bar Chart"],
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
