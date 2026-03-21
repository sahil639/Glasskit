//
//  TreemapChartExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Data Model

struct TreemapItem: Identifiable {
    let id = UUID()
    var label: String
    var value: Double
    var color: Color
    var children: [TreemapItem]

    var isLeaf: Bool { children.isEmpty }

    var totalValue: Double {
        isLeaf ? value : children.map { $0.totalValue }.reduce(0, +)
    }
}

// MARK: - Layout Result

struct TreemapRect {
    var id: UUID
    var label: String
    var value: Double
    var color: Color
    var rect: CGRect
    var depth: Int
    var isLeaf: Bool
}

// MARK: - Treemap Chart Card

struct TreemapChartCard: View {

    let title: String
    let categories: [String]
    @State private var items: [TreemapItem]
    @State private var isExpanded = false
    @State private var appeared = false
    @State private var highlightedID: UUID? = nil
    @State private var drillStack: [TreemapItem] = []  // drill-down stack

    // Zoom & Pan
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragTranslation: CGSize = .zero

    // Layout
    @State private var layoutAlgorithm: TreemapLayout = .squarified
    @State private var showNested: Bool = true
    @State private var nestPadding: Double = 6

    // Styling
    @State private var cornerRadius: Double = 8
    @State private var showLabels: Bool = true
    @State private var showValues: Bool = true
    @State private var labelThreshold: Double = 40
    @State private var borderWidth: Double = 0.5
    @State private var glassEffect2: Bool = true
    @State private var gradientFill: Bool = true
    @State private var fillOpacity: Double = 0.85
    @State private var shadowEnabled: Bool = true

    // Interaction
    @State private var drillDownEnabled: Bool = true
    @State private var zoomPanEnabled: Bool = false
    @State private var animateOnLoad: Bool = true
    @State private var animationDuration: Double = 0.6

    // Enums
    enum TreemapLayout: String, CaseIterable { case squarified = "Squarified", sliceDice = "Slice/Dice", binary = "Binary" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Init

    init(title: String, categories: [String], items: [TreemapItem]) {
        self.title = title
        self.categories = categories
        self._items = State(initialValue: items)
    }

    // MARK: - Computed

    var currentItems: [TreemapItem] {
        drillStack.last?.children ?? items
    }

    var breadcrumb: [String] {
        ["Root"] + drillStack.map { $0.label }
    }

    // MARK: - Layout Algorithms

    // Squarified treemap — Bruls et al.
    func squarifiedLayout(items: [TreemapItem], rect: CGRect) -> [TreemapRect] {
        let total = items.map { $0.totalValue }.reduce(0, +)
        guard total > 0, rect.width > 0, rect.height > 0 else { return [] }

        var result: [TreemapRect] = []
        var remaining = items.sorted { $0.totalValue > $1.totalValue }
        var curRect = rect

        func aspect(_ w: Double, _ h: Double) -> Double { max(w / h, h / w) }

        func worstAspect(row: [TreemapItem], w: Double, total: Double) -> Double {
            let s = row.map { $0.totalValue }.reduce(0, +)
            let sRel = s / total
            let minV = row.map { $0.totalValue / total }.min() ?? 0
            let maxV = row.map { $0.totalValue / total }.max() ?? 0
            guard sRel > 0, minV > 0 else { return Double.infinity }
            return max(
                (w * w * maxV) / (sRel * sRel),
                (sRel * sRel) / (w * w * minV)
            )
        }

        while !remaining.isEmpty {
            let shortSide = Double(min(curRect.width, curRect.height))
            var row: [TreemapItem] = []
            var rowTotal = 0.0
            let remTotal = remaining.map { $0.totalValue }.reduce(0, +)

            for item in remaining {
                let newRow = row + [item]
                let newTotal = rowTotal + item.totalValue
                let newWorst = worstAspect(row: newRow, w: shortSide, total: remTotal)
                let oldWorst = row.isEmpty ? Double.infinity : worstAspect(row: row, w: shortSide, total: remTotal)
                if newWorst <= oldWorst {
                    row.append(item)
                    rowTotal += item.totalValue
                } else {
                    break
                }
            }

            if row.isEmpty {
                row = [remaining[0]]
                rowTotal = remaining[0].totalValue
            }

            // Layout the row
            let rowFrac = remTotal > 0 ? rowTotal / remTotal : 1
            let isHorizontal = curRect.width >= curRect.height
            let rowW = isHorizontal ? curRect.width * CGFloat(rowFrac) : curRect.width
            let rowH = isHorizontal ? curRect.height : curRect.height * CGFloat(rowFrac)
            var x = curRect.minX, y = curRect.minY

            for item in row {
                let itemFrac = rowTotal > 0 ? item.totalValue / rowTotal : 0
                let itemW = isHorizontal ? rowW : curRect.width * CGFloat(itemFrac)
                let itemH = isHorizontal ? curRect.height * CGFloat(itemFrac) : rowH
                let itemRect = CGRect(x: x, y: y, width: itemW, height: itemH)

                if !item.isLeaf && showNested {
                    let childRects = squarifiedLayout(items: item.children,
                                                      rect: itemRect.insetBy(dx: CGFloat(nestPadding), dy: CGFloat(nestPadding)))
                    result.append(contentsOf: childRects)
                }
                result.append(TreemapRect(id: item.id, label: item.label, value: item.totalValue,
                                          color: item.color, rect: itemRect, depth: drillStack.count, isLeaf: item.isLeaf))

                if isHorizontal { y += itemH } else { x += itemW }
            }

            // Remove placed items and shrink rect
            remaining.removeFirst(row.count)
            if isHorizontal {
                curRect = CGRect(x: curRect.minX + rowW, y: curRect.minY, width: curRect.width - rowW, height: curRect.height)
            } else {
                curRect = CGRect(x: curRect.minX, y: curRect.minY + rowH, width: curRect.width, height: curRect.height - rowH)
            }
        }
        return result
    }

    func sliceDiceLayout(items: [TreemapItem], rect: CGRect, depth: Int = 0) -> [TreemapRect] {
        let total = items.map { $0.totalValue }.reduce(0, +)
        guard total > 0 else { return [] }
        var result: [TreemapRect] = []
        let horizontal = depth % 2 == 0
        var offset: CGFloat = 0

        for item in items {
            let frac = CGFloat(item.totalValue / total)
            let itemRect: CGRect
            if horizontal {
                itemRect = CGRect(x: rect.minX + offset, y: rect.minY, width: rect.width * frac, height: rect.height)
                offset += rect.width * frac
            } else {
                itemRect = CGRect(x: rect.minX, y: rect.minY + offset, width: rect.width, height: rect.height * frac)
                offset += rect.height * frac
            }
            if !item.isLeaf && showNested {
                let childRects = sliceDiceLayout(items: item.children,
                                                 rect: itemRect.insetBy(dx: CGFloat(nestPadding), dy: CGFloat(nestPadding)),
                                                 depth: depth + 1)
                result.append(contentsOf: childRects)
            }
            result.append(TreemapRect(id: item.id, label: item.label, value: item.totalValue,
                                      color: item.color, rect: itemRect, depth: drillStack.count, isLeaf: item.isLeaf))
        }
        return result
    }

    func binaryLayout(items: [TreemapItem], rect: CGRect) -> [TreemapRect] {
        guard !items.isEmpty else { return [] }
        if items.count == 1 {
            let item = items[0]
            var result: [TreemapRect] = []
            if !item.isLeaf && showNested {
                result.append(contentsOf: binaryLayout(items: item.children,
                                                        rect: rect.insetBy(dx: CGFloat(nestPadding), dy: CGFloat(nestPadding))))
            }
            result.append(TreemapRect(id: item.id, label: item.label, value: item.totalValue,
                                      color: item.color, rect: rect, depth: drillStack.count, isLeaf: item.isLeaf))
            return result
        }
        let total = items.map { $0.totalValue }.reduce(0, +)
        var cumSum = 0.0
        var splitIdx = 0
        for (i, item) in items.enumerated() {
            cumSum += item.totalValue
            if cumSum >= total / 2 {
                splitIdx = i
                break
            }
        }
        let leftItems  = Array(items[0...splitIdx])
        let rightItems = Array(items[(splitIdx + 1)...])
        let splitFrac = CGFloat(leftItems.map { $0.totalValue }.reduce(0, +) / total)
        let (rectA, rectB): (CGRect, CGRect)
        if rect.width >= rect.height {
            let w = rect.width * splitFrac
            rectA = CGRect(x: rect.minX, y: rect.minY, width: w, height: rect.height)
            rectB = CGRect(x: rect.minX + w, y: rect.minY, width: rect.width - w, height: rect.height)
        } else {
            let h = rect.height * splitFrac
            rectA = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: h)
            rectB = CGRect(x: rect.minX, y: rect.minY + h, width: rect.width, height: rect.height - h)
        }
        return binaryLayout(items: leftItems, rect: rectA) + (rightItems.isEmpty ? [] : binaryLayout(items: rightItems, rect: rectB))
    }

    func computeLayout(rect: CGRect) -> [TreemapRect] {
        let sorted = currentItems.sorted { $0.totalValue > $1.totalValue }
        let rects: [TreemapRect]
        switch layoutAlgorithm {
        case .squarified: rects = squarifiedLayout(items: sorted, rect: rect)
        case .sliceDice:  rects = sliceDiceLayout(items: sorted, rect: rect)
        case .binary:     rects = binaryLayout(items: sorted, rect: rect)
        }
        // Top-level items rendered last (on top)
        return rects.sorted { $0.depth < $1.depth || ($0.depth == $1.depth && !$0.isLeaf) }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            chartView
                .frame(height: 280)
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
                    layoutSettingsView
                    styleSettingsView
                    labelSettingsView
                    interactionSettingsView
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
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let allRects = computeLayout(rect: rect)

            ZStack(alignment: .topLeading) {

                // Breadcrumb
                if !drillStack.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(breadcrumb.enumerated()), id: \.offset) { i, crumb in
                            if i > 0 {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                            Button {
                                if i == 0 {
                                    withAnimation(.spring(response: 0.45)) { drillStack.removeAll() }
                                } else if i < drillStack.count {
                                    withAnimation(.spring(response: 0.45)) {
                                        drillStack.removeSubrange(i...)
                                    }
                                }
                            } label: {
                                Text(crumb)
                                    .font(.system(size: 11, weight: i == breadcrumb.count - 1 ? .semibold : .regular, design: .rounded))
                                    .foregroundStyle(i == breadcrumb.count - 1 ? Color.primary : Color.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                    .zIndex(10)
                }

                // Cells
                ForEach(allRects, id: \.id) { cell in
                    treemapCell(cell: cell)
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
        .clipped()
    }

    // MARK: - Treemap Cell

    @ViewBuilder
    func treemapCell(cell: TreemapRect) -> some View {
        let isHL = highlightedID == cell.id
        let col = cell.color
        let shape = RoundedRectangle(cornerRadius: CGFloat(cornerRadius), style: .continuous)
        let w = cell.rect.width, h = cell.rect.height
        let showLabel = showLabels && w > CGFloat(labelThreshold) && h > 28
        let showVal = showValues && w > CGFloat(labelThreshold) + 10 && h > 42

        ZStack {
            // Shadow
            if shadowEnabled && cell.isLeaf {
                shape.fill(col.opacity(0.15))
                    .blur(radius: 4)
                    .offset(y: 2)
                    .frame(width: w, height: h)
            }

            // Fill
            if gradientFill {
                shape.fill(
                    LinearGradient(
                        colors: [col.opacity(fillOpacity), col.opacity(fillOpacity * 0.6)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: w, height: h)
            } else {
                shape.fill(col.opacity(fillOpacity))
                    .frame(width: w, height: h)
            }

            if glassEffect2 && cell.isLeaf {
                shape
                    .fill(Color.clear)
                    .glassEffect(.clear, in: shape)
                    .frame(width: w, height: h)
            }

            // Border
            shape.stroke(Color.white.opacity(CGFloat(borderWidth) > 0 ? 0.35 : 0), lineWidth: CGFloat(borderWidth))
                .frame(width: w, height: h)

            // Inner glow
            shape.stroke(Color.white, lineWidth: 5)
                .blur(radius: 3)
                .opacity(isHL ? 0.45 : 0.18)
                .clipShape(shape)
                .frame(width: w, height: h)

            // Labels
            if showLabel || showVal {
                VStack(spacing: 2) {
                    if showLabel {
                        Text(cell.label)
                            .font(.system(size: min(14, max(9, w / 8)), weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.95))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    if showVal {
                        Text(cell.value == Double(Int(cell.value)) ? "\(Int(cell.value))" : String(format: "%.1f", cell.value))
                            .font(.system(size: min(12, max(8, w / 10)), weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.75))
                    }
                }
                .padding(6)
                .frame(width: w, height: h)
            }
        }
        .frame(width: w, height: h)
        .position(x: cell.rect.midX, y: cell.rect.midY)
        .scaleEffect(appeared ? 1.0 : 0.85)
        .opacity(appeared ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.75)
                .delay(animateOnLoad ? Double.random(in: 0...0.3) : 0),
            value: appeared
        )
        .onTapGesture {
            if drillDownEnabled, let match = findItem(id: cell.id, in: currentItems), !match.children.isEmpty {
                withAnimation(.spring(response: 0.45)) { drillStack.append(match) }
            }
            withAnimation(.spring(response: 0.3)) {
                highlightedID = highlightedID == cell.id ? nil : cell.id
            }
        }
    }

    func findItem(id: UUID, in list: [TreemapItem]) -> TreemapItem? {
        for item in list {
            if item.id == id { return item }
            if let found = findItem(id: id, in: item.children) { return found }
        }
        return nil
    }

    // MARK: - Settings Views

    @ViewBuilder
    var layoutSettingsView: some View {
        settingsSection("Layout") {
            HStack(spacing: 6) {
                ForEach(TreemapLayout.allCases, id: \.self) { l in
                    pillButton(l.rawValue, selected: layoutAlgorithm == l) { layoutAlgorithm = l }
                }
            }
            .padding(.horizontal, 20)
            Toggle(isOn: $showNested) { settingsLabel("Show Nested") }.padding(.horizontal, 20)
            if showNested {
                HStack {
                    settingsLabel("Nest Padding")
                    Slider(value: $nestPadding, in: 2...16)
                    Text("\(Int(nestPadding))pt")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    @ViewBuilder
    var styleSettingsView: some View {
        settingsSection("Style") {
            Toggle(isOn: $gradientFill) { settingsLabel("Gradient Fill") }.padding(.horizontal, 20)
            Toggle(isOn: $glassEffect2) { settingsLabel("Glass Effect") }.padding(.horizontal, 20)
            Toggle(isOn: $shadowEnabled) { settingsLabel("Shadow") }.padding(.horizontal, 20)
            HStack {
                settingsLabel("Corner Radius")
                Slider(value: $cornerRadius, in: 0...16)
                Text("\(Int(cornerRadius))pt")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
            HStack {
                settingsLabel("Fill Opacity")
                Slider(value: $fillOpacity, in: 0.3...1.0)
                Text(String(format: "%.0f%%", fillOpacity * 100))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
            HStack {
                settingsLabel("Border")
                Slider(value: $borderWidth, in: 0...2)
                Text(String(format: "%.1f", borderWidth))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }
        }
    }

    @ViewBuilder
    var labelSettingsView: some View {
        settingsSection("Labels") {
            Toggle(isOn: $showLabels) { settingsLabel("Show Names") }.padding(.horizontal, 20)
            Toggle(isOn: $showValues) { settingsLabel("Show Values") }.padding(.horizontal, 20)
            if showLabels || showValues {
                HStack {
                    settingsLabel("Min Cell Size")
                    Slider(value: $labelThreshold, in: 20...100)
                    Text("\(Int(labelThreshold))pt")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    @ViewBuilder
    var interactionSettingsView: some View {
        settingsSection("Interaction") {
            Toggle(isOn: $drillDownEnabled) { settingsLabel("Drill Down") }.padding(.horizontal, 20)
            Toggle(isOn: $zoomPanEnabled) { settingsLabel("Zoom & Pan") }.padding(.horizontal, 20)
            Toggle(isOn: $animateOnLoad) { settingsLabel("Animate on Load") }.padding(.horizontal, 20)
        }
    }

    // MARK: - Item List

    var itemListView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Items")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    let idx = items.count % TreemapChartCard.colorPalette.count
                    withAnimation(.spring(response: 0.4)) {
                        items.append(TreemapItem(
                            label: "Item \(items.count + 1)",
                            value: Double.random(in: 10...60),
                            color: TreemapChartCard.colorPalette[idx],
                            children: []
                        ))
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(TreemapChartCard.colorPalette[items.count % TreemapChartCard.colorPalette.count])
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                itemRow(i: i, item: item)
                if i < items.count - 1 {
                    Divider().padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    func itemRow(i: Int, item: TreemapItem) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(item.color)
                .frame(width: 10, height: 10)
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 3))

            Text(item.label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            if !item.children.isEmpty {
                Text("\(item.children.count) sub")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Slider(value: Binding(
                get: { item.value },
                set: { items[i].value = $0 }
            ), in: 1...200)
            .frame(width: 90)

            Text(item.value == Double(Int(item.value)) ? "\(Int(item.value))" : String(format: "%.1f", item.value))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(item.color)
                .frame(width: 32, alignment: .trailing)

            if items.count > 1 {
                Button {
                    withAnimation(.spring(response: 0.4)) { items.removeSubrange(i...i) }
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(.red.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
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
                .background(Capsule().fill(selected ? Color.primary.opacity(0.1) : Color.clear))
                .overlay(Capsule().stroke(selected ? Color.primary.opacity(0.2) : Color.clear, lineWidth: 0.5))
        }
    }
}
