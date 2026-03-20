//
//  TreeDiagramExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Data Model

struct TreeNode: Identifiable {
    let id = UUID()
    var label: String
    var value: Double
    var color: Color
    var children: [TreeNode]
    var isCollapsed: Bool = false

    var isLeaf: Bool { children.isEmpty }

    var allDescendants: [TreeNode] {
        children.flatMap { [$0] + $0.allDescendants }
    }
}

// MARK: - Layout Result

private struct LayoutNode {
    var id: UUID
    var label: String
    var value: Double
    var color: Color
    var center: CGPoint
    var depth: Int
    var parentID: UUID?
    var isCollapsed: Bool
    var isLeaf: Bool
}

// MARK: - Tree Diagram Card

struct TreeDiagramCard: View {

    let title: String
    let categories: [String]
    @State private var root: TreeNode
    @State private var isExpanded = false
    @State private var appeared = false
    @State private var highlightedID: UUID? = nil

    // Zoom & Pan
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragTranslation: CGSize = .zero

    // Layout
    @State private var orientation: TreeOrientation = .topDown
    @State private var connectorStyle: TreeConnector = .curved
    @State private var nodeSize: Double = 36
    @State private var levelSpacing: Double = 70
    @State private var siblingSpacing: Double = 54

    // Node Styling
    @State private var showValues: Bool = true
    @State private var showLabels: Bool = true
    @State private var nodeShape: TreeNodeShape = .circle
    @State private var glassNodes: Bool = true
    @State private var shadowEnabled: Bool = true

    // Connector Styling
    @State private var connectorThickness: Double = 1.5
    @State private var connectorOpacity: Double = 0.45
    @State private var colorConnectors: Bool = false

    // Interaction
    @State private var collapseEnabled: Bool = true
    @State private var zoomPanEnabled: Bool = false
    @State private var animateOnLoad: Bool = true
    @State private var animationDuration: Double = 0.7

    // Enums
    enum TreeOrientation: String, CaseIterable { case topDown = "Top↓", leftRight = "Left→", radial = "Radial" }
    enum TreeConnector: String, CaseIterable { case straight = "Straight", curved = "Curved", orthogonal = "Ortho" }
    enum TreeNodeShape: String, CaseIterable { case circle = "Circle", square = "Square", diamond = "Diamond" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Init

    init(title: String, categories: [String], root: TreeNode) {
        self.title = title
        self.categories = categories
        self._root = State(initialValue: root)
    }

    // MARK: - Layout Engine

    func flatLayout(node: TreeNode, depth: Int, parentID: UUID?, xOffset: inout Double, maxDepth: Int) -> [LayoutNode] {
        guard !node.isCollapsed || depth == 0 else {
            return [LayoutNode(id: node.id, label: node.label, value: node.value, color: node.color,
                               center: .zero, depth: depth, parentID: parentID,
                               isCollapsed: node.isCollapsed, isLeaf: node.isLeaf)]
        }
        var result: [LayoutNode] = []
        if node.children.isEmpty || node.isCollapsed {
            let x = xOffset
            xOffset += siblingSpacing
            result.append(LayoutNode(id: node.id, label: node.label, value: node.value, color: node.color,
                                     center: CGPoint(x: x, y: Double(depth) * levelSpacing),
                                     depth: depth, parentID: parentID,
                                     isCollapsed: node.isCollapsed, isLeaf: node.isLeaf))
        } else {
            let startX = xOffset
            var childLayouts: [[LayoutNode]] = []
            for child in node.children {
                let childResult = flatLayout(node: child, depth: depth + 1, parentID: node.id, xOffset: &xOffset, maxDepth: maxDepth)
                childLayouts.append(childResult)
            }
            let endX = xOffset - siblingSpacing
            let midX = (startX + endX) / 2
            result.append(LayoutNode(id: node.id, label: node.label, value: node.value, color: node.color,
                                     center: CGPoint(x: midX, y: Double(depth) * levelSpacing),
                                     depth: depth, parentID: parentID,
                                     isCollapsed: node.isCollapsed, isLeaf: node.isLeaf))
            result.append(contentsOf: childLayouts.flatMap { $0 })
        }
        return result
    }

    func computeLayout(chartW: CGFloat, chartH: CGFloat) -> [LayoutNode] {
        var xOffset = 0.0
        var nodes = flatLayout(node: root, depth: 0, parentID: nil, xOffset: &xOffset, maxDepth: 8)
        guard !nodes.isEmpty else { return [] }

        if orientation == .radial {
            return radialLayout(nodes: &nodes, chartW: chartW, chartH: chartH)
        }

        // Normalize positions
        let minX = nodes.map { $0.center.x }.min() ?? 0
        let maxX = nodes.map { $0.center.x }.max() ?? 1
        let minY = nodes.map { $0.center.y }.min() ?? 0
        let maxY = nodes.map { $0.center.y }.max() ?? 1
        let xRange = max(maxX - minX, 1)
        let yRange = max(maxY - minY, 1)

        let pad: CGFloat = 40
        let drawW = chartW - pad * 2
        let drawH = chartH - pad * 2

        return nodes.map { n in
            var copy = n
            if orientation == .topDown {
                copy.center = CGPoint(
                    x: pad + CGFloat((n.center.x - minX) / xRange) * drawW,
                    y: pad + CGFloat((n.center.y - minY) / yRange) * drawH
                )
            } else { // leftRight
                copy.center = CGPoint(
                    x: pad + CGFloat((n.center.y - minY) / yRange) * drawW,
                    y: pad + CGFloat((n.center.x - minX) / xRange) * drawH
                )
            }
            return copy
        }
    }

    func radialLayout(nodes: inout [LayoutNode], chartW: CGFloat, chartH: CGFloat) -> [LayoutNode] {
        let cx = chartW / 2, cy = chartH / 2
        let depthCount = (nodes.map { $0.depth }.max() ?? 0) + 1
        let radii = (0..<depthCount).map { CGFloat($0) * CGFloat(levelSpacing) * 0.9 + 30 }
        var depthGroups: [Int: [LayoutNode]] = [:]
        for n in nodes { depthGroups[n.depth, default: []].append(n) }

        return nodes.map { n in
            var copy = n
            let group = depthGroups[n.depth] ?? [n]
            let idx = group.firstIndex { $0.id == n.id } ?? 0
            let count = group.count
            let angle = count > 1 ? (2 * CGFloat.pi * CGFloat(idx) / CGFloat(count)) - CGFloat.pi / 2 : -CGFloat.pi / 2
            let r = n.depth == 0 ? 0 : radii[min(n.depth, radii.count - 1)]
            copy.center = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
            return copy
        }
    }

    // MARK: - Mutual toggle collapse

    func toggleCollapse(id: UUID, in node: inout TreeNode) {
        if node.id == id {
            node.isCollapsed.toggle()
            return
        }
        for i in node.children.indices {
            toggleCollapse(id: id, in: &node.children[i])
        }
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
                    nodeStyleSettingsView
                    connectorStyleSettingsView
                    interactionSettingsView
                    nodeListView
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
            let w = geo.size.width, h = geo.size.height
            let nodes = computeLayout(chartW: w, chartH: h)
            let nodeMap = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
            let r = CGFloat(nodeSize) / 2

            ZStack {
                // Connectors
                ForEach(nodes.filter { $0.parentID != nil }, id: \.id) { child in
                    if let parent = nodeMap[child.parentID!] {
                        connectorPath(from: parent.center, to: child.center, r: r)
                            .stroke(
                                colorConnectors ? child.color.opacity(connectorOpacity) : Color.primary.opacity(connectorOpacity),
                                style: StrokeStyle(lineWidth: CGFloat(connectorThickness), lineCap: .round)
                            )
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: animationDuration).delay(Double(child.depth) * 0.08), value: appeared)
                    }
                }

                // Nodes
                ForEach(nodes, id: \.id) { n in
                    nodeView(n: n, r: r)
                        .position(n.center)
                        .scaleEffect(appeared ? 1.0 : 0.01)
                        .opacity(appeared ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.72)
                                .delay(animateOnLoad ? Double(n.depth) * 0.06 : 0),
                            value: appeared
                        )
                        .onTapGesture {
                            if collapseEnabled && !n.isLeaf {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                                    toggleCollapse(id: n.id, in: &root)
                                }
                            }
                            withAnimation(.spring(response: 0.3)) {
                                highlightedID = highlightedID == n.id ? nil : n.id
                            }
                        }
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
                    .onEnded { v in if zoomPanEnabled { zoomScale = min(6, max(0.3, zoomScale * v)) } }
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

    // MARK: - Node View

    @ViewBuilder
    func nodeView(n: LayoutNode, r: CGFloat) -> some View {
        let isHL = highlightedID == n.id
        let col = n.color
        let shape2D = nodeShape == .circle ? AnyShape(Circle()) :
                      nodeShape == .square ? AnyShape(RoundedRectangle(cornerRadius: 6, style: .continuous)) :
                                             AnyShape(DiamondShape())

        ZStack {
            // Shadow
            if shadowEnabled {
                shape2D
                    .fill(col.opacity(0.2))
                    .blur(radius: 5)
                    .frame(width: r * 2 + 4, height: r * 2 + 4)
                    .offset(y: 3)
            }

            // Fill
            if glassNodes {
                shape2D
                    .fill(col.opacity(0.72))
                    .glassEffect(.clear, in: shape2D)
                    .frame(width: r * 2, height: r * 2)
            } else {
                shape2D
                    .fill(col.opacity(0.85))
                    .frame(width: r * 2, height: r * 2)
            }

            // Border
            shape2D
                .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                .frame(width: r * 2, height: r * 2)

            // Inner glow
            shape2D
                .stroke(Color.white, lineWidth: 4)
                .blur(radius: 2.5)
                .opacity(isHL ? 0.5 : 0.22)
                .clipShape(shape2D)
                .frame(width: r * 2, height: r * 2)

            // Collapse indicator
            if !n.isLeaf && n.isCollapsed {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
        }
        .overlay(alignment: .bottom) {
            if showLabels {
                Text(n.label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .offset(y: r + 10)
            }
        }
        .overlay(alignment: .top) {
            if showValues && n.value > 0 {
                Text(n.value == Double(Int(n.value)) ? "\(Int(n.value))" : String(format: "%.1f", n.value))
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
        }
    }

    // MARK: - Connector Path

    func connectorPath(from parent: CGPoint, to child: CGPoint, r: CGFloat) -> Path {
        Path { p in
            switch connectorStyle {
            case .straight:
                p.move(to: parent)
                p.addLine(to: child)
            case .curved:
                let mid = CGPoint(x: (parent.x + child.x) / 2, y: (parent.y + child.y) / 2)
                if orientation == .leftRight {
                    p.move(to: parent)
                    p.addCurve(to: child,
                               control1: CGPoint(x: mid.x, y: parent.y),
                               control2: CGPoint(x: mid.x, y: child.y))
                } else {
                    p.move(to: parent)
                    p.addCurve(to: child,
                               control1: CGPoint(x: parent.x, y: mid.y),
                               control2: CGPoint(x: child.x, y: mid.y))
                }
            case .orthogonal:
                if orientation == .leftRight {
                    let midX = (parent.x + child.x) / 2
                    p.move(to: parent)
                    p.addLine(to: CGPoint(x: midX, y: parent.y))
                    p.addLine(to: CGPoint(x: midX, y: child.y))
                    p.addLine(to: child)
                } else {
                    let midY = (parent.y + child.y) / 2
                    p.move(to: parent)
                    p.addLine(to: CGPoint(x: parent.x, y: midY))
                    p.addLine(to: CGPoint(x: child.x, y: midY))
                    p.addLine(to: child)
                }
            }
        }
    }

    // MARK: - Settings Views

    @ViewBuilder
    var layoutSettingsView: some View {
        settingsSection("Layout") {
            HStack(spacing: 6) {
                ForEach(TreeOrientation.allCases, id: \.self) { o in
                    pillButton(o.rawValue, selected: orientation == o) { orientation = o }
                }
            }
            .padding(.horizontal, 20)
            HStack {
                settingsLabel("Level Gap")
                Slider(value: $levelSpacing, in: 40...140)
                Text("\(Int(levelSpacing))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }
            HStack {
                settingsLabel("Node Gap")
                Slider(value: $siblingSpacing, in: 30...120)
                Text("\(Int(siblingSpacing))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }
        }
    }

    @ViewBuilder
    var nodeStyleSettingsView: some View {
        settingsSection("Node Style") {
            HStack(spacing: 6) {
                ForEach(TreeNodeShape.allCases, id: \.self) { s in
                    pillButton(s.rawValue, selected: nodeShape == s) { nodeShape = s }
                }
            }
            .padding(.horizontal, 20)
            HStack {
                settingsLabel("Size")
                Slider(value: $nodeSize, in: 20...60)
                Text("\(Int(nodeSize))pt")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
            Toggle(isOn: $glassNodes) { settingsLabel("Glass Effect") }.padding(.horizontal, 20)
            Toggle(isOn: $shadowEnabled) { settingsLabel("Shadow") }.padding(.horizontal, 20)
            Toggle(isOn: $showLabels) { settingsLabel("Labels") }.padding(.horizontal, 20)
            Toggle(isOn: $showValues) { settingsLabel("Values") }.padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    var connectorStyleSettingsView: some View {
        settingsSection("Connectors") {
            HStack(spacing: 6) {
                ForEach(TreeConnector.allCases, id: \.self) { c in
                    pillButton(c.rawValue, selected: connectorStyle == c) { connectorStyle = c }
                }
            }
            .padding(.horizontal, 20)
            HStack {
                settingsLabel("Thickness")
                Slider(value: $connectorThickness, in: 0.5...4)
                Text(String(format: "%.1f", connectorThickness))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }
            HStack {
                settingsLabel("Opacity")
                Slider(value: $connectorOpacity, in: 0.1...1.0)
                Text(String(format: "%.0f%%", connectorOpacity * 100))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
            Toggle(isOn: $colorConnectors) { settingsLabel("Color Connectors") }.padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    var interactionSettingsView: some View {
        settingsSection("Interaction") {
            Toggle(isOn: $collapseEnabled) { settingsLabel("Tap to Collapse") }.padding(.horizontal, 20)
            Toggle(isOn: $zoomPanEnabled) { settingsLabel("Zoom & Pan") }.padding(.horizontal, 20)
            Toggle(isOn: $animateOnLoad) { settingsLabel("Animate on Load") }.padding(.horizontal, 20)
        }
    }

    // MARK: - Node List

    var nodeListView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Nodes")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        let idx = root.children.count % TreeDiagramCard.colorPalette.count
                        root.children.append(
                            TreeNode(label: "Node \(root.children.count + 1)",
                                     value: Double.random(in: 10...90),
                                     color: TreeDiagramCard.colorPalette[idx],
                                     children: [])
                        )
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(TreeDiagramCard.colorPalette[root.children.count % TreeDiagramCard.colorPalette.count])
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            nodeRow(node: root, depth: 0, parentLabel: nil)
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    func nodeRow(node: TreeNode, depth: Int, parentLabel: String?) -> some View {
        HStack(spacing: 8) {
            // Indent
            if depth > 0 {
                Rectangle()
                    .fill(node.color.opacity(0.3))
                    .frame(width: 2, height: 24)
                    .padding(.leading, CGFloat(depth - 1) * 16 + 20)
            } else {
                Color.clear.frame(width: 20, height: 1)
            }

            Circle()
                .fill(node.color)
                .frame(width: 8, height: 8)
                .glassEffect(.clear, in: .circle)

            Text(node.label)
                .font(.system(size: 13, weight: depth == 0 ? .semibold : .regular, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            if !node.children.isEmpty {
                Text("\(node.children.count) \(node.children.count == 1 ? "child" : "children")")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Text(node.value == Double(Int(node.value)) ? "\(Int(node.value))" : String(format: "%.1f", node.value))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(node.color)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, depth == 0 ? 0 : 0)
        .padding(.vertical, 6)

        if !node.isCollapsed {
            ForEach(node.children) { child in
                nodeRow(node: child, depth: depth + 1, parentLabel: node.label)
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
                .background(Capsule().fill(selected ? Color.primary.opacity(0.1) : Color.clear))
                .overlay(Capsule().stroke(selected ? Color.primary.opacity(0.2) : Color.clear, lineWidth: 0.5))
        }
    }
}

