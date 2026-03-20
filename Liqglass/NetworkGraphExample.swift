//
//  NetworkGraphExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Data Models

struct NetworkNode: Identifiable {
    let id = UUID()
    var nodeID: String
    var label: String
    var value: Double
    var category: String
    var color: Color
}

struct NetworkEdge: Identifiable {
    let id = UUID()
    var sourceID: UUID
    var targetID: UUID
    var weight: Double
    var edgeLabel: String
}

// MARK: - Enums

enum NGLayout: String, CaseIterable { case forceDirected = "Force", circular = "Circular", grid = "Grid", hierarchical = "Hierarchical" }
enum NGSizeMode: String, CaseIterable { case fixed = "Fixed", byValue = "By Value" }
enum NGShape: String, CaseIterable { case circle = "Circle", square = "Square" }
enum NGEdgeStyle: String, CaseIterable { case solid = "Solid", dashed = "Dashed" }
enum NGColorMode: String, CaseIterable { case single = "Single", byCategory = "Category", byDegree = "Degree", byValue = "Value" }
enum NGLabelPos: String, CaseIterable { case inside = "Inside", outside = "Outside", hidden = "Hidden" }
enum NGOverflow: String, CaseIterable { case wrap = "Wrap", truncate = "Truncate" }

// MARK: - Network Graph Card

struct NetworkGraphCard: View {

    let title: String
    let categories: [String]
    @State private var nodes: [NetworkNode]
    @State private var edges: [NetworkEdge]
    @State private var isExpanded = false
    @State private var appeared = false
    @State private var nodePositions: [UUID: CGPoint] = [:]
    @State private var chartSize: CGSize = .zero
    @State private var highlightedID: UUID? = nil
    @State private var draggingNodeID: UUID? = nil
    @State private var dragStartPos: CGPoint = .zero
    @State private var tooltipID: UUID? = nil

    // Zoom & Pan
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragTranslation: CGSize = .zero

    // Layout
    @State private var layoutType: NGLayout = .forceDirected
    @State private var nodeSpacingVal: Double = 50
    @State private var layoutIterations: Double = 120
    @State private var chartPadding: Double = 20

    // Physics
    @State private var enablePhysics: Bool = true
    @State private var repulsionStrength: Double = 60
    @State private var linkDistance: Double = 80
    @State private var gravity: Double = 30
    @State private var damping: Double = 0.7

    // Node Styling
    @State private var nodeSize: Double = 18
    @State private var nodeSizeMode: NGSizeMode = .fixed
    @State private var nodeShape: NGShape = .circle
    @State private var nodeFill: Bool = true
    @State private var nodeStroke: Bool = true

    // Edge Styling
    @State private var edgeThickness: Double = 1.5
    @State private var edgeStyle: NGEdgeStyle = .solid
    @State private var edgeOpacity: Double = 0.5
    @State private var curvedEdges: Bool = true

    // Color
    @State private var colorMode: NGColorMode = .byCategory
    @State private var primaryColor: Color = AnalyticsCard.colorPalette[0]
    @State private var colorScale: Bool = true

    // Labels
    @State private var showLabels: Bool = true
    @State private var labelPos: NGLabelPos = .outside
    @State private var labelOverflow: NGOverflow = .truncate

    // Interaction
    @State private var hoverHighlight: Bool = true
    @State private var hoverTooltip: Bool = true
    @State private var dragNodesEnabled: Bool = true
    @State private var zoomPanEnabled: Bool = false
    @State private var focusNode: Bool = false
    @State private var animateOnLoad: Bool = true
    @State private var animationDuration: Double = 0.7

    // Clustering
    @State private var clusterMode: Bool = false
    @State private var clusterStrength: Double = 50
    @State private var groupHighlight: Bool = true

    // Filter
    @State private var filterByDegree: Double = 0
    @State private var filterByValue: Double = 0

    // MARK: - Init

    init(title: String, categories: [String], nodes: [NetworkNode], edges: [NetworkEdge]) {
        self.title = title
        self.categories = categories
        self._nodes = State(initialValue: nodes)
        self._edges = State(initialValue: edges)
    }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Computed Properties

    var degreeMap: [UUID: Int] {
        var d: [UUID: Int] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, 0) })
        for e in edges { d[e.sourceID, default: 0] += 1; d[e.targetID, default: 0] += 1 }
        return d
    }

    var uniqueCategories: [String] { Array(Set(nodes.map { $0.category })).sorted() }

    var connectedNodeIDs: Set<UUID> {
        guard let hid = highlightedID else { return [] }
        var ids = Set<UUID>()
        for e in edges {
            if e.sourceID == hid { ids.insert(e.targetID) }
            if e.targetID == hid { ids.insert(e.sourceID) }
        }
        return ids
    }

    var visibleNodes: [NetworkNode] {
        nodes.filter { n in
            let deg = degreeMap[n.id] ?? 0
            return Double(deg) >= filterByDegree && n.value >= filterByValue
        }
    }
    var visibleNodeIDs: Set<UUID> { Set(visibleNodes.map { $0.id }) }
    var visibleEdges: [NetworkEdge] {
        edges.filter { visibleNodeIDs.contains($0.sourceID) && visibleNodeIDs.contains($0.targetID) }
    }

    // MARK: - Color

    func nodeColor(for n: NetworkNode) -> Color {
        switch colorMode {
        case .single: return primaryColor
        case .byCategory:
            let idx = uniqueCategories.firstIndex(of: n.category) ?? 0
            return NetworkGraphCard.colorPalette[idx % NetworkGraphCard.colorPalette.count]
        case .byDegree:
            let deg = degreeMap
            let maxDeg = max(1, deg.values.max() ?? 1)
            let t = Double(deg[n.id] ?? 0) / Double(maxDeg)
            return Color(hue: 0.667 - t * 0.667, saturation: 0.8, brightness: 0.85)
        case .byValue:
            let maxV = max(1, nodes.map { $0.value }.max() ?? 1)
            let t = n.value / maxV
            return Color(hue: 0.667 - t * 0.667, saturation: 0.8, brightness: 0.85)
        }
    }

    func nodeRadius(for n: NetworkNode) -> CGFloat {
        if nodeSizeMode == .byValue {
            let maxV = max(1, nodes.map { $0.value }.max() ?? 1)
            let t = n.value / maxV
            return CGFloat(nodeSize * 0.5 + nodeSize * t * 1.5)
        }
        return CGFloat(nodeSize)
    }

    func isEdgeHighlighted(_ e: NetworkEdge) -> Bool {
        guard hoverHighlight, let hid = highlightedID else { return false }
        return e.sourceID == hid || e.targetID == hid
    }

    // MARK: - Layout

    func computeLayout() {
        let rect = CGRect(origin: .zero, size: chartSize)
        guard rect.width > 10, rect.height > 10 else { return }
        switch layoutType {
        case .forceDirected: nodePositions = computeForceLayout(rect: rect)
        case .circular:      nodePositions = computeCircularLayout(rect: rect)
        case .grid:          nodePositions = computeGridLayout(rect: rect)
        case .hierarchical:  nodePositions = computeHierarchicalLayout(rect: rect)
        }
    }

    func computeForceLayout(rect: CGRect) -> [UUID: CGPoint] {
        guard !nodes.isEmpty else { return [:] }
        var pos: [UUID: CGPoint] = [:]
        var vel: [UUID: CGSize] = [:]
        let cx = rect.midX, cy = rect.midY
        for (i, n) in nodes.enumerated() {
            if let existing = nodePositions[n.id] {
                pos[n.id] = existing
            } else {
                let angle = 2 * CGFloat.pi * CGFloat(i) / CGFloat(max(1, nodes.count))
                let r = min(rect.width, rect.height) * 0.3
                pos[n.id] = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
            }
            vel[n.id] = .zero
        }
        let repK: CGFloat = CGFloat(repulsionStrength) * 80 + 500
        let grav: CGFloat = CGFloat(gravity) / 100 * 0.04
        let damp: CGFloat = CGFloat(damping)
        let linkDist: CGFloat = CGFloat(linkDistance)
        let clusterK: CGFloat = clusterMode ? CGFloat(clusterStrength) / 100 * 0.08 : 0
        let iters = enablePhysics ? max(10, Int(layoutIterations)) : 1

        for _ in 0..<iters {
            var forces: [UUID: CGSize] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, CGSize.zero) })
            // Repulsion between all pairs
            for i in 0..<nodes.count {
                for j in (i+1)..<nodes.count {
                    guard let pa = pos[nodes[i].id], let pb = pos[nodes[j].id] else { continue }
                    let dx = pb.x - pa.x, dy = pb.y - pa.y
                    let d = max(1, sqrt(dx*dx + dy*dy))
                    let f = repK / (d * d)
                    let fx = f * dx / d, fy = f * dy / d
                    forces[nodes[i].id]?.width -= fx
                    forces[nodes[i].id]?.height -= fy
                    forces[nodes[j].id]?.width += fx
                    forces[nodes[j].id]?.height += fy
                }
            }
            // Edge attraction
            for edge in edges {
                guard let ps = pos[edge.sourceID], let pt = pos[edge.targetID] else { continue }
                let dx = pt.x - ps.x, dy = pt.y - ps.y
                let d = max(1, sqrt(dx*dx + dy*dy))
                let f: CGFloat = 0.04 * (d - linkDist) * CGFloat(edge.weight)
                let fx = f * dx / d, fy = f * dy / d
                forces[edge.sourceID]?.width += fx
                forces[edge.sourceID]?.height += fy
                forces[edge.targetID]?.width -= fx
                forces[edge.targetID]?.height -= fy
            }
            // Cluster attraction
            if clusterMode {
                for i in 0..<nodes.count {
                    for j in (i+1)..<nodes.count {
                        guard nodes[i].category == nodes[j].category,
                              let pa = pos[nodes[i].id], let pb = pos[nodes[j].id] else { continue }
                        let dx = pb.x - pa.x, dy = pb.y - pa.y
                        let d = max(1, sqrt(dx*dx + dy*dy))
                        let fx = clusterK * dx / d, fy = clusterK * dy / d
                        forces[nodes[i].id]?.width += fx
                        forces[nodes[i].id]?.height += fy
                        forces[nodes[j].id]?.width -= fx
                        forces[nodes[j].id]?.height -= fy
                    }
                }
            }
            // Gravity
            for n in nodes {
                guard let p = pos[n.id] else { continue }
                forces[n.id]?.width += grav * (cx - p.x)
                forces[n.id]?.height += grav * (cy - p.y)
            }
            // Integrate
            for n in nodes {
                guard let f = forces[n.id] else { continue }
                vel[n.id]?.width = (vel[n.id]?.width ?? 0) * damp + f.width
                vel[n.id]?.height = (vel[n.id]?.height ?? 0) * damp + f.height
                if let v = vel[n.id], let p = pos[n.id] {
                    pos[n.id] = CGPoint(x: p.x + v.width, y: p.y + v.height)
                }
            }
        }
        return pos
    }

    func computeCircularLayout(rect: CGRect) -> [UUID: CGPoint] {
        let cx = rect.midX, cy = rect.midY
        let r = min(rect.width, rect.height) * 0.38
        var pos: [UUID: CGPoint] = [:]
        for (i, n) in nodes.enumerated() {
            let angle = 2 * CGFloat.pi * CGFloat(i) / CGFloat(max(1, nodes.count)) - CGFloat.pi / 2
            pos[n.id] = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
        }
        return pos
    }

    func computeGridLayout(rect: CGRect) -> [UUID: CGPoint] {
        let cols = max(1, Int(ceil(sqrt(Double(nodes.count)))))
        let pad: CGFloat = CGFloat(chartPadding) + 20
        let usableW = rect.width - pad * 2
        let usableH = rect.height - pad * 2
        let rows = max(1, (nodes.count + cols - 1) / cols)
        let cellW = usableW / CGFloat(cols)
        let cellH = usableH / CGFloat(rows)
        var pos: [UUID: CGPoint] = [:]
        for (i, n) in nodes.enumerated() {
            let col = i % cols, row = i / cols
            pos[n.id] = CGPoint(
                x: rect.minX + pad + cellW * CGFloat(col) + cellW / 2,
                y: rect.minY + pad + cellH * CGFloat(row) + cellH / 2
            )
        }
        return pos
    }

    func computeHierarchicalLayout(rect: CGRect) -> [UUID: CGPoint] {
        guard !nodes.isEmpty else { return [:] }
        var adj: [UUID: [UUID]] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, [UUID]()) })
        for e in edges { adj[e.sourceID]?.append(e.targetID); adj[e.targetID]?.append(e.sourceID) }
        let root = nodes.max(by: { (adj[$0.id]?.count ?? 0) < (adj[$1.id]?.count ?? 0) })?.id ?? nodes[0].id
        var depths: [UUID: Int] = [root: 0]
        var queue: [UUID] = [root]
        while !queue.isEmpty {
            let cur = queue.removeFirst()
            for nb in adj[cur] ?? [] where depths[nb] == nil {
                depths[nb] = (depths[cur] ?? 0) + 1
                queue.append(nb)
            }
        }
        let maxD = depths.values.max() ?? 0
        nodes.forEach { if depths[$0.id] == nil { depths[$0.id] = maxD + 1 } }
        var byDepth: [Int: [UUID]] = [:]
        depths.forEach { byDepth[$0.value, default: []].append($0.key) }
        let pad: CGFloat = CGFloat(chartPadding) + 20
        let allDepths = byDepth.keys.sorted()
        let levelH = (rect.height - pad * 2) / CGFloat(max(1, allDepths.count))
        var pos: [UUID: CGPoint] = [:]
        for d in allDepths {
            let nodesHere = byDepth[d] ?? []
            let cellW = (rect.width - pad * 2) / CGFloat(max(1, nodesHere.count))
            for (i, nid) in nodesHere.enumerated() {
                pos[nid] = CGPoint(
                    x: rect.minX + pad + cellW * CGFloat(i) + cellW / 2,
                    y: rect.minY + pad + levelH * CGFloat(d) + levelH / 2
                )
            }
        }
        return pos
    }

    // MARK: - Edge Path

    func edgePath(from a: CGPoint, to b: CGPoint, curved: Bool) -> Path {
        Path { p in
            p.move(to: a)
            if curved {
                let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
                let perp = CGPoint(x: -(b.y - a.y) * 0.2, y: (b.x - a.x) * 0.2)
                let cp = CGPoint(x: mid.x + perp.x, y: mid.y + perp.y)
                p.addQuadCurve(to: b, control: cp)
            } else {
                p.addLine(to: b)
            }
        }
    }

    // MARK: - Design System Helpers

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

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            ZStack {
                // Edges
                ForEach(visibleEdges) { edge in
                    if let ps = nodePositions[edge.sourceID], let pt = nodePositions[edge.targetID] {
                        let isHL = isEdgeHighlighted(edge)
                        let dash: [CGFloat] = edgeStyle == .dashed ? [6, 4] : []
                        edgePath(from: ps, to: pt, curved: curvedEdges)
                            .stroke(
                                Color.primary.opacity(isHL ? edgeOpacity * 1.8 : edgeOpacity),
                                style: StrokeStyle(lineWidth: isHL ? CGFloat(edgeThickness) * 1.5 : CGFloat(edgeThickness), lineCap: .round, dash: dash)
                            )
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: animationDuration * 0.8), value: appeared)
                    }
                }
                // Nodes
                ForEach(visibleNodes) { n in
                    if let pos = nodePositions[n.id] {
                        nodeView(n: n, pos: pos)
                            .position(pos)
                            .scaleEffect(appeared ? 1 : 0.01)
                            .opacity(appeared ? (hoverHighlight && highlightedID != nil && highlightedID != n.id && !connectedNodeIDs.contains(n.id) ? 0.3 : 1) : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(animateOnLoad ? Double.random(in: 0...0.3) : 0), value: appeared)
                            .animation(.spring(response: 0.25), value: highlightedID)
                            .gesture(
                                DragGesture(minimumDistance: 2)
                                    .onChanged { v in
                                        guard dragNodesEnabled else { return }
                                        if draggingNodeID == nil {
                                            draggingNodeID = n.id
                                            dragStartPos = nodePositions[n.id] ?? .zero
                                        }
                                        if draggingNodeID == n.id {
                                            nodePositions[n.id] = CGPoint(
                                                x: dragStartPos.x + v.translation.width,
                                                y: dragStartPos.y + v.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { _ in draggingNodeID = nil }
                            )
                            .simultaneousGesture(TapGesture().onEnded {
                                withAnimation(.spring(response: 0.3)) {
                                    if highlightedID == n.id { highlightedID = nil; tooltipID = nil }
                                    else { highlightedID = n.id; tooltipID = hoverTooltip ? n.id : nil }
                                }
                            })
                    }
                }
                // Tooltip
                if hoverTooltip, let tid = tooltipID, let n = nodes.first(where: { $0.id == tid }),
                   let pos = nodePositions[tid] {
                    tooltipView(node: n, pos: pos, chartSize: geo.size)
                }
            }
            .background(
                GeometryReader { inner in
                    Color.clear
                        .onAppear { chartSize = inner.size; computeLayout() }
                        .onChange(of: inner.size) { _, s in chartSize = s; computeLayout() }
                }
            )
            .scaleEffect(zoomPanEnabled ? zoomScale * magnifyBy : 1.0, anchor: .center)
            .offset(
                x: zoomPanEnabled ? panOffset.width + dragTranslation.width : 0,
                y: zoomPanEnabled ? panOffset.height + dragTranslation.height : 0
            )
            .gesture(
                MagnificationGesture()
                    .updating($magnifyBy) { v, s, _ in s = zoomPanEnabled ? v : 1.0 }
                    .onEnded { v in if zoomPanEnabled { zoomScale = min(5, max(0.3, zoomScale * v)) } }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 14)
                    .updating($dragTranslation) { v, s, _ in s = (zoomPanEnabled && draggingNodeID == nil) ? v.translation : .zero }
                    .onEnded { v in
                        if zoomPanEnabled && draggingNodeID == nil {
                            panOffset.width += v.translation.width
                            panOffset.height += v.translation.height
                        }
                    }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) { highlightedID = nil; tooltipID = nil }
            }
            .clipped()
        }
    }

    // MARK: - Node View

    @ViewBuilder
    func nodeView(n: NetworkNode, pos: CGPoint) -> some View {
        let r = nodeRadius(for: n)
        let col = nodeColor(for: n)
        let isHL = highlightedID == n.id || connectedNodeIDs.contains(n.id)
        let shapeView: AnyShape = nodeShape == .circle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: r * 0.3, style: .continuous))

        ZStack {
            // Shadow
            shapeView.fill(col.opacity(0.2)).blur(radius: 4).offset(y: 2).frame(width: r*2+4, height: r*2+4)
            // Fill
            if nodeFill {
                shapeView.fill(col.opacity(0.85)).glassEffect(.clear, in: shapeView).frame(width: r*2, height: r*2)
            }
            // Stroke
            if nodeStroke {
                shapeView.stroke(Color.white.opacity(0.35), lineWidth: 0.5).frame(width: r*2, height: r*2)
            }
            // Inner glow
            shapeView.stroke(Color.white, lineWidth: 4).blur(radius: 2.5).opacity(isHL ? 0.45 : 0.22).clipShape(shapeView).frame(width: r*2, height: r*2)

            // Label inside
            if showLabels && labelPos == .inside {
                Text(n.label).font(.system(size: min(10, r * 0.55), weight: .semibold, design: .rounded)).foregroundStyle(Color.white.opacity(0.9)).lineLimit(1).frame(width: r * 1.6)
            }
        }
        .overlay(alignment: labelPos == .outside ? .bottom : .center) {
            if showLabels && labelPos == .outside {
                Text(n.label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(labelOverflow == .wrap ? 2 : 1)
                    .truncationMode(.tail)
                    .offset(y: r + 10)
            }
        }
    }

    // MARK: - Tooltip View

    @ViewBuilder
    func tooltipView(node: NetworkNode, pos: CGPoint, chartSize: CGSize) -> some View {
        let deg = degreeMap[node.id] ?? 0
        VStack(alignment: .leading, spacing: 3) {
            Text(node.label).font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(.primary)
            Divider()
            HStack(spacing: 4) {
                Text("Value:").font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Text(String(format: "%.1f", node.value)).font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            }
            HStack(spacing: 4) {
                Text("Degree:").font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Text("\(deg)").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            }
            HStack(spacing: 4) {
                Text("Category:").font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Text(node.category).font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(Color(uiColor: .systemBackground).opacity(0.92), in: .rect(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        .frame(width: 120)
        .position(
            x: min(max(pos.x, 70), chartSize.width - 70),
            y: max(pos.y - 60, 40)
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            chartView
                .frame(height: 260)
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
                    physicsSettingsView
                    nodeStyleSettingsView
                    edgeStyleSettingsView
                    colorSettingsView
                    labelSettingsView
                    interactionSettingsView
                    clusteringSettingsView
                    filterSettingsView
                    dataListView
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                computeLayout()
                if animateOnLoad {
                    withAnimation(.easeOut(duration: animationDuration)) { appeared = true }
                } else {
                    appeared = true
                }
            }
        }
        .onChange(of: layoutType) { _, _ in withAnimation(.spring(response: 0.5)) { computeLayout() } }
        .onChange(of: enablePhysics) { _, _ in computeLayout() }
        .onChange(of: zoomPanEnabled) { _, enabled in
            if !enabled { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { zoomScale = 1; panOffset = .zero } }
        }
    }

    // MARK: - Settings Views

    var layoutSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Layout")
                HStack(spacing: 4) {
                    ForEach(NGLayout.allCases, id: \.self) { c in
                        pillButton(c.rawValue, isSelected: layoutType == c) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { layoutType = c }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Node Gap")
                Slider(value: $nodeSpacingVal, in: 10...120)
                Text("\(Int(nodeSpacingVal))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            if layoutType == .forceDirected {
                HStack(spacing: 10) {
                    settingsLabel("Iterations")
                    Slider(value: $layoutIterations, in: 10...300)
                    Text("\(Int(layoutIterations))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
            HStack(spacing: 10) {
                settingsLabel("Padding")
                Slider(value: $chartPadding, in: 0...60)
                Text("\(Int(chartPadding))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            Button {
                withAnimation(.spring(response: 0.5)) { computeLayout() }
            } label: {
                Text("Re-layout")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.06), in: .capsule)
            }
        }
    }

    var physicsSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Physics")
                Toggle("", isOn: $enablePhysics).labelsHidden().scaleEffect(0.8)
                Text("force simulation").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if enablePhysics {
                HStack(spacing: 10) {
                    settingsLabel("Repulsion")
                    Slider(value: $repulsionStrength, in: 0...100)
                    Text("\(Int(repulsionStrength))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
                HStack(spacing: 10) {
                    settingsLabel("Link Dist")
                    Slider(value: $linkDistance, in: 10...200)
                    Text("\(Int(linkDistance))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
                HStack(spacing: 10) {
                    settingsLabel("Gravity")
                    Slider(value: $gravity, in: 0...100)
                    Text("\(Int(gravity))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
                HStack(spacing: 10) {
                    settingsLabel("Damping")
                    Slider(value: $damping, in: 0...1)
                    Text(String(format: "%.2f", damping)).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    var nodeStyleSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Node Size")
                Slider(value: $nodeSize, in: 5...40)
                Text("\(Int(nodeSize))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Size Mode")
                HStack(spacing: 4) {
                    ForEach(NGSizeMode.allCases, id: \.self) { c in
                        pillButton(c.rawValue, isSelected: nodeSizeMode == c) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { nodeSizeMode = c }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Shape")
                HStack(spacing: 4) {
                    ForEach(NGShape.allCases, id: \.self) { c in
                        pillButton(c.rawValue, isSelected: nodeShape == c) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { nodeShape = c }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Fill")
                Toggle("", isOn: $nodeFill).labelsHidden().scaleEffect(0.8)
                Text("fill nodes").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Stroke")
                Toggle("", isOn: $nodeStroke).labelsHidden().scaleEffect(0.8)
                Text("border ring").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    var edgeStyleSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Thickness")
                Slider(value: $edgeThickness, in: 1...10)
                Text(String(format: "%.1f", edgeThickness)).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Style")
                HStack(spacing: 4) {
                    ForEach(NGEdgeStyle.allCases, id: \.self) { c in
                        pillButton(c.rawValue, isSelected: edgeStyle == c) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { edgeStyle = c }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Opacity")
                Slider(value: $edgeOpacity, in: 0...1)
                Text("\(Int(edgeOpacity * 100))%").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Curved")
                Toggle("", isOn: $curvedEdges).labelsHidden().scaleEffect(0.8)
                Text("bezier curves").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    var colorSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Color By")
                HStack(spacing: 4) {
                    ForEach(NGColorMode.allCases, id: \.self) { c in
                        pillButton(c.rawValue, isSelected: colorMode == c) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { colorMode = c }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Primary")
                ColorPicker("", selection: $primaryColor).labelsHidden().frame(width: 28, height: 28)
                Text("base color").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Scale")
                Toggle("", isOn: $colorScale).labelsHidden().scaleEffect(0.8)
                Text("gradient scale").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    var labelSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Labels")
                Toggle("", isOn: $showLabels).labelsHidden().scaleEffect(0.8)
                Text("show node labels").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if showLabels {
                HStack(spacing: 10) {
                    settingsLabel("Position")
                    HStack(spacing: 4) {
                        ForEach(NGLabelPos.allCases, id: \.self) { c in
                            pillButton(c.rawValue, isSelected: labelPos == c) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { labelPos = c }
                            }
                        }
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    settingsLabel("Overflow")
                    HStack(spacing: 4) {
                        ForEach(NGOverflow.allCases, id: \.self) { c in
                            pillButton(c.rawValue, isSelected: labelOverflow == c) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { labelOverflow = c }
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    var interactionSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Highlight")
                Toggle("", isOn: $hoverHighlight).labelsHidden().scaleEffect(0.8)
                Text("hover highlight").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Tooltip")
                Toggle("", isOn: $hoverTooltip).labelsHidden().scaleEffect(0.8)
                Text("show on tap").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Drag")
                Toggle("", isOn: $dragNodesEnabled).labelsHidden().scaleEffect(0.8)
                Text("drag nodes").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Zoom/Pan")
                Toggle("", isOn: $zoomPanEnabled).labelsHidden().scaleEffect(0.8)
                Text("pinch & pan").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Focus")
                Toggle("", isOn: $focusNode).labelsHidden().scaleEffect(0.8)
                Text("focus on select").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Animate")
                Toggle("", isOn: $animateOnLoad).labelsHidden().scaleEffect(0.8)
                Text("animate on load").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if animateOnLoad {
                HStack(spacing: 10) {
                    settingsLabel("Duration")
                    Slider(value: $animationDuration, in: 0.1...2.0)
                    Text(String(format: "%.1fs", animationDuration)).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    var clusteringSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Cluster")
                Toggle("", isOn: $clusterMode).labelsHidden().scaleEffect(0.8)
                Text("group by category").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if clusterMode {
                HStack(spacing: 10) {
                    settingsLabel("Strength")
                    Slider(value: $clusterStrength, in: 0...100)
                    Text("\(Int(clusterStrength))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
                HStack(spacing: 10) {
                    settingsLabel("Group HL")
                    Toggle("", isOn: $groupHighlight).labelsHidden().scaleEffect(0.8)
                    Text("highlight groups").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    var filterSettingsView: some View {
        let maxDeg = Double(degreeMap.values.max() ?? 1)
        let maxVal = nodes.map { $0.value }.max() ?? 100
        return settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Min Deg")
                Slider(value: $filterByDegree, in: 0...max(1, maxDeg))
                Text("\(Int(filterByDegree))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Min Val")
                Slider(value: $filterByValue, in: 0...max(1, maxVal))
                Text("\(Int(filterByValue))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Data List View

    var dataListView: some View {
        VStack(spacing: 0) {
            // Nodes header
            HStack {
                Text("Nodes").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(.primary)
                Spacer()
                Button {
                    let idx = nodes.count % NetworkGraphCard.colorPalette.count
                    withAnimation(.spring(response: 0.4)) {
                        let newNode = NetworkNode(nodeID: "n\(nodes.count+1)", label: "Node \(nodes.count+1)", value: Double.random(in: 10...90), category: "Group \(nodes.count % 3 + 1)", color: NetworkGraphCard.colorPalette[idx])
                        nodes.append(newNode)
                        computeLayout()
                    }
                } label: { Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundStyle(NetworkGraphCard.colorPalette[nodes.count % NetworkGraphCard.colorPalette.count]) }
            }
            .padding(.horizontal, 20).padding(.bottom, 10)

            ForEach(Array(nodes.enumerated()), id: \.element.id) { i, n in
                nodeRow(i: i, n: n)
                if i < nodes.count - 1 { Divider().padding(.horizontal, 20) }
            }

            Divider().padding(.horizontal, 20).padding(.top, 6)

            // Edges header
            HStack {
                Text("Edges").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(.primary)
                Spacer()
                Button {
                    guard nodes.count >= 2 else { return }
                    withAnimation(.spring(response: 0.4)) {
                        let src = nodes[Int.random(in: 0..<nodes.count)].id
                        var tgt = nodes[Int.random(in: 0..<nodes.count)].id
                        while tgt == src && nodes.count > 1 { tgt = nodes[Int.random(in: 0..<nodes.count)].id }
                        edges.append(NetworkEdge(sourceID: src, targetID: tgt, weight: Double.random(in: 0.5...2), edgeLabel: ""))
                    }
                } label: { Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundStyle(.secondary) }
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 10)

            ForEach(Array(edges.enumerated()), id: \.element.id) { i, e in
                edgeRow(i: i, e: e)
                if i < edges.count - 1 { Divider().padding(.horizontal, 20) }
            }

            Button { withAnimation(.spring(response: 0.45)) { computeLayout() } } label: {
                Text("↺ Re-layout")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Node Row

    @ViewBuilder
    func nodeRow(i: Int, n: NetworkNode) -> some View {
        HStack(spacing: 10) {
            Circle().fill(nodeColor(for: n)).frame(width: 8, height: 8)
            Text(n.label).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.primary)
            Spacer()
            Text(n.category).font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
            Slider(value: Binding(get: { n.value }, set: { nodes[i].value = $0 }), in: 0...100).frame(width: 80)
            Text(String(format: "%.0f", n.value)).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.primary).frame(width: 28, alignment: .trailing)
            if nodes.count > 1 {
                Button { withAnimation(.spring(response: 0.4)) { nodes.removeSubrange(i...i); edges.removeAll { $0.sourceID == n.id || $0.targetID == n.id }; computeLayout() } } label: { Image(systemName: "minus.circle").font(.system(size: 16)).foregroundStyle(.secondary) }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 8)
    }

    // MARK: - Edge Row

    @ViewBuilder
    func edgeRow(i: Int, e: NetworkEdge) -> some View {
        let srcLabel = nodes.first(where: { $0.id == e.sourceID })?.label ?? "?"
        let tgtLabel = nodes.first(where: { $0.id == e.targetID })?.label ?? "?"
        HStack(spacing: 10) {
            Text("\(srcLabel) → \(tgtLabel)").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(.primary)
            Spacer()
            Slider(value: Binding(get: { e.weight }, set: { edges[i].weight = $0 }), in: 0.1...5).frame(width: 70)
            Text(String(format: "×%.1f", e.weight)).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            Button { withAnimation(.spring(response: 0.4)) { edges.removeSubrange(i...i) } } label: { Image(systemName: "minus.circle").font(.system(size: 16)).foregroundStyle(.secondary) }
        }
        .padding(.horizontal, 20).padding(.vertical, 8)
    }
}
