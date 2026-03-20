//
//  FlowChartExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Data Models

enum FCNodeType: String, CaseIterable { case process = "Process", decision = "Decision", startEnd = "Start/End" }

struct FCNode: Identifiable {
    let id = UUID()
    var label: String
    var nodeType: FCNodeType
    var category: String
    var color: Color
    var gridCol: Int = 0
    var gridRow: Int = 0
}

struct FCConnection: Identifiable {
    let id = UUID()
    var sourceID: UUID
    var targetID: UUID
    var connLabel: String
}

// MARK: - Enums

enum FCLayout: String, CaseIterable { case vertical = "Vertical", horizontal = "Horizontal", freeform = "Freeform" }
enum FCShape: String, CaseIterable { case rectangle = "Rect", rounded = "Rounded", circle = "Circle", diamond = "Diamond" }
enum FCShadow: String, CaseIterable { case soft = "Soft", none_ = "None" }
enum FCConnector: String, CaseIterable { case straight = "Straight", curved = "Curved", orthogonal = "Ortho" }
enum FCLineStyle: String, CaseIterable { case solid = "Solid", dashed = "Dashed" }
enum FCColorMode: String, CaseIterable { case single = "Single", byNodeType = "By Type", byCategory = "Category" }
enum FCLabelPos: String, CaseIterable { case inside = "Inside", outside = "Outside", hidden = "Hidden" }
enum FCTextAlign: String, CaseIterable { case left = "Left", center = "Center", right = "Right" }
enum FCOverflow: String, CaseIterable { case wrap = "Wrap", truncate = "Truncate" }

// MARK: - Flow Chart Card

struct FlowChartCard: View {

    let title: String
    let categories: [String]
    @State private var nodes: [FCNode]
    @State private var connections: [FCConnection]
    @State private var isExpanded = false
    @State private var appeared = false
    @State private var highlightedID: UUID? = nil
    @State private var tooltipID: UUID? = nil
    @State private var nodePositions: [UUID: CGPoint] = [:]
    @State private var chartSize: CGSize = .zero
    @State private var draggingID: UUID? = nil
    @State private var dragStartPos: CGPoint = .zero

    // Zoom & Pan
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragTranslation: CGSize = .zero

    // Layout
    @State private var layoutType: FCLayout = .vertical
    @State private var autoLayout: Bool = true
    @State private var nodeSpacing: Double = 60
    @State private var levelSpacing: Double = 80
    @State private var chartPadding: Double = 20

    // Node Types
    @State private var nodeShape: FCShape = .rounded
    @State private var defaultNodeType: FCNodeType = .process
    @State private var allowMixedTypes: Bool = true

    // Node Styling
    @State private var nodeWidth: Double = 120
    @State private var nodeHeight: Double = 50
    @State private var cornerRadius: Double = 10
    @State private var nodeFill: Bool = true
    @State private var nodeStroke: Bool = true
    @State private var shadowStyle: FCShadow = .soft

    // Connector Styling
    @State private var connectorType: FCConnector = .orthogonal
    @State private var connectorThickness: Double = 1.5
    @State private var connectorStyle: FCLineStyle = .solid
    @State private var showArrowHead: Bool = true
    @State private var connectorOpacity: Double = 0.7

    // Color
    @State private var colorMode: FCColorMode = .byNodeType
    @State private var primaryColor: Color = FlowChartCard.colorPalette[0]
    @State private var colorScale: Bool = true

    // Labels
    @State private var showLabels: Bool = true
    @State private var labelPos: FCLabelPos = .inside
    @State private var textAlign: FCTextAlign = .center
    @State private var textOverflow: FCOverflow = .truncate

    // Interaction
    @State private var hoverHighlight: Bool = true
    @State private var hoverTooltip: Bool = true
    @State private var dragNodesEnabled: Bool = true
    @State private var zoomPanEnabled: Bool = false
    @State private var animateOnLoad: Bool = true
    @State private var animationDuration: Double = 0.7

    // Navigation
    @State private var showMinimap: Bool = false
    @State private var autoCenter: Bool = false

    // Validation
    @State private var flowValidation: Bool = false
    @State private var highlightErrors: Bool = false

    // MARK: - Color Palette

    static let colorPalette: [Color] = [
        Color(red: 0.28, green: 0.16, blue: 0.72),
        Color(red: 0.62, green: 0.52, blue: 0.88),
        Color(red: 0.82, green: 0.78, blue: 0.94),
        Color(red: 0.56, green: 0.82, blue: 0.72),
        Color(red: 0.38, green: 0.65, blue: 0.58),
        Color(red: 0.82, green: 0.92, blue: 0.88),
    ]

    // MARK: - Init

    init(title: String, categories: [String], nodes: [FCNode], connections: [FCConnection]) {
        self.title = title
        self.categories = categories
        self._nodes = State(initialValue: nodes)
        self._connections = State(initialValue: connections)
    }

    // MARK: - Color Logic

    var uniqueCategories: [String] { Array(Set(nodes.map { $0.category })).sorted() }

    func nodeColor(for n: FCNode) -> Color {
        switch colorMode {
        case .single: return primaryColor
        case .byNodeType:
            switch n.nodeType {
            case .process:  return FlowChartCard.colorPalette[0]
            case .decision: return FlowChartCard.colorPalette[2]
            case .startEnd: return FlowChartCard.colorPalette[4]
            }
        case .byCategory:
            let idx = uniqueCategories.firstIndex(of: n.category) ?? 0
            return FlowChartCard.colorPalette[idx % FlowChartCard.colorPalette.count]
        }
    }

    // MARK: - Validation

    func isUnconnected(_ n: FCNode) -> Bool {
        !connections.contains { $0.sourceID == n.id || $0.targetID == n.id }
    }

    // MARK: - Auto Layout (BFS-based)

    func computeAutoLayout(size: CGSize) -> [UUID: CGPoint] {
        guard !nodes.isEmpty else { return [:] }
        var outgoing: [UUID: [UUID]] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, [UUID]()) })
        var incoming: [UUID: [UUID]] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, [UUID]()) })
        for c in connections { outgoing[c.sourceID]?.append(c.targetID); incoming[c.targetID]?.append(c.sourceID) }
        var levels: [UUID: Int] = [:]
        let roots = nodes.filter { incoming[$0.id]?.isEmpty ?? true }.map { $0.id }
        roots.forEach { levels[$0] = 0 }
        var queue = roots
        while !queue.isEmpty {
            let cur = queue.removeFirst()
            let l = levels[cur] ?? 0
            for next in outgoing[cur] ?? [] where (levels[next] ?? -1) < l + 1 {
                levels[next] = l + 1
                queue.append(next)
            }
        }
        let maxL = levels.values.max() ?? 0
        nodes.forEach { if levels[$0.id] == nil { levels[$0.id] = maxL } }
        var byLevel: [Int: [UUID]] = [:]
        levels.forEach { byLevel[$0.value, default: []].append($0.key) }
        let pad = CGFloat(chartPadding)
        let nw = CGFloat(nodeWidth), nh = CGFloat(nodeHeight)
        let ns = CGFloat(nodeSpacing), ls = CGFloat(levelSpacing)
        var pos: [UUID: CGPoint] = [:]
        for (l, ids) in byLevel {
            for (i, nid) in ids.enumerated() {
                if layoutType == .vertical {
                    let totalW = CGFloat(ids.count) * nw + CGFloat(max(0, ids.count - 1)) * ns
                    let startX = (size.width - totalW) / 2
                    pos[nid] = CGPoint(x: startX + CGFloat(i) * (nw + ns) + nw / 2,
                                       y: pad + CGFloat(l) * (nh + ls) + nh / 2)
                } else {
                    let totalH = CGFloat(ids.count) * nh + CGFloat(max(0, ids.count - 1)) * ns
                    let startY = (size.height - totalH) / 2
                    pos[nid] = CGPoint(x: pad + CGFloat(l) * (nw + ls) + nw / 2,
                                       y: startY + CGFloat(i) * (nh + ns) + nh / 2)
                }
            }
        }
        return pos
    }

    func computeLayout() {
        let size = chartSize
        guard size.width > 10 else { return }
        if autoLayout {
            let newPos = computeAutoLayout(size: size)
            if layoutType != .freeform {
                nodePositions = newPos
            } else {
                for (id, pt) in newPos where nodePositions[id] == nil {
                    nodePositions[id] = pt
                }
            }
        }
    }

    // MARK: - Connector Path

    func connectorPath(from sPos: CGPoint, to tPos: CGPoint, nodeW: CGFloat, nodeH: CGFloat) -> Path {
        let startPt: CGPoint
        let endPt: CGPoint
        if layoutType == .horizontal {
            startPt = CGPoint(x: sPos.x + nodeW / 2, y: sPos.y)
            endPt   = CGPoint(x: tPos.x - nodeW / 2, y: tPos.y)
        } else {
            startPt = CGPoint(x: sPos.x, y: sPos.y + nodeH / 2)
            endPt   = CGPoint(x: tPos.x, y: tPos.y - nodeH / 2)
        }
        return Path { p in
            p.move(to: startPt)
            switch connectorType {
            case .straight:
                p.addLine(to: endPt)
            case .curved:
                let mid = CGPoint(x: (startPt.x + endPt.x) / 2, y: (startPt.y + endPt.y) / 2)
                if layoutType == .horizontal {
                    p.addCurve(to: endPt, control1: CGPoint(x: mid.x, y: startPt.y), control2: CGPoint(x: mid.x, y: endPt.y))
                } else {
                    p.addCurve(to: endPt, control1: CGPoint(x: startPt.x, y: mid.y), control2: CGPoint(x: endPt.x, y: mid.y))
                }
            case .orthogonal:
                if layoutType == .horizontal {
                    let midX = (startPt.x + endPt.x) / 2
                    p.addLine(to: CGPoint(x: midX, y: startPt.y))
                    p.addLine(to: CGPoint(x: midX, y: endPt.y))
                    p.addLine(to: endPt)
                } else {
                    let midY = (startPt.y + endPt.y) / 2
                    p.addLine(to: CGPoint(x: startPt.x, y: midY))
                    p.addLine(to: CGPoint(x: endPt.x, y: midY))
                    p.addLine(to: endPt)
                }
            }
        }
    }

    func arrowHead(from sPos: CGPoint, to tPos: CGPoint, nodeW: CGFloat, nodeH: CGFloat) -> Path {
        let endPt: CGPoint
        if layoutType == .horizontal {
            endPt = CGPoint(x: tPos.x - nodeW / 2, y: tPos.y)
        } else {
            endPt = CGPoint(x: tPos.x, y: tPos.y - nodeH / 2)
        }
        let angle: CGFloat = layoutType == .horizontal ? 0 : CGFloat.pi / 2
        let size: CGFloat = 7
        return Path { p in
            p.move(to: endPt)
            p.addLine(to: CGPoint(x: endPt.x - size * cos(angle - 0.4), y: endPt.y - size * sin(angle - 0.4)))
            p.addLine(to: CGPoint(x: endPt.x - size * cos(angle + 0.4), y: endPt.y - size * sin(angle + 0.4)))
            p.closeSubpath()
        }
    }

    // MARK: - Node View

    @ViewBuilder
    func nodeView(n: FCNode) -> some View {
        let w = CGFloat(nodeWidth), h = CGFloat(nodeHeight)
        let col = nodeColor(for: n)
        let isHL = highlightedID == n.id
        let hasError = flowValidation && highlightErrors && isUnconnected(n)

        let nodeShapeView: AnyShape = {
            switch n.nodeType {
            case .decision: return AnyShape(DiamondShape())
            case .startEnd: return nodeShape == .circle ? AnyShape(Capsule()) : AnyShape(RoundedRectangle(cornerRadius: h/2, style: .continuous))
            case .process:
                switch nodeShape {
                case .rectangle: return AnyShape(Rectangle())
                case .rounded, .circle: return AnyShape(RoundedRectangle(cornerRadius: CGFloat(cornerRadius), style: .continuous))
                case .diamond: return AnyShape(DiamondShape())
                }
            }
        }()

        ZStack {
            if shadowStyle == .soft {
                nodeShapeView.fill(col.opacity(0.15)).blur(radius: 4).offset(y: 2).frame(width: w + 4, height: h + 4)
            }
            if nodeFill {
                nodeShapeView.fill(col.opacity(0.82)).glassEffect(.clear, in: nodeShapeView).frame(width: w, height: h)
            }
            if nodeStroke {
                nodeShapeView.stroke(hasError ? Color.orange : Color.white.opacity(0.35), lineWidth: hasError ? 1.5 : 0.5).frame(width: w, height: h)
            }
            nodeShapeView.stroke(Color.white, lineWidth: 4).blur(radius: 2.5).opacity(isHL ? 0.45 : 0.22).clipShape(nodeShapeView).frame(width: w, height: h)

            if showLabels && labelPos != .hidden {
                Text(n.label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .multilineTextAlignment(textAlign == .left ? .leading : textAlign == .right ? .trailing : .center)
                    .lineLimit(textOverflow == .wrap ? 3 : 1)
                    .truncationMode(.tail)
                    .frame(width: w - 12)
                    .padding(.horizontal, 6)
            }
        }
        .frame(width: w, height: h)
    }

    // MARK: - Tooltip View

    @ViewBuilder
    func tooltipView(node: FCNode, pos: CGPoint, size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(node.label).font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(.primary)
            Divider()
            HStack(spacing: 4) {
                Text("Type:").font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Text(node.nodeType.rawValue).font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            }
            HStack(spacing: 4) {
                Text("Category:").font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Text(node.category).font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            }
            if flowValidation {
                HStack(spacing: 4) {
                    Text("Status:").font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    Text(isUnconnected(node) ? "⚠ Unconnected" : "✓ Connected").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(isUnconnected(node) ? .orange : .green)
                }
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(Color(uiColor: .systemBackground).opacity(0.92), in: .rect(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        .frame(width: 130)
        .position(x: min(max(pos.x, 75), size.width - 75), y: max(pos.y - 60, 40))
    }

    // MARK: - Minimap

    @ViewBuilder
    var minimapView: some View {
        let mmW: CGFloat = 80
        let mmH: CGFloat = 60
        let allPositions = nodePositions.values
        let minX = allPositions.map(\.x).min() ?? 0
        let maxX = allPositions.map(\.x).max() ?? mmW
        let minY = allPositions.map(\.y).min() ?? 0
        let maxY = allPositions.map(\.y).max() ?? mmH
        let rangeX = max(maxX - minX, 1)
        let rangeY = max(maxY - minY, 1)

        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(uiColor: .systemBackground).opacity(0.85))
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)

            ForEach(nodes) { n in
                if let pos = nodePositions[n.id] {
                    let nx = (pos.x - minX) / rangeX * (mmW - 10) + 5
                    let ny = (pos.y - minY) / rangeY * (mmH - 10) + 5
                    Circle()
                        .fill(nodeColor(for: n))
                        .frame(width: 5, height: 5)
                        .position(x: nx, y: ny)
                }
            }
        }
        .frame(width: mmW, height: mmH)
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            ZStack {
                // Connections (drawn first, behind nodes)
                ForEach(connections) { conn in
                    if let sPos = nodePositions[conn.sourceID],
                       let tPos = nodePositions[conn.targetID] {
                        let isHL = highlightedID == conn.sourceID || highlightedID == conn.targetID
                        let dash: [CGFloat] = connectorStyle == .dashed ? [7, 4] : []

                        connectorPath(from: sPos, to: tPos, nodeW: CGFloat(nodeWidth), nodeH: CGFloat(nodeHeight))
                            .stroke(Color.primary.opacity(isHL ? connectorOpacity * 1.5 : connectorOpacity),
                                    style: StrokeStyle(lineWidth: CGFloat(connectorThickness), lineCap: .round, dash: dash))

                        if showArrowHead {
                            arrowHead(from: sPos, to: tPos, nodeW: CGFloat(nodeWidth), nodeH: CGFloat(nodeHeight))
                                .fill(Color.primary.opacity(isHL ? connectorOpacity * 1.5 : connectorOpacity))
                        }

                        if !conn.connLabel.isEmpty {
                            let mid = CGPoint(x: (sPos.x + tPos.x) / 2, y: (sPos.y + tPos.y) / 2)
                            Text(conn.connLabel)
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(3)
                                .background(Color(uiColor: .systemBackground).opacity(0.8), in: .capsule)
                                .position(mid)
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: animationDuration * 0.7), value: appeared)

                // Nodes
                ForEach(nodes) { n in
                    if let pos = nodePositions[n.id] {
                        nodeView(n: n)
                            .position(pos)
                            .scaleEffect(appeared ? 1 : 0.01)
                            .opacity(appeared ? (hoverHighlight && highlightedID != nil && highlightedID != n.id ? 0.4 : 1) : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(animateOnLoad ? Double.random(in: 0...0.25) : 0), value: appeared)
                            .animation(.spring(response: 0.25), value: highlightedID)
                            .gesture(
                                DragGesture(minimumDistance: 2)
                                    .onChanged { v in
                                        guard dragNodesEnabled else { return }
                                        if draggingID == nil { draggingID = n.id; dragStartPos = nodePositions[n.id] ?? .zero }
                                        if draggingID == n.id {
                                            nodePositions[n.id] = CGPoint(x: dragStartPos.x + v.translation.width,
                                                                           y: dragStartPos.y + v.translation.height)
                                        }
                                    }
                                    .onEnded { _ in draggingID = nil }
                            )
                            .simultaneousGesture(TapGesture().onEnded {
                                withAnimation(.spring(response: 0.3)) {
                                    highlightedID = highlightedID == n.id ? nil : n.id
                                    tooltipID = hoverTooltip ? (tooltipID == n.id ? nil : n.id) : nil
                                }
                            })
                    }
                }

                // Validation errors
                if flowValidation && highlightErrors {
                    ForEach(nodes.filter { isUnconnected($0) }) { n in
                        if let pos = nodePositions[n.id] {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.orange)
                                .position(x: pos.x + CGFloat(nodeWidth) / 2 - 6, y: pos.y - CGFloat(nodeHeight) / 2 - 6)
                        }
                    }
                }

                // Tooltip
                if hoverTooltip, let tid = tooltipID, let n = nodes.first(where: { $0.id == tid }),
                   let pos = nodePositions[tid] {
                    tooltipView(node: n, pos: pos, size: geo.size)
                }

                // Minimap overlay
                if showMinimap {
                    VStack {
                        HStack {
                            Spacer()
                            minimapView
                                .padding(8)
                        }
                        Spacer()
                    }
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
            .offset(x: zoomPanEnabled ? panOffset.width + dragTranslation.width : 0,
                    y: zoomPanEnabled ? panOffset.height + dragTranslation.height : 0)
            .gesture(MagnificationGesture().updating($magnifyBy) { v, s, _ in s = zoomPanEnabled ? v : 1.0 }.onEnded { v in if zoomPanEnabled { zoomScale = min(5, max(0.3, zoomScale * v)) } })
            .simultaneousGesture(DragGesture(minimumDistance: 14).updating($dragTranslation) { v, s, _ in s = (zoomPanEnabled && draggingID == nil) ? v.translation : .zero }.onEnded { v in if zoomPanEnabled && draggingID == nil { panOffset.width += v.translation.width; panOffset.height += v.translation.height } })
            .contentShape(Rectangle())
            .onTapGesture { withAnimation(.spring(response: 0.3)) { highlightedID = nil; tooltipID = nil } }
            .clipped()
        }
    }

    // MARK: - Settings Helpers

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

    // MARK: - Settings Sections

    var layoutSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Layout")
                HStack(spacing: 2) {
                    ForEach(FCLayout.allCases, id: \.self) { lt in
                        pillButton(lt.rawValue, isSelected: layoutType == lt) { layoutType = lt }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Auto")
                Toggle("", isOn: $autoLayout).labelsHidden().scaleEffect(0.8)
                Text("auto-arrange nodes").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Node Gap")
                Slider(value: $nodeSpacing, in: 20...120, step: 5)
                Text("\(Int(nodeSpacing))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Level Gap")
                Slider(value: $levelSpacing, in: 40...160, step: 5)
                Text("\(Int(levelSpacing))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Padding")
                Slider(value: $chartPadding, in: 0...60)
                Text("\(Int(chartPadding))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    var nodeTypeSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Shape")
                HStack(spacing: 2) {
                    ForEach(FCShape.allCases, id: \.self) { sh in
                        pillButton(sh.rawValue, isSelected: nodeShape == sh) { nodeShape = sh }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Default")
                HStack(spacing: 2) {
                    ForEach(FCNodeType.allCases, id: \.self) { nt in
                        pillButton(nt.rawValue, isSelected: defaultNodeType == nt) { defaultNodeType = nt }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Mixed")
                Toggle("", isOn: $allowMixedTypes).labelsHidden().scaleEffect(0.8)
                Text("allow multiple types").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    var nodeStylingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Width")
                Slider(value: $nodeWidth, in: 80...240)
                Text("\(Int(nodeWidth))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Height")
                Slider(value: $nodeHeight, in: 40...120)
                Text("\(Int(nodeHeight))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Radius")
                Slider(value: $cornerRadius, in: 0...20)
                Text("\(Int(cornerRadius))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Fill")
                Toggle("", isOn: $nodeFill).labelsHidden().scaleEffect(0.8)
                Text("fill node background").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Stroke")
                Toggle("", isOn: $nodeStroke).labelsHidden().scaleEffect(0.8)
                Text("draw node border").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Shadow")
                HStack(spacing: 2) {
                    ForEach(FCShadow.allCases, id: \.self) { sh in
                        pillButton(sh.rawValue, isSelected: shadowStyle == sh) { shadowStyle = sh }
                    }
                }
                Spacer()
            }
        }
    }

    var connectorSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Type")
                HStack(spacing: 2) {
                    ForEach(FCConnector.allCases, id: \.self) { ct in
                        pillButton(ct.rawValue, isSelected: connectorType == ct) { connectorType = ct }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Thickness")
                Slider(value: $connectorThickness, in: 1...6)
                Text(String(format: "%.1f", connectorThickness)).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Style")
                HStack(spacing: 2) {
                    ForEach(FCLineStyle.allCases, id: \.self) { ls in
                        pillButton(ls.rawValue, isSelected: connectorStyle == ls) { connectorStyle = ls }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Arrow")
                Toggle("", isOn: $showArrowHead).labelsHidden().scaleEffect(0.8)
                Text("show arrow head").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Opacity")
                Slider(value: $connectorOpacity, in: 0...1)
                Text("\(Int(connectorOpacity * 100))%").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    var colorSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Mode")
                HStack(spacing: 2) {
                    ForEach(FCColorMode.allCases, id: \.self) { cm in
                        pillButton(cm.rawValue, isSelected: colorMode == cm) { colorMode = cm }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Scale")
                Toggle("", isOn: $colorScale).labelsHidden().scaleEffect(0.8)
                Text("use color scale").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
                    HStack(spacing: 2) {
                        ForEach(FCLabelPos.allCases, id: \.self) { lp in
                            pillButton(lp.rawValue, isSelected: labelPos == lp) { labelPos = lp }
                        }
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    settingsLabel("Align")
                    HStack(spacing: 2) {
                        ForEach(FCTextAlign.allCases, id: \.self) { ta in
                            pillButton(ta.rawValue, isSelected: textAlign == ta) { textAlign = ta }
                        }
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    settingsLabel("Overflow")
                    HStack(spacing: 2) {
                        ForEach(FCOverflow.allCases, id: \.self) { ov in
                            pillButton(ov.rawValue, isSelected: textOverflow == ov) { textOverflow = ov }
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
                Text("dim others on tap").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Tooltip")
                Toggle("", isOn: $hoverTooltip).labelsHidden().scaleEffect(0.8)
                Text("show node tooltip").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Drag")
                Toggle("", isOn: $dragNodesEnabled).labelsHidden().scaleEffect(0.8)
                Text("drag nodes freely").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Zoom/Pan")
                Toggle("", isOn: $zoomPanEnabled).labelsHidden().scaleEffect(0.8)
                Text("pinch & pan chart").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Animate")
                Toggle("", isOn: $animateOnLoad).labelsHidden().scaleEffect(0.8)
                Text("animate on load").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Duration")
                Slider(value: $animationDuration, in: 0.2...2.0)
                Text(String(format: "%.1fs", animationDuration)).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    var navigationSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Minimap")
                Toggle("", isOn: $showMinimap).labelsHidden().scaleEffect(0.8)
                Text("overview in corner").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Center")
                Toggle("", isOn: $autoCenter).labelsHidden().scaleEffect(0.8)
                Text("auto-center on load").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    var validationSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Validate")
                Toggle("", isOn: $flowValidation).labelsHidden().scaleEffect(0.8)
                Text("check flow integrity").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if flowValidation {
                HStack(spacing: 10) {
                    settingsLabel("Errors")
                    Toggle("", isOn: $highlightErrors).labelsHidden().scaleEffect(0.8)
                    Text("highlight unconnected").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    Spacer()
                }
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
                    let idx = nodes.count % FlowChartCard.colorPalette.count
                    withAnimation(.spring(response: 0.4)) {
                        let n = FCNode(label: "Step \(nodes.count+1)", nodeType: defaultNodeType, category: "Flow", color: FlowChartCard.colorPalette[idx])
                        nodes.append(n)
                        computeLayout()
                    }
                } label: { Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundStyle(FlowChartCard.colorPalette[nodes.count % FlowChartCard.colorPalette.count]) }
            }
            .padding(.horizontal, 20).padding(.bottom, 10)

            ForEach(Array(nodes.enumerated()), id: \.element.id) { i, n in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 4).fill(nodeColor(for: n)).frame(width: 10, height: 10)
                    Text(n.label).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.primary).lineLimit(1)
                    Spacer()
                    Text(n.nodeType.rawValue).font(.system(size: 10, design: .rounded)).foregroundStyle(.secondary).padding(.horizontal, 6).padding(.vertical, 2).background(Color.black.opacity(0.06), in: .capsule)
                    if nodes.count > 1 {
                        Button { withAnimation(.spring(response: 0.4)) { let nid = n.id; nodes.removeSubrange(i...i); connections.removeAll { $0.sourceID == nid || $0.targetID == nid }; computeLayout() } } label: { Image(systemName: "minus.circle").font(.system(size: 16)).foregroundStyle(.secondary) }
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 8)
                if i < nodes.count - 1 { Divider().padding(.horizontal, 20) }
            }

            Divider().padding(.horizontal, 20).padding(.top, 6)

            // Connections header
            HStack {
                Text("Connections").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(.primary)
                Spacer()
                Button {
                    guard nodes.count >= 2 else { return }
                    withAnimation(.spring(response: 0.4)) {
                        let pairs = nodes.enumerated().compactMap { i, n -> FCConnection? in
                            guard i < nodes.count - 1 else { return nil }
                            return FCConnection(sourceID: n.id, targetID: nodes[i+1].id, connLabel: "")
                        }
                        if let new = pairs.first(where: { c in !connections.contains { $0.sourceID == c.sourceID && $0.targetID == c.targetID } }) {
                            connections.append(new)
                        } else {
                            connections.append(FCConnection(sourceID: nodes[0].id, targetID: nodes[nodes.count-1].id, connLabel: ""))
                        }
                    }
                } label: { Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundStyle(.secondary) }
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 10)

            ForEach(Array(connections.enumerated()), id: \.element.id) { i, c in
                let srcLabel = nodes.first(where: { $0.id == c.sourceID })?.label ?? "?"
                let tgtLabel = nodes.first(where: { $0.id == c.targetID })?.label ?? "?"
                HStack(spacing: 10) {
                    Image(systemName: "arrow.right").font(.system(size: 10)).foregroundStyle(.secondary)
                    Text("\(srcLabel) → \(tgtLabel)").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(.primary).lineLimit(1)
                    Spacer()
                    Button { withAnimation(.spring(response: 0.4)) { connections.removeSubrange(i...i) } } label: { Image(systemName: "minus.circle").font(.system(size: 16)).foregroundStyle(.secondary) }
                }
                .padding(.horizontal, 20).padding(.vertical, 8)
                if i < connections.count - 1 { Divider().padding(.horizontal, 20) }
            }
        }
        .padding(.bottom, 12)
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
                        Text(title).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(.primary).frame(maxWidth: .infinity)
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
                    VStack(spacing: 10) {
                        layoutSettingsView
                        nodeTypeSettingsView
                        nodeStylingSettingsView
                        connectorSettingsView
                        colorSettingsView
                        labelSettingsView
                        interactionSettingsView
                        navigationSettingsView
                        validationSettingsView
                    }
                    .padding(.horizontal, 16)
                    dataListView
                }
                .frame(maxHeight: isExpanded ? .infinity : 0)
                .clipped().opacity(isExpanded ? 1 : 0)
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
        .onChange(of: autoLayout) { _, _ in computeLayout() }
        .onChange(of: zoomPanEnabled) { _, enabled in
            if !enabled { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { zoomScale = 1; panOffset = .zero } }
        }
    }
}

// MARK: - Analytics View Extension

struct FlowChartAnalyticsView: View {

    private func makeNodes() -> [FCNode] {
        let p = FlowChartCard.colorPalette
        return [
            FCNode(label: "Start",       nodeType: .startEnd,  category: "Flow",    color: p[4]),
            FCNode(label: "Input Data",  nodeType: .process,   category: "Data",    color: p[0]),
            FCNode(label: "Valid?",      nodeType: .decision,  category: "Logic",   color: p[2]),
            FCNode(label: "Process",     nodeType: .process,   category: "Core",    color: p[0]),
            FCNode(label: "Handle Err",  nodeType: .process,   category: "Error",   color: p[1]),
            FCNode(label: "Output",      nodeType: .process,   category: "Data",    color: p[0]),
            FCNode(label: "End",         nodeType: .startEnd,  category: "Flow",    color: p[4]),
        ]
    }

    private func makeConnections(nodes: [FCNode]) -> [FCConnection] {
        guard nodes.count >= 7 else { return [] }
        return [
            FCConnection(sourceID: nodes[0].id, targetID: nodes[1].id, connLabel: ""),
            FCConnection(sourceID: nodes[1].id, targetID: nodes[2].id, connLabel: ""),
            FCConnection(sourceID: nodes[2].id, targetID: nodes[3].id, connLabel: "Yes"),
            FCConnection(sourceID: nodes[2].id, targetID: nodes[4].id, connLabel: "No"),
            FCConnection(sourceID: nodes[3].id, targetID: nodes[5].id, connLabel: ""),
            FCConnection(sourceID: nodes[4].id, targetID: nodes[1].id, connLabel: "Retry"),
            FCConnection(sourceID: nodes[5].id, targetID: nodes[6].id, connLabel: ""),
        ]
    }

    var body: some View {
        let nodes = makeNodes()
        let conns = makeConnections(nodes: nodes)
        FlowChartCard(
            title: "Flow Chart",
            categories: ["Flow", "Data", "Logic", "Core", "Error"],
            nodes: nodes,
            connections: conns
        )
    }
}
